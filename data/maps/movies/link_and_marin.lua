-- Lua script of map final_scene.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

-- Variables
local map = ...
local game = map:get_game()
local player_name = game:get_player_name()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local language_manager = require("scripts/language_manager")

-- Sunset effect
--local sunset_effect = require("scripts/maps/sunset_effect")
-- Cinematic black lines
local black_stripe = nil
-- Final fade sprite
local fade_sprite = nil
local fade_x = 0
local fade_y = 0
local black_surface = nil
local end_text = nil

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()

  -- Camera
   local camera = map:get_camera()
   camera:start_manual()
   camera:set_position(0,0)

  -- Hide or show HUD.
  game:set_hud_enabled(false)

  -- Prevent or allow the player from pausing the game
  game:set_pause_allowed(false)

  
  local dialog_box = game:get_dialog_box()
  dialog_box:set_position("top")

  -- Let the sprite animation running.
  marin:get_sprite():set_ignore_suspend(true)
  hero:get_sprite():set_ignore_suspend(true)
  seagull_1:get_sprite():set_ignore_suspend(true)
  seagull_2:get_sprite():set_ignore_suspend(true)
  seagull_3:get_sprite():set_ignore_suspend(true)
  -- Let the swell animation running.
  for i = 1, 10 do
    local swell_name = "swell_" .. i
    local swell_entity = map:get_entity(swell_name)
    if swell_entity ~= nil then
        swell_entity:get_sprite():set_ignore_suspend(true)
    end
  end
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

  -- Freeze hero.
  local hero = map:get_hero()
  hero:set_visible(true)
  hero:freeze()

  -- Launch cinematic.
  map:start_cinematic()
end

-- Draw sunset then black stripes.
function map:on_draw(dst_surface)

  -- Fade.
  if fade_sprite ~= nil then
    fade_sprite:draw(dst_surface, fade_x, fade_y)
  end

  -- Full black.
  if black_surface then
    black_surface:draw(dst_surface)
  end

  -- End text.
  if end_text then
    local quest_w, quest_h = sol.video.get_quest_size()
    end_text:draw(dst_surface, quest_w / 2, quest_h / 2)
  end
end

-- Final cinematic.
function map:start_cinematic()

   local camera = map:get_camera()
   local movement = sol.movement.create("straight")
   movement:set_speed(20)
   movement:set_angle(3 * math.pi / 2)
   movement:set_max_distance(256)
   movement:set_ignore_obstacles(true)
   movement:start(camera, function()
    map:start_dialog()
   end)
  sol.timer.start(seagull_1, 200, function()
     audio_manager:play_sound("misc/seagull")
     seagull_1:get_sprite():set_animation("walking")
     local movement_seagull_1 = sol.movement.create("target")
     movement_seagull_1:set_speed(100)
     movement_seagull_1:set_ignore_obstacles(true)
     movement_seagull_1:set_target(seagull_1_destination)
     movement_seagull_1:start(seagull_1)
  end)
  sol.timer.start(seagull_2, 1000, function()
     audio_manager:play_sound("misc/seagull")
     seagull_2:get_sprite():set_animation("walking")
     local movement_seagull_2 = sol.movement.create("target")
     movement_seagull_2:set_speed(100)
     movement_seagull_2:set_ignore_obstacles(true)
     movement_seagull_2:set_target(seagull_2_destination)
     movement_seagull_2:start(seagull_2)
  end)

  sol.timer.start(seagull_3, 8000, function()
     audio_manager:play_sound("misc/seagull")
     seagull_3:get_sprite():set_animation("walking")
     local movement_seagull_3 = sol.movement.create("target")
     movement_seagull_3:set_speed(100)
     movement_seagull_3:set_ignore_obstacles(true)
     movement_seagull_3:set_target(seagull_3_destination)
     movement_seagull_3:start(seagull_3)
  end)


end


function map:start_dialog()

  game:start_dialog("movies.link_and_marin.marin_1", function()
    sol.timer.start(marin, 1000, function()
      game:start_dialog("movies.link_and_marin.marin_2", function()
        sol.timer.start(marin, 1000, function()
          game:start_dialog("movies.link_and_marin.marin_3", function(answer)
            if answer == 1 then
              game:start_dialog("movies.link_and_marin.marin_4", function()
                game:start_dialog("movies.link_and_marin.marin_5", function()
                  game:set_step_done("marin_joined")
                  game:set_hud_enabled(true)
                  game:set_pause_allowed(true)
                  hero:teleport("out/b4_south_prairie", "marin_destination")
                end)
              end)
            else
              game:start_dialog("movies.link_and_marin.marin_6", function()
                map:start_dialog()
              end)
            end
          end)
        end)
      end)
    end)
  end)

end
