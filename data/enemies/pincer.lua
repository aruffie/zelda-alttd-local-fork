-- Lua script of pincer.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("enemies/lib/weapons").learn(enemy)
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local body_sprites = {}
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25
local before_go_back_timer

-- Configuration variables
local charging_speed = 128
local charging_distance = 48
local go_back_speed = 64
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000
local appearing_duration = 1000
local before_go_back_delay = 600

-- Update the body sprites position depending on the head one.
function enemy:update_body_sprites_position()

  local head_x, head_y, _ = head_sprite:get_xy()
  for i = 1, 3 do
    body_sprites[i]:set_xy(head_x / 4.0 * i, head_y / 4.0 * i)
  end
end

-- Start charging the hero.
function enemy:start_charging()

  local movement = sol.movement.create("straight")
  local angle = enemy:get_angle(hero)
  movement:set_speed(charging_speed)
  movement:set_max_distance(charging_distance)
  movement:set_angle(angle)
  movement:start(head_sprite)
  function movement:on_position_changed()
    enemy:update_body_sprites_position()
  end

  head_sprite:set_direction(enemy:get_direction4_to(hero))
  for i = 1, 3 do
    body_sprites[i]:set_opacity(255)
  end

  -- Go back on movement finished.
  function movement:on_finished()
    before_go_back_timer = sol.timer.start(enemy, before_go_back_delay, function()
      before_go_back_timer = nil
      local back_movement = sol.movement.create("straight")
      back_movement:set_speed(go_back_speed)
      back_movement:set_max_distance(charging_distance)
      back_movement:set_angle(angle + math.pi)
      back_movement:start(head_sprite)
      function back_movement:on_position_changed()
        enemy:update_body_sprites_position()
      end
      function back_movement:on_finished()
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

    -- Behavior for each items.
    enemy:set_hero_weapons_reactions(2, {
      sword = 1,
      magic_powder = "immobilized",
      jump_on = "ignored"
    })
    enemy:set_can_attack(true)
    head_sprite:set_animation("walking")

    enemy:start_charging()
  end)
end

-- Wait a few time and appear.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      return waiting_duration
    end
    enemy:appear()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 8)

  for i = 1, 3 do
    body_sprites[4 - i] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
    enemy:bring_sprite_to_back(body_sprites[4 - i]) -- Bring last sprite to back first.
  end
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

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
  enemy:set_invincible()
  enemy:set_pushed_back_when_hurt(false)
  enemy:wait()
end)

