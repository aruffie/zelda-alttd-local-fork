-- Lua script of item melody_2.
-- This script is executed only once for the whole game.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local item = ...
local game = item:get_game()
local shader_ocarina = sol.shader.create("ocarina_warp")
local warp_magnitude = 0.01

-- Event called when the game is initialized.
function item:on_started()

  self:set_savegame_variable("possession_melody_2")
  self:set_assignable(true)
  
  game:register_event("on_map_changed", function(game, map)
    map:register_event("on_draw", function(map, surface)
        local teleport_warp_effect = game:get_value("teleport_warp_effect")
        if teleport_warp_effect == "start"  or teleport_warp_effect == "stop" then
          if teleport_warp_effect == "start" then
            warp_magnitude = warp_magnitude + 0.001
            if warp_magnitude > 0.1 then
              warp_magnitude = 0.1
              game:set_value("teleport_warp_effect",  "stop");
            end
          else
            warp_magnitude = warp_magnitude - 0.001
            if warp_magnitude < 0.01 then
              warp_magnitude = 0.01
              game:set_value("teleport_warp_effect",  nil);
            end
          end
          shader_ocarina:set_uniform("magnitude", warp_magnitude)
          surface:set_shader(shader_ocarina)
        else
              surface:set_shader(nil)
        end
      end)

  end)

end

-- Event called when the hero is using this item.
function item:on_using()

    local map = game:get_map()
    local hero = map:get_hero()
    local ocarina = game:get_item("ocarina")
    ocarina:playing_song("items/ocarina_2")
    sol.timer.start(map, 4000, function()
        game:set_value("teleport_warp_effect", "start");
        sol.audio.play_sound("items/ocarina_2_warp")
         sol.timer.start(map, 2000, function()
            hero:teleport("out/b2_graveyard", "ocarina_2", "fade")
         end)
     end)
    item:set_finished()
end