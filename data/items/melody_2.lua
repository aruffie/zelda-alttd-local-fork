-- Lua script of item melody_2.
-- This script is executed only once for the whole game.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local item = ...
local game = item:get_game()

require("scripts/multi_events")

-- Event called when the game is initialized.
function item:on_started()

  self:set_savegame_variable("possession_melody_2")
  self:set_assignable(true)

end

-- Event called when the hero is using this item.
function item:on_using()

    local map = game:get_map()
    local hero = map:get_hero()
    local camera = map:get_camera()
    local ocarina = game:get_item("ocarina")
    local surface = camera:get_surface()
    local effect_model = require("scripts/gfx_effects/distorsion")
    hero:freeze()
    game:set_pause_allowed(false)
    ocarina:playing_song("items/ocarina_2", function()
      game:set_suspended(true)
      game:set_hud_enabled(false)
      game:set_value("teleport_warp_effect", "start");
      audio_manager:play_sound("items/ocarina_2_warp")
       -- Execute In effect
      effect_model.start_effect(surface, game, "in", false, function()
          local dungeon = game:get_dungeon()
          local map_id = "out/b2_graveyard"
          local destination_id = "ocarina_2"
          if dungeon ~= nil and dungeon.destination_ocarina ~= nil then
            map_id = dungeon.destination_ocarina.map_id
            destination_id = dungeon.destination_ocarina.destination_name
          end
          if map:get_id() ~= map_id then
              hero:teleport(map_id, destination_id, "immediate")
              game.map_in_transition = effect_model
          else
              hero:teleport(map_id, destination_id, "immediate")
              effect_model.start_effect(surface, game, "out", false, function()
                game:set_suspended(false)
                game:set_hud_enabled(true)
                game:set_pause_allowed(true)
              end)
          end
      end)
    end)
    item:set_finished()
end