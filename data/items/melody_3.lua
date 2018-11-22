-- Variables
local item = ...
local game = item:get_game()

function item:on_started()

  self:set_savegame_variable("possession_melody_3")
  self:set_assignable(true)

end

function item:on_using()

    local map = game:get_map()
    local hero = map:get_hero()
    local ocarina = game:get_item("ocarina")
    hero:freeze()
    game:set_pause_allowed(false)
    ocarina:playing_song("items/ocarina_3", function()
        hero:unfreeze()
        game:set_pause_allowed(true)
    end)

  item:set_finished()
  
end
