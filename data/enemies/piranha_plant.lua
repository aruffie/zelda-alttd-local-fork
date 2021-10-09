----------------------------------
--
-- Piranha Plant.
--
-- Immobile enemy in sideview maps that starts hidden, then rush out and bite, and finally go back to its initial state.
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local height
local quarter = math.pi * 0.5

-- Configuration variables.
local out_speed = 80
local back_speed = 20
local hidden_duration = 1500
local biting_duration = 2000

-- Go back to the initial state and restarts.
local function go_back()

  local movement = sol.movement.create("straight")
  movement:set_speed(back_speed)
  movement:set_angle(3.0 * quarter)
  movement:set_max_distance(height)
  movement:start(sprite)
  sprite:set_animation("immobile")

  function movement:on_finished()
    enemy:restart()
  end
end

-- Rush out and bite.
local function rush_out()

  local movement = sol.movement.create("straight")
  movement:set_speed(out_speed)
  movement:set_angle(quarter)
  movement:set_max_distance(height)
  movement:start(sprite)

  function movement:on_finished()
    sprite:set_animation("biting")
    sol.timer.start(enemy, biting_duration, function()
      go_back()
    end)
  end

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = 1,
  	boomerang = 1,
  	explosion = 1,
  	sword = 1,
  	thrown_item = 1,
  	fire = 1,
  	jump_on = "ignored",
  	hammer = 1,
  	hookshot = 1,
  	magic_powder = 1,
  	shield = "protected",
  	thrust = 1
  })
end

-- Workaround: No way to set a clipping rectangle to a drawable or entity, do it manually to not draw the hidden part in case tiles under are too skinny.
enemy:set_draw_override(function()

  local x, y = enemy:get_position()
  local camera_x, camera_y = camera:get_position()
  local _, sprite_y = sprite:get_xy()
  local width, height = sprite:get_size()
  sprite:draw_region(-8, -height + 3, width, height - sprite_y, camera:get_surface(), x - camera_x, y - camera_y) -- Region is relative to the sprite origin.
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 32)
  enemy:set_origin(8, 29)
  _, height = sprite:get_size()
  sprite:set_xy(0, height)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_animation("immobile")
  enemy:set_invincible()
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  sol.timer.start(enemy, hidden_duration, function()
    rush_out()
  end)
end)
