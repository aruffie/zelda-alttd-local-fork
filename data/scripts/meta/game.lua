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


-- Global override function for item use that completely avoids triggering the "item" state and allows full control over item behavior. All you need to do is to define item:start_using in your item script. If not, then it will just be ignored and trigger item:on_using as usual.

game_meta:register_event("on_command_pressed", function(game, command)
    print "item_command ?"
    if not game:is_suspended() then
      local item_1 = game:get_item_assigned("1")
      local item_2 = game:get_item_assigned("2")
      local name_1 = item_1:get_name()
      local name_2 = item_2:get_name()
      --mark items as triggered
      local handled = false
      if command =="item_1" and item_1~=nil then
        print "Item 1 triggered"
        game.last_item_1=name_1
        handled = item_1.start_combo ~= nil or item_1.start_combo ~= nil
        sol.timer.start(game, 30, function()
            --Delay resetting combo register for next cycle after combo checking
            print "Item 1 resetted"
            game.last_item_1=nil
          end)
      elseif command == "item_2" and item_2~=nil then 
        print "Item 2 triggered"
        game.last_item_2=name_2
        handled = item_2.start_combo ~= nil or item_2.start_combo ~= nil
        sol.timer.start(game, 30, function()
            --Delay resetting combo registers for next cycle after combo_checking
            print "Item 2 resetted"
            game.last_item_2=nil  
          end)
      end
      --If at least one item has been triggered, then start checking if botg items are in use at the same time
      if game.last_item_1~=nil or game.last_item_2~=nil then
        --This timer ensures we have enough time to press the other command before falling back to single-item behavior
        sol.timer.start(game, 20, function()
            --Do not trigger the combo twice in the same cycle
            if game.item_combo ~= true and game.last_item_1~=nil and game.last_item_2~=nil then
              print "Combination detected"
              game.item_combo=true
              sol.timer.start(game, 30, function()
                  game.item_combo=nil
                end)


              --Both items are trying to be used at the same time, so try to start the combo for them
              if item_1.start_combo then
                print ("Using combined behavior for item 1 ("..name_1..") with "..name_2)
                item_1:start_combo(item_2)
                return
              elseif item_2.start_combo then
                print ("Using combined behavior for item 2 ("..name_2..") with "..name_1)
                item_2:start_combo(item_1)
                return
              end
            end
            -- If the combo was not successful, try using the override starter on each item individually
            if not game.item_combo then
              if game.last_item_1 and item_1.start_using~=nil then
                print "item 1"
                item_1:start_using()
                return
              elseif game.last_item_2 and item_2.start_using~=nil then
                item_2:start_using()
                print "item 2"
                return
              end
            end
          end)


      end
      return handled
    end
  end)
