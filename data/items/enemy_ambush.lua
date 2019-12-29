----------------------------------
--
-- Item that can be contained in a chest and makes an enemy spawn on obtaining.
-- Herit custom properties from the chest.
--
-- Heritable properties : breed, jumping_angle
--
----------------------------------

-- Variables
local item = ...
local game = item:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Default configuration variables.
local breed = "zol_green"
local waiting_duration = 1000
local jumping_duration = 1000
local jumping_height = 16
local jumping_angle = 0
local jumping_speed = 16

-- Event called when the game is initialized.
function item:on_created()
  item:set_sound_when_brandished(nil)
end

function item:on_obtaining()

  -- Get opened chest assuming opened from south, and get its heritable properties.
  local map = game:get_map()
  local hero = map:get_hero()
  local x, y, layer = hero:get_position()
  y = y - 16
  for chest in map:get_entities_by_type("chest") do
    if chest:overlaps(x, y) then
      x, y, layer = chest:get_position()
      breed = chest:get_property("breed")
      jumping_angle = chest:get_property("jumping_angle") or jumping_angle
    end
  end

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
    local movement = enemy:start_jumping(jumping_duration, jumping_height, jumping_angle, jumping_speed, function()
      enemy:restart()
    end)
    movement:set_ignore_obstacles(true)
  end)

  -- Skip the brandish animation when obtaining an enemy in a chest.
  map:get_hero():unfreeze()

  -- Sound
  audio_manager:play_sound("misc/error")
end
