local null = pandoc.Null()
local p = quarto.log.output


local function starts_with(str, start)
  return str:sub(1, #start) == start
end

local function process(el)
  if starts_with(el.identifier, 'fig-') then
    p(el.attr)
    return el
  else
    return el
  end
end

return {
  Image = process,
  Div = process,
}

-- Image {
--   attr: Attr {
--     attributes: AttributeList {}
--     classes: List {}
--     clone: function: 0x7ffba1d562a0
--     identifier: "fig-nmr-ensemble"
--   }
--   caption: Inlines {
--     [1] Str {
--       clone: function: 0x7ffba1d57b30
--       text: " "
--       walk: function: 0x7ffba1d57d30
--     }
--   }
--   clone: function: 0x7ffba1d55340
--   src: "./assets/structures/2kc2-ensemble-10.png"
--   title: "fig:"
--   walk: function: 0x7ffba1d55500
-- }
