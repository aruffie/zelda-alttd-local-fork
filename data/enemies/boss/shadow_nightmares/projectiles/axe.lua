----------------------------------
--
-- Shadow of Ganon's Axe.
--
-- A double axe that can be throwed to the hero.
--
-- Methods : enemy:start_taking(offset_x, offset_y)
--           enemy:start_spinning(offset_x, offset_y)
--           enemy:start_aiming(offset_x, offset_y)
--           enemy:start_throwed()
--
-- Events : enemy:on_took()
--          enemy:on_catched()
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
local throwed_speed = 120
local throwed_distance = 200

-- Start the enemy being throwed.
function enemy:start_throwed(thrower_entity)

  sprite:set_xy(0, 0)
  sprite:set_animation("spinning")
  local go_movement = enemy:start_straight_walking(enemy:get_angle(hero), throwed_speed, throwed_distance, function()
    local back_movement = enemy:start_target_walking(thrower_entity, throwed_speed)

    -- Stop the back movement when the position is the same than the thrower one.
    function back_movement:on_position_changed()
      local thrower_x, thrower_y = thrower_entity:get_position()
      local x, y = enemy:get_position()
      if thrower_x == x and thrower_y == y then
        back_movement:stop()
        if enemy.on_catched then
          enemy:on_catched()
        end
      end
    end
  end)
  go_movement:set_smooth(false)
end

-- Start spinning the enemy.
function enemy:start_aiming(offset_x, offset_y)

  sprite:set_xy(offset_x, offset_y)
  sprite:set_animation("aiming")
end

-- Start spinning the enemy.
function enemy:start_spinning(offset_x, offset_y)

  sprite:set_xy(offset_x, offset_y)
  sprite:set_animation("spinning")
end

-- Start being taken in hand.
function enemy:start_taking(offset_x, offset_y)

  sprite:set_xy(offset_x, offset_y)
  sprite:set_animation("taking", function()
    sprite:set_animation("took")
    if enemy.on_took then
      enemy:on_took()
    end
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  enemy:set_invincible()
  enemy:set_can_attack(true)
  enemy:set_damage(4)
end)
