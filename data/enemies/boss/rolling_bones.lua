-- Lua script of enemy rolling bones.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
local map_tools = require("scripts/maps/map_tools")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25
local moving_angle = nil
local spike

-- Configuration variables
local waiting_duration = 500
local spike_speed = 150
local spike_slow_speed = 60
local jumping_speed = 120
local jumping_speed_increase_by_hp = 5
local jumping_height = 12
local jumping_duration = 500
local between_jumps_duration = 100

-- Return the direction to the further left/right or up/down side of the camera.
local function get_further_direction(direction4)

  local index = direction4 % 2 + 1
  local position = {enemy:get_position()}
  local camera_position = {camera:get_position()}
  local camera_size = {camera:get_size()}
  return ((position[index] - camera_position[index] > camera_position[index] + camera_size[index] - position[index] and 2 or 0) - index + 1) % 4
end

-- Start the enemy jumping movement to the opposite side of the room.
function enemy:start_moving()

  local jumping_angle = sol.main.get_angle(0, 0, math.cos(moving_angle), -math.sin(get_further_direction(1) * quarter))
  local jumping_final_speed = jumping_speed + jumping_speed_increase_by_hp * (8 - enemy:get_life())
  local movement = enemy:start_jumping(jumping_duration, jumping_height, jumping_angle, jumping_final_speed, function()
    if moving_angle then
      sol.timer.start(enemy, between_jumps_duration, function()
        enemy:start_moving(angle)
      end)
    else
      enemy:restart()
    end
  end)

  -- Stop moving on obstacle reached.
  function movement:on_obstacle_reached()
    movement:stop()
    moving_angle = nil
  end
end

-- Start pushing the spike.
function enemy:start_pushing(angle)

  local spike_sprite = spike:get_sprite()
  sol.timer.start(enemy, waiting_duration, function()
    sprite:set_animation("punching", function()

      -- Start spike movement on punching animation finished.
      moving_angle = angle -- Set the global direction angle here to not start pushing again if hurt.
      sprite:set_animation("immobilized")
      spike:start_straight_walking(angle, spike_speed, nil, function()

        -- Start an earthquake when the spike hit the wall and slightly move back.
        map_tools.start_earthquake({count = 12, amplitude = 4, speed = 90})
        spike:start_straight_walking(angle - math.pi, spike_slow_speed, 46, function()
          spike_sprite:set_animation("stopped")
        end)
        spike_sprite:set_frame_delay(100)
      end)
      spike_sprite:set_animation("walking")

      -- Start moving a little after.
      sol.timer.start(enemy, waiting_duration, function()
        enemy:start_moving()
      end)
    end)
  end)
end

-- Remove the spike on dead.
enemy:register_event("on_dead", function(enemy)

  spike:get_sprite():set_animation("destroyed", function()
    spike:remove()
  end)
end)

-- Remove the spike if rolling bones removed from outside this script.
enemy:register_event("on_removed", function(enemy)

  if spike:exists() then
    spike:remove()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(48, 24)
  enemy:set_origin(24, 21)
  enemy:set_hurt_style("boss")
  enemy:start_shadow("entities/shadows/giant_shadow")

  -- Create the spike.
  spike = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_spike",
    breed = "boss/projectile/spike",
    direction = 2,
    x = get_further_direction(0) == 2 and -30 or 30
  })
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    sword = 1
  })

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  if not moving_angle then
    local direction = get_further_direction(0)
    sprite:set_direction(direction)
    enemy:start_pushing(direction * quarter)
  else
    -- Finish moving if hurt during the movement.
    enemy:start_moving()
  end
end)
