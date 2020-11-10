----------------------------------
--
-- Piranha.
--
-- Moves horizontally and change direction once the ground is not water anymore.
-- Regularly jump out the water where he becomes vulnerable.
--
-- Methods : enemy:start_swimming([direction2])
--           enemy:dive()
--           enemy:jump()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local swimming_speed = 32
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000
local jumping_duration = 600
local jumping_height = 16

-- Start the enemy movement.
function enemy:start_swimming(direction2)

  direction2 = direction2 or math.random(2) - 1
  local current_animation = sprite:get_animation()

  -- Start a walking movement and change direction on stopped.
  local movement = enemy:start_straight_walking(direction2 * math.pi, swimming_speed, nil, function()
    enemy:start_swimming((direction2 + 1) % 2)
  end)
  movement:set_smooth(false)

  -- Also change the direction if the front ground is not water anymore.
  function movement:on_position_changed()
    local x, y, layer = enemy:get_position()
    if not enemy:is_over_grounds({"shallow_water", "deep_water"}) then
      movement:stop()
      enemy:start_swimming((direction2 + 1) % 2)
    end
  end

  -- Restore the previous animation.
  sprite:set_animation(current_animation)
end

-- Wait for some time then jump out of the water.
function enemy:dive()

  enemy:set_invincible()
  sprite:set_animation("walking")
  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    enemy:jump()
  end)
end

-- Jump out of the water.
function enemy:jump()

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

  -- Jump and dive when finished.
  sprite:set_animation("jumping")
  enemy:start_jumping(jumping_duration, jumping_height, nil, nil, function()
    local effect = enemy:start_brief_effect("entities/effects/fishing_water_effect", "normal")
    effect:bring_to_front()
    enemy:dive()
  end)

  -- Start diving animation at the middle of the jump.
  sol.timer.start(enemy, jumping_duration / 2.0, function()
    sprite:set_animation("diving")
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_obstacle_behavior("swimming")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:set_obstacle_behavior("swimming")
  enemy:dive()
  enemy:start_swimming()
end)
