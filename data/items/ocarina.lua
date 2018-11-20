local item = ...
local game = item:get_game()

function item:on_created()

  self:set_savegame_variable("possession_ocarina")
  self:set_sound_when_brandished("treasure_2")
  self:set_assignable(true)
end


function item:on_using()

  item:playing_song("items/ocarina")
  self:set_finished()

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
    sprite = "entities/notes"
  }
  local notes2 = map:create_custom_entity{
    x = x,
    y = y,
    layer = layer + 1,
    width = 24,
    height = 32,
    direction = 2,
    sprite = "entities/notes"
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

