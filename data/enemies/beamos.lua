-- Lua script of enemy beamos.
-- This script is executed every time an enemy with this model is created.

-- Global variables.
local enemy = ...
local map = enemy:get_map()
local hero = map:get_hero()
local audio_manager = require("scripts/audio_manager")

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local angle_per_frame = 2 * math.pi / sprite:get_num_frames()

-- Configuration variables.
local triggering_angle = angle_per_frame * 1.5
local start_shooting_delay = 200
local pause_duration = 1000
local is_exhausted_duration = 200

-- Properties
function enemy:on_created()

  self:set_invincible()
  self:set_damage(2)
  self.is_exhausted = false -- True after a shoot and before a delay.
end

-- Function to start firing.
function enemy:start_firing()

  -- Pause the animation.
  sprite:set_paused()

  -- Save the hero position at this point to use it as the target of the laser.
  local firing_target_x, firing_target_y, firing_target_layer = hero:get_position()

  -- Start the laser after some time.
  sol.timer.start(enemy, start_shooting_delay, function()

    self.is_exhausted = true 

    -- Create laser entities.
    self:create_enemy({
      breed =  "eyegore_statue/eyegore_statue_fireball", -- TODO
      x = 0,
      y = 0
    })

    -- Unpause animation after some time.
    sol.timer.start(enemy, pause_duration, function()
      sprite:set_paused(false)

      -- Allow to shoot again after a delay.
      sol.timer.start(enemy, is_exhausted_duration, function()
        self.is_exhausted = false 
      end)
    end)
  end)
end

-- Check if the beamos is facing the hero at each frame change, then stop and shoot.
function sprite:on_frame_changed(animation, frame)

  if not enemy.is_exhausted then
    local x, y, _ = enemy:get_position()
    local hero_x, hero_y, _ = hero:get_position()
    local enemy_angle = frame * angle_per_frame - math.pi / 2.0 -- Frame 0 of the sprite faces the south.
    local hero_angle = math.atan2(y - hero_y, hero_x - x)

    if (math.abs(enemy_angle - hero_angle) + math.pi * 2.0) % (math.pi * 2.0) <= triggering_angle then
      enemy:start_firing()
    end
  end
end
