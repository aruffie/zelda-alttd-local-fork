local lib ={}

-- Returns whether the ground at given coordinates is a ladder.
function lib:is_position_on_ladder(map, x, y)

  for entity in map:get_entities_in_rectangle(x, y, 1, 1) do
    if entity:get_type() == "custom_entity" and entity:get_model() == "ladder" then
      return true
    end
  end

  return false
end

-- Return whether the ground over the entity is a ladder.
  function lib:is_on_ladder(entity)

  local map = entity:get_map()
  local x, y = entity:get_position() 
  return self:is_position_on_ladder(map, x, y - 2) or self:is_position_on_ladder(map, x, y + 2)
end

-- Return whether the hero is above a ladder.
function lib:is_above_ladder(entity)

  local x, y = entity:get_position()
  return entity:test_obstacles(0, 1) or not self:is_on_ladder(entity) and self:is_position_on_ladder(entity:get_map(), x, y + 3)
end

-- Check if an enemy sensible to jump is overlapping the hero, then hurt it and bounce.
function lib:on_bounce_possible(entity)

  local map = entity:get_map()
  local hero = map:get_hero()
  for enemy in map:get_entities_by_type("enemy") do
    if hero:overlaps(enemy, "overlapping") and enemy:get_life() > 0 and not enemy:is_immobilized() then
      local reaction = enemy:get_jump_on_reaction()
      if reaction ~= "ignored" then
        enemy:receive_attack_consequence("jump_on", reaction)
        entity.vspeed = 0 - math.abs(entity.vspeed)
      end
    end
  end
  return entity.vspeed or 0
end

return lib
