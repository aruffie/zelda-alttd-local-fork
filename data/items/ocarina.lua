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

function item:playing_song(music)

   local map = game:get_map()
   local hero = map:get_hero()
   local x,y,layer = hero:get_position()
   hero:freeze()
   game:set_pause_allowed(false)
   hero:set_animation("playing_ocarina")
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
  sol.audio.play_sound(music)
  sol.timer.start(map, 4000, function()
    game:set_pause_allowed(true)
    hero:unfreeze()
    notes:remove()
    notes2:remove()
  end)

end

