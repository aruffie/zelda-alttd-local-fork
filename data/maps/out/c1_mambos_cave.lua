-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

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

 --Jumping if coming from the Bird key cave
  if destination == cave_c1_bird_cave_key_hole then
    hero:start_jumping(6,48,true)
  end

end)

-- Initialize the music of the map
function map:init_music()
  
  local x_hero, y_hero = hero:get_position()
  if y_hero < 384 then
    audio_manager:play_music("46_tal_tal_mountain_range")
  else
    audio_manager:play_music("10_overworld")
  end

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  -- Father and hibiscus
  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  if game:get_value("main_quest_step") < 18 or variant >= 8  then
    father:set_enabled(false)
    hibiscus:set_enabled(false)
  end
  father:get_sprite():set_animation("calling")
  hibiscus:get_sprite():set_animation("magnifying_lens")
  hibiscus:get_sprite():set_direction(7)
  
end

-- Discussion with Father 1
function map:talk_to_father() 

 local item = game:get_item("magnifying_lens")
 local variant = item:get_variant()
 father:get_sprite():set_animation("sitting")
 if variant == 7 then
   game:start_dialog("maps.out.mambos_cave.father_1", function(answer)
    if answer == 1 then
      game:start_dialog("maps.out.mambos_cave.father_3", function()
        map:launch_cinematic_1()
      end)
    else
      game:start_dialog("maps.out.mambos_cave.father_2", function()
        father:get_sprite():set_animation("calling")
      end)
    end
   end)
 elseif variant == 8 then
    game:start_dialog("maps.out.mambos_cave.father_5", function()
      father:get_sprite():set_animation("eating")
    end)
 else
   game:start_dialog("maps.out.mambos_cave.father_6", function(answer)
    game:start_dialog("maps.out.mambos_cave.father_2", function()
      father:get_sprite():set_animation("calling")
    end)
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

-- NPCs events
function father:on_interaction()

  map:talk_to_father()

end

-- NPCs events
function dungeon_4_lock:on_interaction()

  if not game:is_step_done("dungeon_4_key_obtained") then
    game:start_dialog("maps.out.mambos_cave.dungeon_4_lock")
  elseif game:is_step_last("dungeon_4_key_obtained") then
    -- Todo launch cinematic
  end
  
end

-- Cinematics
-- This is the cinematic in which Father quadruplet eat pineapple
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, father}
    }
    map:set_cinematic_mode(true, options)
    father:get_sprite():set_animation("eating")
    wait(5000)
    father:get_sprite():set_animation("sitting")
    dialog("maps.out.mambos_cave.father_4")
    hibiscus:set_enabled(false)
    wait_for(hero.start_treasure, hero, "magnifying_lens", 8, "magnifying_lens_8")
    father:get_sprite():set_animation("eating")
    map:set_cinematic_mode(false, options)
  end)

end