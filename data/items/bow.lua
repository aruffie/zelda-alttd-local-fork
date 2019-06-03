-- Lua script of item "bow".
-- This script is executed only once for the whole game.

-- Variables
local item = ...
local game=item:get_game()

local audio_manager=require("scripts/audio_manager")
-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_bow")
  item:set_amount_savegame_variable("amount_bow")
  item:set_assignable(true)

end

-- Event called when the hero is using this item.
function item:start_using()

  if item:get_amount() == 0 then
    audio_manager:play_sound("misc/error")
  else
    -- we remove the arrow from the equipment after a small delay because the hero
    -- does not shoot immediately
    sol.timer.start(300, function()
        item:remove_amount(1)
      end)

    --Bomb-arrows!
    if game.last_item_1=="bombs_counter" or game.last_item_2=="bombs_counter" then
      print "Bomb and arrows!"
      local hero=game:get_hero()
      local x,y,layer=hero:get_position()
      local direction = hero:get_direction()
      if direction == 0 then
        x = x + 16
      elseif direction == 1 then
        y = y - 16
      elseif direction == 2 then
        x = x - 16
      elseif direction == 3 then
        y = y + 16
      end
      
      local bomb = game:get_map():create_bomb{
        x = x,
        y = y,
        layer = layer
      }

    local m=sol.movement.create("straight")
    m:set_speed(96)
    m:set_angle(hero:get_direction()*math.pi/2)
    m:start(bomb, function()
        print "BOOM"
          --Will it explode on it's own ?
        end)
    end

    item:get_map():get_entity("hero"):start_bow()
  end
  item:set_finished()

end

function item:on_amount_changed(amount)

  if item:get_variant() ~= 0 then
    if amount == 0 then
      item:set_variant(1)
    else
      item:set_variant(2)
    end
  end

end

function item:on_obtaining(variant, savegame_variable)

  local quiver = itrm:get_game():get_item("quiver")
  if not quiver:has_variant() then
    quiver:set_variant(1)
  end

end

