-- Variables
local map = ...
local game = map:get_game()
local merchant_move = false
local link_move = false

-- Include scripts
local shop_manager = require("scripts/maps/shop_manager")
local laser_manager = require("scripts/maps/laser_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)
  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Shop
  if not game:get_value("thief_must_die") then
    shop_manager:init(map)
  end

end

function map:on_opening_transition_finished()
  
  if game:get_value("thief_must_die") then
    map:launch_cinematic_1()
  end
  
end

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    audio_manager:play_music("07_koholint_island")
  else
    if game:get_value("thief_must_die") then
      audio_manager:play_music("boss")
    else
      audio_manager:play_music("14_shop")
    end
  end

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  if not game:get_value("thief_must_die") then
    map:repeat_merchant_direction_check()
    merchant_angry:set_enabled(false)
  else
    merchant:set_enabled(false)
    merchant_invisible:set_enabled(false)
    merchant_angry:get_sprite():set_animation("angry")
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

-- Discussion with Merchant
function map:talk_to_merchant() 

  local direction4 = merchant:get_direction4_to(hero)
  merchant:get_sprite():set_direction(direction4)
  if shop_manager.product == nil then
    game:start_dialog("maps.houses.mabe_village.shop_2.merchant_1")
  end

end

-- NPCs events
function merchant:on_interaction()

  map:talk_to_merchant()

end

function merchant_invisible:on_interaction()

  map:talk_to_merchant()

end

-- Sensors events
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

-- Cinematics
-- This is the cinematic in which the hero retrieves his sword
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {merchant_angry}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    wait(1000)
    hero:set_animation("walking")
    local m1 = sol.movement.create("path")
    m1:set_path{2,2,2,2}
    m1:set_ignore_suspend(true)
    m1:set_speed(80)
    movement(m1, hero)
    hero:set_animation("stopped")
    wait(1000)
    local symbol = hero:create_symbol_exclamation(true)
    wait(1000)
    dialog("maps.houses.mabe_village.shop_2.merchant_5")
    symbol:remove()
    laser_manager:start(map, hero, merchant_angry)
    wait(5000)
    game:set_value("thief_must_die", false)
    game:set_life(0)
    map:set_cinematic_mode(false, options)
    map:init_music()
    
  end)

end
