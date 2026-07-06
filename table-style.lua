-- ==============================
-- Helper functions
-- ==============================

local function get_caption_text(tbl)
  if tbl.caption and tbl.caption.long then
    return pandoc.utils.stringify(tbl.caption.long)
  end
  return ""
end

local pending_table_widths = nil

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

local function latex_escape(s)
  s = s:gsub("\\", "\\textbackslash{}")
  s = s:gsub("([%%{}_%#&$])", "\\%1")
  s = s:gsub("~", "\\textasciitilde{}")
  s = s:gsub("%^", "\\textasciicircum{}")
  return s
end

local function blocks_to_text(blocks)
  return latex_escape(pandoc.utils.stringify(blocks))
end

local function cell_to_text(cell)
  return blocks_to_text(cell.contents)
end

local function row_to_latex(row, is_header)
  local parts = {}
  for _, cell in ipairs(row.cells) do
    local txt = cell_to_text(cell)
    if is_header then
      txt = "\\textcolor{white}{\\textbf{" .. txt .. "}}"
    end
    table.insert(parts, txt)
  end
  return table.concat(parts, " & ") .. " \\\\ \\hline"
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

  -- Build column widths
  local cols = {}

  if widths_override and #widths_override == ncols then
    for i = 1, ncols do
      cols[i] = string.format(
        [[>{\raggedright\arraybackslash}p{\dimexpr%.3f\linewidth-2\tabcolsep-\arrayrulewidth\relax}]],
        widths_override[i]
      )
    end
  elseif ncols == 3 then
    cols = {
      [[>{\raggedright\arraybackslash}p{0.08\linewidth}]],
      [[>{\raggedright\arraybackslash}p{0.27\linewidth}]],
      [[>{\raggedright\arraybackslash}p{0.60\linewidth}]]
    }
  elseif ncols == 2 then
    cols = {
      [[>{\raggedright\arraybackslash}p{0.22\linewidth}]],
      [[>{\raggedright\arraybackslash}p{0.73\linewidth}]]
    }
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

  local colspec = "|" .. table.concat(cols, "|") .. "|"

  local out = {}
  table.insert(out, "\\begin{longtable}{" .. colspec .. "}")

  if caption_text ~= "" then
    table.insert(out, "\\caption{" .. caption_text .. "}\\\\")
  end

  table.insert(out, "\\hline")

  -- Header
  if tbl.head and #tbl.head.rows > 0 then
    local header_row = tbl.head.rows[1]
    table.insert(out, "\\rowcolor{TableHeader}")
    table.insert(out, row_to_latex(header_row, true))

    table.insert(out, "\\endfirsthead")
    table.insert(out, "\\hline")

    table.insert(out, "\\rowcolor{TableHeader}")
    table.insert(out, row_to_latex(header_row, true))
    table.insert(out, "\\endhead")
  end

  -- Body
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      table.insert(out, row_to_latex(row, false))
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

  if tbl.attributes and tbl.attributes["widths"] then
    widths = parse_widths(tbl.attributes["widths"])
  end

  return build_table(tbl, widths)
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

function DivWidths(el)
  if FORMAT ~= "latex" then
    return nil
  end

  if has_class(el, "table-cols") and el.attributes and el.attributes["widths"] then
    local widths = parse_widths(el.attributes["widths"])

    local new_blocks = pandoc.Blocks{}

    for _, b in ipairs(el.content) do
      if b.t == "Table" then
        b.attributes = b.attributes or {}
        b.attributes["widths"] = el.attributes["widths"]
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

  pending_table_widths = nil

  if not has_class(el, "landscape") then
    return nil
  end

  local blocks = pandoc.Blocks{}

  blocks:insert(
    pandoc.RawBlock("latex",
      "\\clearpage\n" ..
      "\\begin{landscape}\n" ..
      "\\pagestyle{fancy}\n" ..
      "\\setlength{\\leftskip}{0pt}"
    )
  )

  blocks:extend(el.content)

  blocks:insert(
    pandoc.RawBlock("latex",
      "\\end{landscape}\n" ..
      "\\clearpage\n" ..
      "\\pagestyle{fancy}"
    )
  )

  return blocks
end

return {
  { Div = DivWidths, traverse = "topdown" },
  { Table = Table },
  { Div = DivLandscape }
}
