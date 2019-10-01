local block_manager={}

function block_manager:init_block_riddle(map, block_prefix, callback)
  
  if not map.blocks_remaining then
    map.blocks_remaining={}
  end
  map.blocks_remaining[block_prefix] = map:get_entities_count(block_prefix)
  local game = map:get_game()
  local function block_on_moved()
    local remaining = map.blocks_remaining[block_prefix]
    remaining = remaining - 1
    map.blocks_remaining[block_prefix] = remaining
    if remaining == 0 then
      if callback then
        callback()
      end
    end
  end
  for block in map:get_entities(block_prefix) do
    block:register_event("on_moved", block_on_moved)
  end
  
end

return block_manager