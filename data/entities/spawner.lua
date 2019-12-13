
-- Global variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local camera = map:get_camera()
local is_active = false
local is_exhausted = false

-- Configuration variables
local minimum_time = entity:get_property("minimum_time") or 2000
local maximum_time = entity:get_property("maximum_time") or 4000
local breed = entity:get_property("breed")
local treasure_name = entity:get_property("treasure_name") or "random_with_charm"
local treasure_variant = entity:get_property("treasure_variant") or 1

-- Return true if the spawner is active.
function entity:is_active()
  return is_active
end

-- Make spawner create a new enemy and schedule next one.
function entity:start()

  is_active = true

  if not is_exhausted then
    entity:spawn()

    sol.timer.start(entity, math.random(minimum_time, maximum_time), function()
      is_exhausted = false
      if is_active then
        entity:spawn()
        return math.random(minimum_time, maximum_time)
      end
    end)
  end
end

-- Make spawner stop creating new enemies.
function entity:stop()
  is_active = false
end

-- Create the given enemy.
function entity:spawn()

  is_exhausted = true
  local x, y, layer = entity:get_position()
  local enemy = map:create_enemy({
    breed = breed,
    x = x,
    y = y,
    layer = layer,
    direction = direction or math.random(4) - 1,
    treasure_name = treasure_name,
    treasure_variant = treasure_variant
  })

  -- Call an entity:on_enemy_spawned(enemy) event.
  if entity.on_enemy_spawned then
    entity:on_enemy_spawned(enemy)
  end
end
