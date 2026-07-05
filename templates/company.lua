function Div(el)
  if el.classes:includes("pagebreak") then
    if FORMAT:match("latex") then
      return pandoc.RawBlock("latex", "\\clearpage")
    end
    return {}
  end
end

function HorizontalRule()
  if FORMAT:match("latex") then
    return pandoc.RawBlock("latex", "\\clearpage")
  end
end
