local tu = {}

-- make a line wrapping predicate from a max width in pixels, a font id, and a font_size
function tu.sol_text_wrap_predicate(max_width, font, font_size)
  return function(text)
    local prw,prh = sol.text_surface.get_predicted_size(font, font_size, text)
    return prw <= max_width
  end
end

-- make a mono wrapping predicate from a max character_count
function tu.mono_wrap_predicate(character_count)
  return function(text)
    return #text < character_count
  end
end

----------------------------------------
-- return an iterator of lines from a single line text

-- example :
-- `tu.word_wrap("long test ... phrase",tu.sol_text_wrap_predicate(300,"font_id",font_size))`
----------------------------------------
function tu.word_wrap(text, predicate)
  local words = text:gmatch("%S+ *[!;:?]*")
  local last = ''
  local space = ''
  return iter(function()
    local line = last
    for w in words do
      w = w:gsub("%s+$", "") -- remove space at word end
      local new_line = line .. space .. w
      if not predicate(new_line) then
        last = w
        return line
      end
      line = new_line
      space = ' '
    end
    --no more words
    if last then
      last = nil
      return line
    end
  end)
end

return tu
