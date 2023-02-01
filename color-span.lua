return {
  Span = function(el)
    local red = el.attr.classes[1] == 'red'

    -- if no red attribute, return unchange
    if red == false then return el end

    -- transform to <span style="color: red;"></span>
    if FORMAT:match 'html' then
      -- remove color attributes
      el.attributes['color'] = nil
      -- use style attribute instead
      el.attributes['style'] = 'color: ' .. 'red' .. ';'
      -- return full span element
      return el
    elseif FORMAT:match 'latex' then
      -- remove color attributes
      el.attributes['color'] = nil
      -- encapsulate in latex code
      table.insert(
        el.content, 1,
        pandoc.RawInline('latex', '\\textcolor{' .. 'red' .. '}{')
      )
      table.insert(
        el.content,
        pandoc.RawInline('latex', '}')
      )
      -- returns only span content
      return el.content
    else
      -- for other format return unchanged
      return el
    end
  end
}
