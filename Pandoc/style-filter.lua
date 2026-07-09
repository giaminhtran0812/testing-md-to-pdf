-- ==============================
-- Helper functions
-- ==============================

local function get_caption_text(tbl)
  if tbl.caption and tbl.caption.long then
    return pandoc.utils.stringify(tbl.caption.long)
  end
  return ""
end

local function parse_widths(s)
  local widths = {}
  if not s or s == "" then
    return widths
  end
  for w in s:gmatch("[^,]+") do
    local num = tonumber(w)
    if num then
      table.insert(widths, num)
    end
  end
  return widths
end

local function get_width_attr(attributes)
  if not attributes then
    return nil
  end
  return attributes["widths"] or attributes["width"]
end

local function get_note_attr(attributes)
  if not attributes then
    return nil
  end
  return attributes["note"] or attributes["notes"] or attributes["footnote"]
end

local function parse_notes(s)
  local notes = {}
  if not s or s == "" then
    return notes
  end

  for note in s:gmatch("[^|]+") do
    note = note:gsub("^%s+", ""):gsub("%s+$", "")
    if note ~= "" then
      notes[#notes + 1] = note
    end
  end

  return notes
end

local function has_class(el, class_name)
  if not el.classes then
    return false
  end
  for _, c in ipairs(el.classes) do
    if c == class_name then
      return true
    end
  end
  return false
end

local function latex_escape(s)
  s = s:gsub("\\", "\\textbackslash{}")
  s = s:gsub("([%%{}_%#&$])", "\\%1")
  s = s:gsub("~", "\\textasciitilde{}")
  s = s:gsub("%^", "\\textasciicircum{}")
  return s
end

local function latex_label(s)
  if not s or s == "" then
    return nil
  end
  return s:gsub("[{}\\]", "")
end

local function blocks_to_text(blocks)
  return latex_escape(pandoc.utils.stringify(blocks))
end

local function inlines_to_latex(inlines)
  local out = {}

  for _, inline in ipairs(inlines or {}) do
    if inline.t == "Str" then
      out[#out + 1] = latex_escape(inline.text)
    elseif inline.t == "Space" or inline.t == "SoftBreak" then
      out[#out + 1] = " "
    elseif inline.t == "LineBreak" then
      out[#out + 1] = "\\newline{}"
    elseif inline.t == "Code" then
      out[#out + 1] = "\\texttt{" .. latex_escape(inline.text) .. "}"
    elseif inline.t == "Emph" then
      out[#out + 1] = "\\emph{" .. inlines_to_latex(inline.content) .. "}"
    elseif inline.t == "Strong" then
      out[#out + 1] = "\\textbf{" .. inlines_to_latex(inline.content) .. "}"
    elseif inline.t == "RawInline" and (inline.format == "latex" or inline.format == "tex") then
      out[#out + 1] = inline.text
    elseif inline.content then
      out[#out + 1] = inlines_to_latex(inline.content)
    else
      out[#out + 1] = latex_escape(pandoc.utils.stringify(inline))
    end
  end

  return table.concat(out)
end

local function blocks_to_latex(blocks)
  local out = {}

  for _, block in ipairs(blocks or {}) do
    if block.t == "Plain" or block.t == "Para" then
      out[#out + 1] = inlines_to_latex(block.content)
    elseif block.t == "RawBlock" and (block.format == "latex" or block.format == "tex") then
      out[#out + 1] = block.text
    else
      out[#out + 1] = latex_escape(pandoc.utils.stringify(block))
    end
  end

  return table.concat(out, "\\par{}")
end

local cell_color_classes = {
  ["cell-green"] = "CellGreen",
  ["cell-yellow"] = "CellYellow",
  ["cell-red"] = "CellRed",
  ["cell-gray"] = "CellGray",
  ["cell-blue"] = "CellBlue"
}

local function rgb_color_attr(attributes)
  if not attributes then
    return nil
  end

  local value = attributes["rgb"] or attributes["cell-rgb"] or attributes["bg-rgb"]
  if not value then
    return nil
  end

  local parts = {}
  for part in value:gmatch("%d+") do
    local n = tonumber(part)
    if not n or n < 0 or n > 255 then
      return nil
    end
    parts[#parts + 1] = tostring(n)
  end

  if #parts ~= 3 then
    return nil
  end

  return "[RGB]{" .. table.concat(parts, ",") .. "}"
end

local function find_cell_color_in_inlines(inlines)
  if not inlines then
    return nil
  end

  for _, inline in ipairs(inlines) do
    local rgb = rgb_color_attr(inline.attributes)
    if rgb then
      return rgb
    end

    if inline.classes then
      for _, class in ipairs(inline.classes) do
        if cell_color_classes[class] then
          return cell_color_classes[class]
        end
      end
    end

    local nested = find_cell_color_in_inlines(inline.content)
    if nested then
      return nested
    end
  end

  return nil
end

local function cell_color(cell)
  for _, block in ipairs(cell.contents) do
    local rgb = rgb_color_attr(block.attributes)
    if rgb then
      return rgb
    end

    if block.classes then
      for _, class in ipairs(block.classes) do
        if cell_color_classes[class] then
          return cell_color_classes[class]
        end
      end
    end

    local color = find_cell_color_in_inlines(block.content)
    if color then
      return color
    end
  end

  return nil
end

local function cell_to_text(cell)
  return blocks_to_latex(cell.contents)
end

local function item_label(cell)
  local text = pandoc.utils.stringify(cell.contents)
  return text:match("^%s*{#([%w:_%.%-]+)}%s*$")
    or text:match("^%s*{#([%w:_%.%-]+)}")
end

local function row_to_latex(row, is_header, options)
  local parts = {}
  options = options or {}

  for i, cell in ipairs(row.cells) do
    local txt

    if options.auto_items and not is_header and i == 1 then
      local label = item_label(cell)
      txt = "\\refstepcounter{BHTableItem}"
      if label then
        txt = txt .. "\\label{" .. label .. "}"
      end
      txt = txt .. "\\theBHTableItem"
      txt = "\\raggedright " .. txt
    else
      txt = cell_to_text(cell)
    end

    if is_header then
      txt = "\\textcolor{white}{\\textbf{" .. txt .. "}}"
    else
      local color = cell_color(cell)
      if color then
        if color:match("^%[") then
          txt = "\\cellcolor" .. color .. txt
        else
          txt = "\\cellcolor{" .. color .. "}" .. txt
        end
      end
    end
    table.insert(parts, txt)
  end
  return table.concat(parts, " & ") .. " \\\\ \\hline"
end

local function nomenclature_row_to_latex(row)
  local first = row.cells[1] and cell_to_text(row.cells[1]) or ""
  local second = row.cells[2] and cell_to_text(row.cells[2]) or ""
  return first .. " & " .. second .. " \\\\ \\hline"
end

local function nomenclature_col_widths(widths_override)
  local widths = widths_override
  if not widths or #widths ~= 2 then
    widths = { 0.25, 0.75 }
  end

  local total = widths[1] + widths[2]
  if total <= 0 then
    widths = { 0.25, 0.75 }
    total = 1
  end

  return (widths[1] / total) * 0.86, (widths[2] / total) * 0.86
end

local function build_nomenclature_column(rows, widths_override)
  local out = {}
  local first_width, second_width = nomenclature_col_widths(widths_override)
  table.insert(out, string.format("\\begin{tabular}{|>{\\raggedright\\arraybackslash}p{%.4f\\linewidth}|>{\\raggedright\\arraybackslash}p{%.4f\\linewidth}|}", first_width, second_width))
  table.insert(out, "\\hline")

  for _, row in ipairs(rows) do
    table.insert(out, nomenclature_row_to_latex(row))
  end

  table.insert(out, "\\end{tabular}")
  return table.concat(out, "\n")
end

local function build_nomenclature_table(tbl, widths_override)
  local colspecs = tbl.colspecs
  if not colspecs or #colspecs ~= 2 then
    return build_table(tbl, nil)
  end

  local rows = {}
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      rows[#rows + 1] = row
    end
  end

  local split_at = math.ceil(#rows / 2)
  local left_rows = {}
  local right_rows = {}
  for i, row in ipairs(rows) do
    if i <= split_at then
      left_rows[#left_rows + 1] = row
    else
      right_rows[#right_rows + 1] = row
    end
  end

  local out = {}

  table.insert(out, "\\begingroup")
  table.insert(out, "\\setlength{\\leftskip}{0pt}")
  table.insert(out, "\\fontsize{\\BHTableFontSize}{\\BHTableLineHeight}\\selectfont")

  table.insert(out, "\\noindent")
  table.insert(out, "\\begin{minipage}[t]{0.475\\linewidth}")
  table.insert(out, build_nomenclature_column(left_rows, widths_override))
  table.insert(out, "\\end{minipage}\\hfill")
  table.insert(out, "\\begin{minipage}[t]{0.475\\linewidth}")
  table.insert(out, build_nomenclature_column(right_rows, widths_override))
  table.insert(out, "\\end{minipage}")
  table.insert(out, "\\par\\endgroup")

  return pandoc.RawBlock("latex", table.concat(out, "\n"))
end

local function widths_to_cols(widths)
  local cols = {}
  local total = 0

  for _, w in ipairs(widths) do
    total = total + w
  end

  if total <= 0 then
    return nil
  end

  for i, w in ipairs(widths) do
    cols[i] = string.format(
      [[>{\raggedright\arraybackslash}p{\dimexpr%.6f\linewidth-2\tabcolsep-\arrayrulewidth\relax}]],
      w / total
    )
  end

  return cols
end

-- ==============================
-- Build table (NEW API)
-- ==============================

local build_table

build_table = function(tbl, widths_override)
  local colspecs = tbl.colspecs
  if not colspecs or #colspecs == 0 then
    return nil
  end

  local ncols = #colspecs
  local caption_text = get_caption_text(tbl)
  local label = latex_label(tbl.identifier)
  local notes = parse_notes(get_note_attr(tbl.attributes))
  local options = {
    auto_items = has_class(tbl, "auto-items")
  }

  -- Build column widths
  local cols = {}

  if widths_override and #widths_override == ncols then
    cols = widths_to_cols(widths_override)
  elseif ncols == 3 then
    cols = widths_to_cols({ 0.08, 0.27, 0.60 })
  elseif ncols == 2 then
    cols = widths_to_cols({ 0.22, 0.73 })
  else
    local total_tabcolsep = 2 * ncols
    local total_rules = ncols + 1
    for i = 1, ncols do
      cols[i] = string.format(
        [[>{\raggedright\arraybackslash}p{\dimexpr(\linewidth-%d\tabcolsep-%d\arrayrulewidth)/%d\relax}]],
        total_tabcolsep,
        total_rules,
        ncols
      )
    end
  end

  if not cols then
    return nil
  end

  local colspec = "|" .. table.concat(cols, "|") .. "|"

  local out = {}
  if options.auto_items then
    table.insert(out, "\\setcounter{BHTableItem}{0}")
  end
  table.insert(out, "\\begin{longtable}{" .. colspec .. "}")

  if caption_text ~= "" then
    if label then
      table.insert(out, "\\caption{" .. caption_text .. "\\label{" .. label .. "}}\\\\")
    else
      table.insert(out, "\\caption{" .. caption_text .. "}\\\\")
    end
  end

  table.insert(out, "\\hline")

  -- Header
  if tbl.head and #tbl.head.rows > 0 then
    local header_row = tbl.head.rows[1]
    table.insert(out, "\\rowcolor{TableHeader}")
    table.insert(out, row_to_latex(header_row, true, options))

    table.insert(out, "\\endfirsthead")
    table.insert(out, "\\hline")

    table.insert(out, "\\rowcolor{TableHeader}")
    table.insert(out, row_to_latex(header_row, true, options))
    table.insert(out, "\\endhead")
  end

  -- Body
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      table.insert(out, row_to_latex(row, false, options))
    end
  end

  if #notes == 1 then
    table.insert(out, "\\multicolumn{" .. ncols .. "}{|p{\\dimexpr\\linewidth-2\\tabcolsep-\\arrayrulewidth\\relax}|}{\\fontsize{8pt}{10pt}\\selectfont\\textbf{Note:} " .. latex_escape(notes[1]) .. "} \\\\ \\hline")
  elseif #notes > 1 then
    local note_text = {}
    for i, note in ipairs(notes) do
      note_text[i] = latex_escape(note)
    end
    table.insert(out, "\\multicolumn{" .. ncols .. "}{|p{\\dimexpr\\linewidth-2\\tabcolsep-\\arrayrulewidth\\relax}|}{\\fontsize{8pt}{10pt}\\selectfont\\textbf{Notes:} " .. table.concat(note_text, "\\par{}") .. "} \\\\ \\hline")
  end

  table.insert(out, "\\end{longtable}")

  return pandoc.RawBlock("latex", table.concat(out, "\n"))
end

-- ==============================
-- Main handlers
-- ==============================

function Table(tbl)
  if FORMAT ~= "latex" then
    return nil
  end

  local widths = nil

  local width_attr = get_width_attr(tbl.attributes)
  if width_attr then
    widths = parse_widths(width_attr)
  end

  if has_class(tbl, "nomenclature") then
    return build_nomenclature_table(tbl, widths)
  end

  return build_table(tbl, widths)
end

function DivWidths(el)
  if FORMAT ~= "latex" then
    return nil
  end

  local width_attr = get_width_attr(el.attributes)
  local note_attr = get_note_attr(el.attributes)
  if has_class(el, "table-cols") or has_class(el, "auto-items") or has_class(el, "nomenclature") or note_attr then
    local new_blocks = pandoc.Blocks{}

    for _, b in ipairs(el.content) do
      if b.t == "Table" then
        b.attributes = b.attributes or {}
        if width_attr then
          b.attributes["widths"] = width_attr
        end
        if note_attr then
          b.attributes["note"] = note_attr
        end
        if has_class(el, "auto-items") then
          b.classes = b.classes or pandoc.List{}
          b.classes:insert("auto-items")
        end
        if has_class(el, "nomenclature") then
          b.classes = b.classes or pandoc.List{}
          b.classes:insert("nomenclature")
        end
      end
      new_blocks:insert(b)
    end

    return new_blocks
  end

  return nil
end


function DivLandscape(el)
  if FORMAT ~= "latex" then
    return nil
  end

  if not has_class(el, "landscape") then
    return nil
  end

  local blocks = pandoc.Blocks{}

  blocks:insert(
    pandoc.RawBlock("latex",
      "\\BHBeginLandscape"
    )
  )

  blocks:extend(el.content)

  blocks:insert(
    pandoc.RawBlock("latex",
      "\\BHEndLandscape"
    )
  )

  return blocks
end

function DivNote(el)
  if FORMAT ~= "latex" then
    return nil
  end

  if not has_class(el, "note") then
    return nil
  end

  local blocks = pandoc.Blocks{}
  blocks:insert(pandoc.RawBlock("latex", "\\begin{BHNoteBox}"))
  blocks:extend(el.content)
  blocks:insert(pandoc.RawBlock("latex", "\\end{BHNoteBox}"))

  return blocks
end

return {
  { Div = DivWidths, traverse = "topdown" },
  { Div = DivNote },
  { Table = Table },
  { Div = DivLandscape }
}
