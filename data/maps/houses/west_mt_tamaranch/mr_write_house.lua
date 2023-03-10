-- Variables
local map = ...
local game = map:get_game()
local draw_picture = false

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()

end)

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("27_mr_write_house")

end

-- Discussion with mr Write
function map:talk_to_mr_write() 

  local direction4 = mr_write:get_direction4_to(hero)
  local mr_write_sprite = mr_write:get_sprite()
  mr_write_sprite:set_direction(direction4)
  mr_write_sprite:set_animation("stopped")
  if draw_picture == false then
    local item = game:get_item("magnifying_lens")
    local variant = item:get_variant()
    if variant < 9 then
        game:start_dialog("maps.houses.west_mt_tamaranch.mr_write_house.mr_write_1", function()
          mr_write_sprite:set_direction(3)
          mr_write_sprite:set_animation("waiting")
        end)
    elseif variant >= 10 then
       game:start_dialog("maps.houses.west_mt_tamaranch.mr_write_house.mr_write_5", function()
        mr_write_sprite:set_direction(3)
        mr_write_sprite:set_animation("waiting")
       end)
    else
      game:start_dialog("maps.houses.west_mt_tamaranch.mr_write_house.mr_write_2", function()
        hero:freeze()
        game:set_hud_enabled(false)
        game:set_pause_allowed(false)
        draw_picture = true
        local disappear_picture = false
        local opacity = 0
        local peach_sprite = sol.sprite.create("pictures/peach")
        local white_surface =  sol.surface.create(320, 256)
        local black_surface = sol.surface.create(320, 80)
        white_surface:fill_color({255, 255, 255})
        black_surface:fill_color({0, 0, 0})
        function map:on_draw(dst_surface)
          if draw_picture then
            white_surface:set_opacity(opacity)
            peach_sprite:draw(white_surface, 116, 64)
            white_surface:draw(dst_surface)
            black_surface:draw(white_surface, 0, 179)
            if disappear_picture == false then
              opacity = opacity + 2
              if opacity > 255 then
                opacity = 255
              end
            else
              opacity = opacity - 2
              if opacity <= 0 then
                draw_picture = false
                game:start_dialog("maps.houses.west_mt_tamaranch.mr_write_house.mr_write_3", function(answer)
                  if answer == 1 then
                    hero:start_treasure("magnifying_lens", 10, nil, function()
                      game:set_hud_enabled(true)
                      game:set_pause_allowed(true)
                      hero:unfreeze()
                      mr_write_sprite:set_direction(3)
                      mr_write_sprite:set_animation("waiting")
                    end)
                  else
                    map:talk_to_mr_write_2()
                  end
                end)
              end
            end
          end
        end
        sol.timer.start(mr_write, 5000, function()
          disappear_picture = true
        end)
      end)
    end
  end

end

-- Discussion with mr Write 2
function map:talk_to_mr_write_2()
  
  game:start_dialog("maps.houses.west_mt_tamaranch.mr_write_house.mr_write_4", function(answer)
    if answer == 1 then
      hero:start_treasure("magnifying_lens", 10, nil,  function()
        game:set_hud_enabled(true)
        game:set_pause_allowed(true)
        hero:unfreeze()
      end)
    else
      map:talk_to_mr_write_2()
    end
  end)

end

-- NPCs events
function mr_write:on_collision_fire()

  return false

end

function mr_write:on_interaction()

  map:talk_to_mr_write()

end

function mr_write_invisible:on_interaction()

  map:talk_to_mr_write()

end

for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
