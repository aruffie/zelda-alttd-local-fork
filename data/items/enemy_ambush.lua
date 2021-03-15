----------------------------------
--
-- Item that can be contained in a chest and makes an enemy appear and jump out the chest on obtaining.
-- Herit custom properties from the chest.
--
-- Events :            chest:on_enemy_released(enemy)
--                     chest:on_enemy_jump_out_finished(enemy)
--
-- Custom properties : breed
--                     jumping_angle
--
----------------------------------

-- Variables
local item = ...
local game = item:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Configuration variables default value.
local breed = "zol_chest"
local waiting_duration = 1000
local jumping_duration = 1000
local jumping_height = 16
local jumping_angle = 0
local jumping_speed = 16

-- Make the enemy start jumping out the chest.
-- TODO This is a duplicate of a enemies/lib/common_actions.lua function, factorize to entity meta one day.
local function start_jumping_out(enemy, duration, height, angle, speed, on_finished_callback)

  local movement

  -- Schedule an update of the sprite vertical offset by frame.
  local elapsed_time = 0
  sol.timer.start(enemy, 10, function()

    elapsed_time = elapsed_time + 10
    if elapsed_time < duration then
      for _, sprite in enemy:get_sprites() do
        sprite:set_xy(0, -math.sqrt(math.sin(elapsed_time / duration * math.pi)) * height)
      end
      return true
    else
      for _, sprite in enemy:get_sprites() do
        sprite:set_xy(0, 0)
      end
      if movement and enemy:get_movement() == movement then
        movement:stop()
      end

      -- Call events once jump finished.
      if on_finished_callback then
        on_finished_callback()
      end
    end
  end)

  -- Move the enemy on-floor.
  movement = sol.movement.create("straight")
  movement:set_speed(speed)
  movement:set_angle(angle)
  movement:set_smooth(false)
  movement:set_ignore_obstacles(true)
  movement:start(enemy)
end

-- Event called when the game is initialized.
function item:on_created()
  item:set_sound_when_brandished(nil)
end

function item:on_obtaining()

  -- Get opened chest assuming opened from south, and get its heritable properties.
  local chest
  local map = game:get_map()
  local hero = map:get_hero()
  local x, y, layer = hero:get_position()
  y = y - 16
  for map_chest in map:get_entities_by_type("chest") do
    if map_chest:overlaps(x, y) then
      chest = map_chest
    end
  end
  x, y, layer = chest:get_position()
  breed = chest:get_property("breed") or breed
  jumping_angle = chest:get_property("jumping_angle") or jumping_angle

  -- Create enemy
  local enemy = map:create_enemy({
    x = x,
    y = y,
    layer = layer,
    breed = breed,
    direction = 3,
  })
  local sprite = enemy:get_sprite()

  -- Make enemy freeze for a few time.
  sol.timer.stop_all(enemy)
  enemy:stop_movement()
  enemy:set_visible()
  sprite:set_animation("walking")
  sol.timer.start(enemy, waiting_duration, function()

    -- Then jump out of the chest.
    if sprite:has_animation("jumping") then
      sprite:set_animation("jumping")
    end
    start_jumping_out(enemy, jumping_duration, jumping_height, jumping_angle, jumping_speed, function()
      enemy:restart()
      if chest.on_enemy_jump_out_finished then
        chest:on_enemy_jump_out_finished(enemy)
      end
    end)
  end)

  -- Skip the brandish animation when obtaining an enemy in a chest.
  hero:unfreeze()

  -- Sound
  audio_manager:play_sound("misc/error")

  -- Release event.
  if chest.on_enemy_released then
    chest:on_enemy_released(enemy)
  end
end
