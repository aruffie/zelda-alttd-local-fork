-- Lua script of enemy "pike auto".
-- This script is executed every time an enemy with this model is created.

-- Pike that always moves, horizontally or vertically
-- depending on its direction.

-- Variables
local enemy = ...
local recent_obstacle = 0

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_damage(4)
  enemy:create_sprite("enemies/pike_auto")
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_can_hurt_hero_running(true)
  enemy:set_invincible()
  enemy:set_attack_consequence("sword", "protected")
  enemy:set_attack_consequence("thrown_item", "protected")
  enemy:set_attack_consequence("arrow", "protected")
  enemy:set_attack_consequence("hookshot", "protected")
  enemy:set_attack_consequence("boomerang", "protected")
  
end)

-- The enemy was stopped for some reason and should restart.
enemy:register_event("on_restarted", function(enemy)

  local sprite = enemy:get_sprite()
  local direction4 = sprite:get_direction()
  local m = sol.movement.create("path")
  m:set_path{direction4 * 2}
  m:set_speed(192)
  m:set_loop(true)
  m:start(enemy)
end)


enemy:register_event("on_obstacle_reached", function(enemy)

  local sprite = enemy:get_sprite()
  local direction4 = sprite:get_direction()
  sprite:set_direction((direction4 + 2) % 4)

  local x, y = enemy:get_position()
  local hero_x, hero_y = enemy:get_map():get_entity("hero"):get_position()
  if recent_obstacle == 0
    and math.abs(x - hero_x) < 184
    and math.abs(y - hero_y) < 144 then
    audio_manager:play_entity_sound(enemy, "enemies/blade_trap")
  end

  recent_obstacle = 8
  enemy:restart()
end)


enemy:register_event("on_position_changed", function(enemy)

  if recent_obstacle > 0 then
    recent_obstacle = recent_obstacle - 1
  end
end)

