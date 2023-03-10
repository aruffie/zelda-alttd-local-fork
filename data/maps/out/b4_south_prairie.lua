-- Variables
local map = ...
local game = map:get_game()
local marin_song = false
local next_sign = 1
local directions = {
  0, 3, 2, 1, 0, 3, 0, 1, 2, 3, 0, 3, 2
}

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)
  -- Shore
  map:init_shore()
 
end)

-- Initialize the music of the map
function map:init_music()
  
  if game:is_step_last("shield_obtained") then
    audio_manager:play_music("07_koholint_island")
  else
    if marin_song then
      sol.audio.stop_music()
      audio_manager:play_music("42_marin_beach")
    else
      audio_manager:play_music("10_overworld")
    end
  end

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  -- Ground sand
  for ground in map:get_entities('ground_sand') do
    ground:set_visible(false)
  end
  -- Marin
  if not game:is_step_last("started_looking_for_marin") then
    marin:set_enabled(false)
  end
  -- Sensor music
  if not game:is_step_last("started_looking_for_marin") then
    music_sensor:set_enabled(false)
    music_sensor_2:set_enabled(false)
  end
  -- Wart cave
  if game:get_value("wart_cave") == nil then
    for wart_cave in map:get_entities("wart_cave") do
      wart_cave:set_enabled(false)
    end
  end
  
end

-- Initialize shore
function map:init_shore()
  
  sol.timer.start(map, 5000, function()
    local x,y,layer = hero:get_position()
    if y > 500 then
      audio_manager:play_sound("misc/shore")
    end  
    return true
  end)
  
end  

-- Discussion with Marin
function map:talk_to_marin() 

  game:start_dialog("maps.out.south_prairie.marin_1", game:get_player_name(), function(answer)
    if answer == 1 then
      hero:teleport("movies/link_and_marin")
    else
      game:start_dialog("maps.out.south_prairie.marin_2")
      marin:get_sprite():set_direction(3)
    end
  end)

end

-- Doors events
function weak_door_1:on_opened()

  audio_manager:play_sound("misc/secret1")

end

-- NPCs events
function marin:on_interaction()

  map:talk_to_marin()

end

-- Sensors events

function sensor_1:on_activated()
  
  if game:get_value("ghost_quest_step") == "ghost_joined" then
    game:set_value("ghost_quest_step", "ghost_saw_his_house")
  end
  
end



-- Signs and wart
for sign in map:get_entities("sign_frog_") do
  
  sign:register_event("on_interaction", function(npc)
    if sign:get_sprite():get_animation() == "stopped" then  
      if game:get_value("wart_cave") == nil then
        if next_sign > 1 and sign:get_name() == "sign_" .. next_sign or sign:get_name() == "sign_" .. next_sign and next_sign == 1 and game:get_value("wart_cave_start") then
          if next_sign and next_sign < 14 then
            game:start_dialog("maps.out.south_prairie.surprise_" .. directions[next_sign])
          elseif next_sign == 14 then
            audio_manager:play_sound("misc/secret1")
            game:start_dialog("maps.out.south_prairie.surprise_success")
            game:set_value("wart_cave", true)
            for wart_cave in map:get_entities("wart_cave") do
              wart_cave:set_enabled(true)
            end
          end
          next_sign = next_sign + 1
        else
          game:set_value("wart_cave_start", nil)
          game:start_dialog("maps.out.south_prairie.surprise_error")
          audio_manager:play_sound("misc/error")
          next_sign = 1
        end
      else
        game:start_dialog("maps.out.south_prairie.surprise_finished")
      end
    end  
 end)
end

-- Obtaining slim key
function map:on_obtaining_treasure(treasure_item, treasure_variant, treasure_savegame_variable)

  if treasure_savegame_variable == "south_prairie_slim_key" then
    game:set_step_done("dungeon_3_key_obtained")
  end

end

