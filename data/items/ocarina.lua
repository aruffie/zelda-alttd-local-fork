-- Lua script of item "ocarina".
-- This script is executed only once for the whole game.

local item = ...
local game = item:get_game()

function item:on_created()

  item:set_savegame_variable("possession_ocarina")
  item:set_sound_when_brandished(nil)
  item:set_assignable(true)
  
end

-- Event called when the hero is using this item.
function item:on_using()

  item:playing_song("items/ocarina")
  item:set_finished()

end

function item:playing_song(music, callback)

   local map = game:get_map()
   local hero = map:get_hero()
   local x,y,layer = hero:get_position()
   hero:set_animation("playing_ocarina", function()
     game:set_pause_allowed(true)
     notes:remove()
     notes2:remove()
   end)
  local notes = map:create_custom_entity{
    x = x,
    y = y,
    layer = layer + 1,
    width = 24,
    height = 32,
    direction = 0,
    sprite = "entities/symbols/notes"
  }
  local notes2 = map:create_custom_entity{
    x = x,
    y = y,
    layer = layer + 1,
    width = 24,
    height = 32,
    direction = 2,
    sprite = "entities/symbols/notes"
  }
  audio_manager:play_sound(music)
  local timer = sol.timer.start(map, 4000, function()
    notes:remove()
    notes2:remove()
    if callback ~= nil then
      callback()
    end
  end)

end

