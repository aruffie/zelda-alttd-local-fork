-- Lua script of enemy "pike detect".
-- This script is executed every time an enemy with this model is created.

-- Pike that moves when the hero is close.

-- Variables
local enemy = ...
local state = "stopped"  -- "stopped", "moving", "going_back" or "paused".
local initial_xy = {}
local activation_distance = 24

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_damage(4)
  enemy:create_sprite("enemies/pike_detect")
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_can_hurt_hero_running(true)
  enemy:set_invincible()
  enemy:set_attack_consequence("sword", "protected")
  enemy:set_attack_consequence("thrown_item", "protected")
  enemy:set_arrow_reaction("protected")
  enemy:set_attack_consequence("hookshot", "protected")
  enemy:set_attack_consequence("boomerang", "protected")
  initial_xy.x, initial_xy.y = enemy:get_position()
  
end)

-- The enemy restart: reset its state.
enemy:register_event("on_restarted", function(enemy)
  state = "stopped"
end)

enemy:register_event("on_update", function(enemy)

  local hero = enemy:get_map():get_entity("hero")
  if state == "stopped" and enemy:get_distance(hero) <= 192 then
    -- Check whether the hero is close.
    local x, y = enemy:get_position()
    local hero_x, hero_y = hero:get_position()
    local dx, dy = hero_x - x, hero_y - y

    if math.abs(dy) < activation_distance then
      if dx > 0 then
	enemy:go(0)
      else
	enemy:go(2)
      end
    end
    if state == "stopped" and math.abs(dx) < activation_distance then
      if dy > 0 then
	enemy:go(3)
      else
	enemy:go(1)
      end
    end
  end
  
end)

function enemy:go(direction4)

  local dxy = {
    { x =  8, y =  0},
    { x =  0, y = -8},
    { x = -8, y =  0},
    { x =  0, y =  8}
  }

  -- Check that we can make the move.
  local index = direction4 + 1
  if not enemy:test_obstacles(dxy[index].x * 2, dxy[index].y * 2) then

    state = "moving"

    local x, y = enemy:get_position()
    local angle = direction4 * math.pi / 2
    local m = sol.movement.create("straight")
    m:set_speed(192)
    m:set_angle(angle)
    m:set_max_distance(104)
    m:set_smooth(false)
    m:start(enemy)
  end
  
end

enemy:register_event("on_obstacle_reached", function(enemy)

  enemy:go_back()
  
end)

enemy:register_event("on_movement_finished", function(enemy)

  enemy:go_back()
  
end)

enemy:register_event("on_collision_enemy", function(enemy, other_enemy, other_sprite, my_sprite)

  if other_enemy:get_breed() == enemy:get_breed() and state == "moving" then
    enemy:go_back()
  end
end)

function enemy:go_back()

  if state == "moving" then

    state = "going_back"

    local m = sol.movement.create("target")
    m:set_speed(64)
    m:set_target(initial_xy.x, initial_xy.y)
    m:set_smooth(false)
    m:start(enemy)
    audio_manager:play_entity_sound(enemy, "enemies/blade_trap")

  elseif state == "going_back" then

    state = "paused"
    sol.timer.start(enemy, 500, function() enemy:unpause() end)
  end
  
end

function enemy:unpause()
  
  state = "stopped"
  
end

