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

local cell_color_classes = {
  ["cell-green"] = "CellGreen",
  ["cell-yellow"] = "CellYellow",
  ["cell-red"] = "CellRed",
  ["cell-gray"] = "CellGray",
  ["cell-blue"] = "CellBlue"
}

local function find_cell_color_in_inlines(inlines)
  if not inlines then
    return nil
  end

  for _, inline in ipairs(inlines) do
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
  return blocks_to_text(cell.contents)
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
    else
      txt = cell_to_text(cell)
    end

    if is_header then
      txt = "\\textcolor{white}{\\textbf{" .. txt .. "}}"
    else
      local color = cell_color(cell)
      if color then
        txt = "\\cellcolor{" .. color .. "}" .. txt
      end
    end
    table.insert(parts, txt)
  end
  return table.concat(parts, " & ") .. " \\\\ \\hline"
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

local function build_table(tbl, widths_override)
  local colspecs = tbl.colspecs
  if not colspecs or #colspecs == 0 then
    return nil
  end

  local ncols = #colspecs
  local caption_text = get_caption_text(tbl)
  local label = latex_label(tbl.identifier)
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

  return build_table(tbl, widths)
end

function DivWidths(el)
  if FORMAT ~= "latex" then
    return nil
  end

  local width_attr = get_width_attr(el.attributes)
  if has_class(el, "table-cols") or has_class(el, "auto-items") then
    local new_blocks = pandoc.Blocks{}

    for _, b in ipairs(el.content) do
      if b.t == "Table" then
        b.attributes = b.attributes or {}
        if width_attr then
          b.attributes["widths"] = width_attr
        end
        if has_class(el, "auto-items") then
          b.classes = b.classes or pandoc.List{}
          b.classes:insert("auto-items")
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

return {
  { Div = DivWidths, traverse = "topdown" },
  { Table = Table },
  { Div = DivLandscape }
}
