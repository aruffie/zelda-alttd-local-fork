----------------------------------
--
-- Pincer.
--
-- Immobile enemy composed of a head and three body sprites.
-- Starts hidden and appear to try to bite the hero when close enough.
--
-- Methods : enemy:start_charging()
--           enemy:appear()
--           enemy:wait()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local head_sprite
local body_sprites = {}
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25
local waiting_timer, before_go_back_timer

-- Configuration variables
local triggering_distance = 64
local charging_speed = 128
local charging_distance = 40
local go_back_speed = 64
local appearing_duration = 1000
local before_go_back_delay = 600

-- Get the upper-left grid node coordinates of the enemy position.
local function get_grid_position()

  local position_x, position_y, _ = enemy:get_position()
  return position_x - position_x % 8, position_y - position_y % 8
end

-- Start charging to the given angle.
local function start_charging_movement(angle, speed)

  local movement = sol.movement.create("straight")
  movement:set_speed(speed)
  movement:set_max_distance(charging_distance)
  movement:set_angle(angle)
  movement:start(head_sprite)

  -- Update the body sprites position depending on the head one.
  function movement:on_position_changed()
    local head_x, head_y, _ = head_sprite:get_xy()
    for i = 1, 3 do
      body_sprites[i]:set_xy(head_x / 4.0 * i, head_y / 4.0 * i)
    end
  end

  return movement
end

-- Start charging to the hero and go back once finished.
function enemy:start_charging()

  -- Initialize sprites.
  head_sprite:set_direction(enemy:get_direction8_to(hero))
  for i = 1, 3 do
    body_sprites[i]:set_opacity(255)
  end

  -- Start movement.
  local angle = enemy:get_angle(hero)
  local movement = start_charging_movement(angle, charging_speed)

  -- Go back after a delay on movement finished.
  function movement:on_finished()
    before_go_back_timer = sol.timer.start(enemy, before_go_back_delay, function()
      before_go_back_timer = nil
      movement = start_charging_movement(angle + math.pi, go_back_speed)

      function movement:on_finished()
        enemy:restart()
      end
    end)
  end
end

-- Make the enemy appear.
function enemy:appear()

  enemy:set_visible()
  head_sprite:set_animation("seeking")
  head_sprite:set_direction(enemy:get_direction4_to(hero))
  sol.timer.start(enemy, appearing_duration, function()

    enemy:set_hero_weapons_reactions({
    	arrow = 2,
    	boomerang = 2,
    	explosion = 2,
    	sword = 1,
    	thrown_item = 2,
    	fire = 2,
    	jump_on = "ignored",
    	hammer = 2,
    	hookshot = 2,
    	magic_powder = "immobilized",
    	shield = "protected",
    	thrust = 2
    })

    enemy:set_can_attack(true)
    head_sprite:set_animation("walking")

    enemy:start_charging()
  end)
end

-- Wait for the hero to be near enough and appear.
function enemy:wait()

  waiting_timer = sol.timer.start(enemy, 50, function()
    if enemy:is_near(hero, triggering_distance) then
      enemy:appear()
      return false
    end
    return true
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(24, 24)
  enemy:set_origin(12, 12)
  enemy:set_position(get_grid_position()) -- Set the position to the center of the current 16*16 case instead of 8, 13.

  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  for i = 1, 3 do
    body_sprites[i] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
    enemy:bring_sprite_to_front(body_sprites[i])
  end
  enemy:bring_sprite_to_front(head_sprite)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_invincible()

  -- States.
  if before_go_back_timer then
    before_go_back_timer:stop()
    before_go_back_timer = nil
  end
  head_sprite:set_xy(0, 0)
  for i = 1, 3 do
    body_sprites[i]:set_opacity(0)
    body_sprites[i]:set_xy(0, 0)
  end
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_damage(4)
  enemy:set_pushed_back_when_hurt(false)
  enemy:wait()
end)

