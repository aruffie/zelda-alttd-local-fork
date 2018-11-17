-- Variables
local map = ...
local game = map:get_game()
local next_sign = 1
local directions = {
  0, 3, 2, 1, 0, 3, 0, 1, 2, 3, 0, 3, 2
}

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Initialize the music of the map
function map:init_music()
  
  if game:get_value("main_quest_step") == 3  then
    audio_manager:play_music("tarin_chased_by_bees")
  else
    if marin_song then
      sol.audio.stop_music()
      audio_manager:play_music("marin_on_beach")
    else
      audio_manager:play_music("10_overworld")
    end
  end

end

-- Map events
function map:on_started()

  map:init_music()
  map:set_digging_allowed(true)
  -- Marin
  if game:get_value("main_quest_step") ~= 21  then
    marin:set_enabled(false)
  end
 
end

function map:on_opening_transition_finished(destination)

  if destination ==  marin_destination then
    marin:set_enabled(false)
  end

end

-- Discussion with Marin
function map:talk_to_marin() 

  game:start_dialog("maps.out.south_prairie.marin_1", game:get_player_name(), function(answer)
    if answer == 1 then
      hero:teleport("movies/link_and_marin")
    else
      game:start_dialog("maps.out.south_prairie.marin_2")
    end
  end)

end

-- Sensor events
function marin_sensor:on_activated()

  local hero = game:get_hero()
  if game:get_value("main_quest_step") == 21 then
    if hero:get_direction() == 1 then
      marin_song = false
      map:init_music()
    else
      marin_song = true
      map:init_music()
    end
  end

end

-- Doors events
function weak_door_1:on_opened()

  sol.audio.play_sound("secret_1")

end

-- NPC events
function marin:on_interaction()

  map:talk_to_marin()

end

-- Signs and wart
for sign in map:get_entities("sign_") do
  function sign:on_interaction()
    if game:get_value("wart_cave") == nil then
      if next_sign > 1 and self:get_name() == "sign_" .. next_sign or self:get_name() == "sign_" .. next_sign and next_sign == 1 and game:get_value("wart_cave_start") then
        if next_sign and next_sign < 14 then
          game:start_dialog("maps.out.south_prairie.surprise_" .. directions[next_sign])
        elseif next_sign == 14 then
          sol.audio.play_sound("secret_1")
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
        sol.audio.play_sound("wrong")
        next_sign = 1
      end
    else
      game:start_dialog("maps.out.south_prairie.surprise_finished")
    end
 end
end

if game:get_value("wart_cave") == nil then
  for wart_cave in map:get_entities("wart_cave") do
    wart_cave:set_enabled(false)
  end
end


