-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

function map:on_started(destination)

  -- Music
  map:init_music()
  
  snores:set_enabled(false)
  for torch in map:get_entities("light_torch") do
    torch:set_lit(true)
  end

end

-- Link go to bed
function map:go_to_bed() 

  local x, y, layer = placeholder_link_sleep:get_position()
  bed:get_sprite():set_animation("empty_open")
    game:set_hud_enabled(false)
    game:set_pause_allowed(false)
    hero:freeze()
    audio_manager:play_music("36_falling_asleep")
    sol.timer.start(map, 6000, function()
      sol.audio.stop_music()
    end)
    sol.timer.start(map, 500, function()
      hero:set_enabled(false)
      bed:get_sprite():set_animation("hero_goes_to_bed")
      sol.timer.start(map, 500, function()
        local black_surface =  sol.surface.create(320, 256)
        local opacity_black = 0
        black_surface:fill_color({0, 0, 0})
        map:register_event("on_draw", function(map, dst_surface)
          black_surface:set_opacity(opacity_black)
          black_surface:draw(dst_surface)
          opacity_black = opacity_black + 1
          if opacity_black > 255 then
            opacity_black = 255
          end
        end)
        bed:get_sprite():set_animation("hero_sleeping")
        snores:set_enabled(true)
        for torch in map:get_entities("light_torch_1") do
            torch:set_lit(false)
        end
        sol.timer.start(map, 500, function()
          for torch in map:get_entities("light_torch_2") do
              torch:set_lit(false)
          end
          sol.timer.start(map, 500, function()
            for torch in map:get_entities("light_torch_3") do
                torch:set_lit(false)
            end
            sol.timer.start(map, 500, function()
              for torch in map:get_entities("light_torch_4") do
                  torch:set_lit(false)
              end
              local white_surface =  sol.surface.create(320, 256)
              local opacity = 0
              white_surface:fill_color({255, 255, 255})
              map:register_event("on_draw", function(map, dst_surface)
                white_surface:set_opacity(opacity)
                white_surface:draw(dst_surface)
                opacity = opacity + 1
                if opacity > 255 then
                  opacity = 255
                end
              end)
              sol.timer.start(map, 4000, function()
                  hero:teleport("houses/mabe_village/dream_shine_lower_level", "dream_shine_to_upper_1_A", "immediate")
              end)
            end)
          end)
        end)
      end)
    end)
end

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("35_dream_shrine_entrance")

end


function bed_npc:on_interaction()

      map:go_to_bed()

end