-- Initialize block behavior specific to this quest.

-- Variables
local game_meta = sol.main.get_metatable("game")

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")

game_meta:register_event("on_map_changed", function(game, map)

    -- Init infinite timer and check if sound is played
    local crystal_state = map:get_crystal_state() 
    local timer = sol.timer.start(map, 50, function()  
        local changed = map:get_crystal_state() ~= crystal_state
        crystal_state = map:get_crystal_state()
        if changed and not map:get_game():is_suspended() then
          audio_manager:play_sound("misc/dungeon_crystal")
        end
        return true
      end)
    timer:set_suspended_with_map(false)

  end)
game_meta:register_event("on_draw", function(game, dst_surface)

    if game.map_in_transition then
      dst_surface:fill_color({0,0,0})
    end

  end)

game_meta:register_event("on_command_pressed", function(game, command)
    print "item_command ?"
    if not game:is_suspended() then
      local item_1 = game:get_item_assigned("1")
      local item_2 = game:get_item_assigned("2")
      if command =="item_1" and item_1 then
        if item_1.start_using then
          item_1:start_using()
          return true
        end
      elseif command=="item_2" and item_2 then
        if item_2.start_using then
          item_2:start_using()
          return true
        end
      end
    end
  end)
