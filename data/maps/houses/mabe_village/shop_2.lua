-- Variables
local map = ...
local game = map:get_game()
local merchant_move = false
local link_move = false

-- Include scripts
local shop_manager = require("scripts/maps/shop_manager")

-- Map events
function map:on_started(destination)

  map:init_music()
  map:init_map_entities()
  shop_manager:init(map)

end

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    sol.audio.play_music("maps/out/sword_search")
  else
    local thief_must_die = game:get_value("thief_must_die")
    if thief_must_die then
      sol.audio.play_music("maps/dungeons/boss")
    else
      sol.audio.play_music("maps/houses/shop")
    end
  end

end

-- Function that forces Merchent to always watch the hero with delay
function map:repeat_merchant_direction_check()

  local direction4 = merchant:get_direction4_to(hero)
  if direction4 == 0 then
    if merchant_move == false then
      merchant_move = true
      sol.timer.start(map, 1600, function() 
        merchant:get_sprite():set_direction(direction4)
        merchant_move = false
      end)
    end
  else
    if merchant_move == false then
      merchant:get_sprite():set_direction(direction4)
    end
  end
  sol.timer.start(map, 100, function() 
    map:repeat_merchant_direction_check()
  end)

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  map:repeat_merchant_direction_check()
  merchant_angry:set_enabled(false)

end

-- Discussion with Merchant
function map:talk_to_merchant() 

    local direction4 = merchant:get_direction4_to(hero)
    merchant:get_sprite():set_direction(direction4)
    --if map.shop_manager_product == nil then
    game:start_dialog("maps.houses.mabe_village.shop_2.merchant_1")
    --end

end

-- NPC events
function merchant:on_interaction()

    map:talk_to_merchant()

end

function merchant_invisible:on_interaction()

    map:talk_to_merchant()

end

function exit_sensor:on_activated()

  if shop_manager.product ~= nil then
    local direction4 = merchant:get_sprite():get_direction()
    if direction4 == 2 or direction4 == 3 then
      link_move = true
      game:start_dialog("maps.houses.mabe_village.shop_2.merchant_2", function()
        local x_initial,y_initial = hero_invisible:get_position()
        local movement = sol.movement.create("straight")
        movement:set_angle(math.pi / 2)
        movement:set_max_distance(16)
        movement:set_speed(45)
        movement:start(hero_invisible)
        hero:set_direction(1)
        function movement:on_position_changed()
          local x,y = hero_invisible:get_position()
          hero:set_position(x, y)
        end
        function movement:on_finished()
          hero_invisible:set_position(x_initial, y_initial)
          link_move = false
        end
      end)
    else
      game:set_value("hero_is_thief", true)
      game:set_value("hero_is_thief_message", true)
      game:set_value("thief_must_die", true)
    end
  end

end
