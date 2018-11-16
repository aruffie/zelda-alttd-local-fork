-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  map:init_music()
  map:init_map_entities()
  -- Hero
  if destination:get_name() == "start_position"  then
    hero:set_enabled(false)
    bed:get_sprite():set_animation("hero_sleeping")
  else
    snores:remove()
  end
  -- Letter
  if game:get_value("main_quest_step") ~= 21  then
    letter:set_enabled(false)
  end

end

function map:on_opening_transition_finished(destination)

  -- Start position
  if destination:get_name() == "start_position"  then
    map:launch_cinematic_1()
  else
    if bed ~= nil then
      bed:set_layer(0)
    end
  end

end

map:register_event("on_finished", function()

  if game:has_item("shield") == true and game:get_value("main_quest_step") == 2 then
   -- Sword quest
    game:set_value("main_quest_step", 3)
  end

end)

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") < 3  then
    audio_manager:play_music("06_marin_house")
  elseif game:get_value("main_quest_step") == 3  then
    audio_manager:play_music("07_koholint_island")
  else
    audio_manager:play_music("12_house")
  end

end

-- Initializes entities based on player's progress
function map:init_map_entities()
 
   local item = game:get_item("magnifying_lens")
   local variant = item:get_variant()
   -- Marin
   if game:get_value("main_quest_step") > 3  then
     marin:remove()
   else
     marin:get_sprite():set_animation("waiting")
     map:repeat_marin_direction_check()
   end
   -- Others entities
   if game:get_value("main_quest_step") > 10 and variant < 4 then
    snores_tarin:remove()
    bed_tarin:remove()
    tarin:get_sprite():set_animation("waiting")
    tarin:get_sprite():set_direction(3)
   elseif game:get_value("main_quest_step") > 10  then
    snores_tarin:remove()
    bed_tarin:remove()
    bed:remove()
    tarin:remove()
    bananas:remove()
   elseif game:get_value("main_quest_step") > 4 then
    local x,y,layer = placeholder_tarin_sleep:get_position()
    tarin:set_position(x,y,layer)
    tarin:get_sprite():set_animation("sleeping")
    bed:remove()
    bananas:remove()
  elseif game:get_value("main_quest_step") > 3  then
    snores_tarin:remove()
    bed_tarin:remove()
    bed:remove()
    tarin:remove()
    bananas:remove()
  else
    snores_tarin:remove()
    bed_tarin:remove()
    tarin:get_sprite():set_animation("waiting")
    map:repeat_tarin_direction_check()
    bananas:remove()
  end

end

-- Function that forces Marin to always watch the hero
function map:repeat_marin_direction_check()

  local direction4 = marin:get_direction4_to(hero)
  marin:get_sprite():set_direction(direction4)
  sol.timer.start(map, 100, function() 
    map:repeat_marin_direction_check()
  end)

end

-- Function that forces Tarin to always watch the hero
function map:repeat_tarin_direction_check()

  local direction4 = tarin:get_direction4_to(hero)
  tarin:get_sprite():set_direction(direction4)
  sol.timer.start(map, 100, function() 
    map:repeat_tarin_direction_check()
  end)

end

-- Discussion with Tarin
function  map:talk_to_tarin() 

   if game:get_value("main_quest_step") > 10 then
    game:start_dialog("maps.houses.mabe_village.marin_house.tarin_5")
   elseif game:get_value("main_quest_step") > 4 then
    game:start_dialog("maps.houses.mabe_village.marin_house.tarin_4")
   else
      if game:has_item("shield") == false then
        local item = game:get_item("shield")
        game:start_dialog("maps.houses.mabe_village.marin_house.tarin_1", game:get_player_name(), function()
          hero:start_treasure("shield", 1, "schield")
          game:set_item_assigned(1, item)
          game:set_value("main_quest_step", 2)
        end)
      else
          game:start_dialog("maps.houses.mabe_village.marin_house.tarin_2", game:get_player_name())
      end
  end

end

-- Discussion with Marin
function map:talk_to_marin() 

  game:start_dialog("maps.houses.mabe_village.marin_house.marin_1")

end

-- Sensor events
function exit_sensor:on_activated()

  if game:has_item("shield") == false then
    game:start_dialog("maps.houses.mabe_village.marin_house.tarin_3", function()
     hero:set_direction(2)
     hero:walk("2222")
   end)
  end

end

-- NPC events
function tarin:on_interaction()

  map:talk_to_tarin()

end

function tarin_npc:on_interaction()

  map:talk_to_tarin()

end

function marin:on_interaction()

  map:talk_to_marin()

end

-- Cinematics
-- This is the cinematic that the hero wakes up and gets up from his bed.
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, marin, tarin, snores}
    }
    map:set_cinematic_mode(true, options)
    wait(3000)
    snores:remove()
    bed:get_sprite():set_animation("hero_waking")
    wait(1000)
    dialog("maps.houses.mabe_village.marin_house.marin_2")
    wait(500)

    hero:set_enabled(true)
    sol.audio.play_sound("hero_lands")
    bed:get_sprite():set_animation("empty_open")
    bed:set_layer(0)
    hero:set_animation("jumping")
    -- Movement that brings the hero out of bed.
    local movement_jump = sol.movement.create("jump")
    movement_jump:set_direction8(7)
    movement_jump:set_distance(24)
    movement_jump:set_ignore_obstacles(true)
    movement_jump:set_ignore_suspend(true)
    movement(movement_jump, hero)
    map:set_cinematic_mode(false, options)
    game:set_starting_location("houses/mabe_village/marin_house", "marin_house_1_B")
    game:set_value("main_quest_step", 1)
  end)

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end