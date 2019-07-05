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
    print "songle item arrow"
    item:get_map():get_entity("hero"):start_bow()
  end

end
-- Event called when the hero is using this item.
function item:start_combo(other)

  local map=game:get_map()
  print ("trying to fire a combined arrow launch (arrows: "..item:get_amount()..", other: "..other:get_amount()..")")
  if item:get_amount() == 0 then

    if other.start_using then
      other:start_using()
    else
      audio_manager:play_sound("misc/error")  
    end
  else
    -- we remove the arrow from the equipment after a small delay because the hero
    -- does not shoot immediately

    --TODO get rid of this useless timer once the bomb-arrow sprite is ready
    sol.timer.start(300, function()
        item:remove_amount(1)
      end)


    if other:get_name()=="bombs_counter" and other:get_amount()>0 then
      --Bomb-arrows!
      --  sol.timer.start(item, 400, function()
      other:remove_amount(1)
      print "Bomb and arrows!"
      local hero=game:get_hero()
      local x,y,layer=hero:get_position()
      local direction = hero:get_direction()
      if direction == 0 then
        x = x + 16
        y = y - 7
      elseif direction == 1 then
        y = y - 16
      elseif direction == 2 then
        x = x - 16
        y = y - 7
      elseif direction == 3 then
        y = y + 16
      end

      local bomb_arrow = map:create_custom_entity{
        name="bomb_arrow",
        x = x,
        y = y,
        layer = layer,
        width=8,
        height=8,

        sprite = "entities/bomb_arrow",
        direction=direction,
      }
      bomb_arrow.apply_cliffs=true,
      bomb_arrow:set_origin(4,4)
      bomb_arrow:set_can_traverse("explosion", true)
      bomb_arrow:set_can_traverse("teletransporter", true)
      bomb_arrow:set_can_traverse("custom_entity", true)
      bomb_arrow:set_can_traverse("jumper", true)
      bomb_arrow:set_can_traverse("npc", function(entity, other)
          --TODO check for NPC type when a function like "npc:is_generalized()" is available
          return other:is_drawn_in_y_order() or other:is_traversable()
        end)
      bomb_arrow:set_can_traverse_ground("hole", true)
      bomb_arrow:set_can_traverse_ground("deep_water", true)
      bomb_arrow:set_can_traverse_ground("shallow_water", true)
      bomb_arrow:set_can_traverse_ground("low_wall", true)
      bomb_arrow:set_can_traverse_ground("lava", true)
      bomb_arrow:set_can_traverse_ground("prickles", true)


      local m=sol.movement.create("straight")
      m:set_speed(192)
      m:set_angle(direction*math.pi/2)
      m.on_obstacle_reached=function()
        --TODO find a way to ignore axisting explosions
        print "BOOM"
        --Will it explode on it's own ? no :(
        local x,y,layer=bomb_arrow:get_position()
        audio_manager:play_sound("items/bomb_explode")
        map:create_explosion({
            x=x, 
            y=y,
            layer=layer,
          })
        bomb_arrow:remove()
      end
      m:start(bomb_arrow)
      --   end)
    else
      --Trigger normal arrow so we don't break the standard behavior
      item:get_map():get_entity("hero"):start_bow()
    end
  end
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

