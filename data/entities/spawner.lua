
-- Global variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local camera = map:get_camera()
local is_running = true

-- Configuration variables
local minimum_time = entity:get_property("minimum_time") or 2000
local maximum_time = entity:get_property("maximum_time") or 4000
local breed = entity:get_property("breed")
local treasure_name = entity:get_property("treasure_name") or "random_with_charm"
local treasure_variant = entity:get_property("treasure_variant") or 1

-- Make spawner start creating new enemies.
function entity:start()
  is_running = true
end

-- Make spawner stop creating new enemies.
function entity:stop()
  is_running = false
end

-- Initialization.
function entity:on_created()

  if breed then
    sol.timer.start(entity, math.random(minimum_time, maximum_time), function()
      if is_running then
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

      return math.random(minimum_time, maximum_time)
    end)
  end
end
