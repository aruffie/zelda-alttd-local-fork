-- Lua script of item "ocarina".
-- This script is executed only once for the whole game.

local item = ...
local game = item:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()

  item:set_savegame_variable("possession_ocarina")
  item:set_sound_when_brandished(nil)
  item:set_assignable(true)
  
end

-- Event called when the hero is using this item.
function item:on_using()

  item:playing_song("items/ocarina_default")
  item:set_finished()

end

-- Play fanfare sound on obtaining.
function item:on_obtaining()
  
  audio_manager:play_sound("items/fanfare_item_extended")
  
end


function item:playing_song(music, callback)

  local map = game:get_map()
  local hero = map:get_hero()
  local x,y,layer = hero:get_position()
  hero:freeze()
  game:set_pause_allowed(false)
  hero:set_animation("playing_ocarina")
  local notes = map:create_custom_entity{
    x = x,
    y = y,
    layer = layer,
    width = 24,
    height = 32,
    direction = 0,
    sprite = "entities/symbols/notes"
  }
  local notes2 = map:create_custom_entity{
    x = x,
    y = y,
    layer = layer,
    width = 24,
    height = 32,
    direction = 2,
    sprite = "entities/symbols/notes"
  }
  audio_manager:play_sound(music)
  local timer = sol.timer.start(map, 4000, function()
    notes:remove()
    notes2:remove()
    hero:unfreeze()
    game:set_pause_allowed(true)
    if callback ~= nil then
      callback()
    end
  end)

end

