-- Outside - West Mt Tarmaranch

-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()


-- Methods - Functions


-- Events

function map:on_started()

 map:set_music()
 map:set_digging_allowed(true)

  --Hibiscus
  -- Father and hibiscus
  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  if game:get_value("main_quest_step") < 18 or variant >= 8  then
    father:set_enabled(false)
    hibiscus:set_enabled(false)
  end
 local father_sprite = father:get_sprite()
 father_sprite:set_animation("calling")
 local hibiscus_sprite = hibiscus:get_sprite()
 hibiscus_sprite:set_animation("magnifying_lens")
 hibiscus_sprite:set_direction(7)

end

function map:set_music()
  
  local x_hero, y_hero = hero:get_position()
  if y_hero < 384 then
    if game:get_player_name():lower() == "marin" then
      sol.audio.play_music("maps/out/mt_tamaranch_marin")
    else
      sol.audio.play_music("maps/out/mt_tamaranch")
    end
  else
      sol.audio.play_music("maps/out/overworld")
  end

end

function map:talk_to_father() 

 local father_sprite = father:get_sprite()
 local item = game:get_item("magnifying_lens")
 local variant = item:get_variant()
 father_sprite:set_animation("sitting")
 if variant == 7 then
   game:start_dialog("maps.out.mambos_cave.father_1", function(answer)
    if answer == 1 then
      game:start_dialog("maps.out.mambos_cave.father_3", function()
        game:set_hud_enabled(false)
        game:set_pause_allowed(false)
        hero:freeze()
        father_sprite:set_animation("eating")
        sol.timer.start(father, 5000, function()
          father_sprite:set_animation("sitting")
          game:start_dialog("maps.out.mambos_cave.father_4", function()
            hibiscus:set_enabled(false)
            hero:start_treasure("magnifying_lens", 8, nil, function()
              father_sprite:set_animation("eating")
              game:set_hud_enabled(true)
              game:set_pause_allowed(true)
              hero:unfreeze()
            end)
          end)
        end)
      end)
    else
      game:start_dialog("maps.out.mambos_cave.father_2", function()
        father_sprite:set_animation("calling")
      end)
    end
   end)
 elseif variant == 8 then
      game:start_dialog("maps.out.mambos_cave.father_5", function()
        father_sprite:set_animation("eating")
      end)
 else
   game:start_dialog("maps.out.mambos_cave.father_6", function(answer)
    game:start_dialog("maps.out.mambos_cave.father_2", function()
      father:set_animation("calling")
    end)
   end)
  end

end

function father:on_interaction()

      map:talk_to_father()

end

function dungeon_4_lock:on_interaction()

      if false and game:get_value("main_quest_step") < 6 then
          game:start_dialog("maps.out.south_mabe_village.dungeon_1_lock")
      elseif true or game:get_value("main_quest_step") == 6 then
        sol.audio.stop_music()
        hero:freeze()
        sol.timer.start(map, 1000, function() 
          map:remove_water(1)
          sol.audio.play_sound("shake")
          local camera = map:get_camera()
          local shake_config = {
              count = 100,
              amplitude = 4,
              speed = 90,
          }
          camera:shake(shake_config, function()
            sol.audio.play_sound("secret_2")
            hero:unfreeze()
            map:set_music()
          end)
          game:set_value("main_quest_step", 7)
        end)
      end

end

function map:remove_water(step)

  if step > 7 then
    return
  end
  sol.timer.start(map, 1000, function()
    for tile in map:get_entities("water_" .. step .. "_") do
      tile:remove()
    end
    step = step +1
    map:remove_water(step)
  end)
  
  

end