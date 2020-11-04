-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()

  -- Make the hero jump to bed and launch the cinematic when facing the bed.
  bed_entrance:add_collision_test("facing", function(bed_entrance, entity)
    if entity:get_type() == "hero" then

      bed_entrance:clear_collision_tests()
      hero:freeze()
      game:get_item("feather"):start_using()

      local movement = sol.movement.create("target")
      movement:set_speed(88)
      movement:set_target(placeholder_link_sleep)
      movement:set_ignore_obstacles(true)
      movement:start(entity)

      function movement:on_finished()
        map:launch_cinematic_1()
      end
    end
  end)
end)

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("35_dream_shrine_entrance")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()

  snores:set_enabled(false)
  for torch in map:get_entities("light_torch") do
    torch:set_lit(true)
  end
  
end

-- Cinematics
-- This is the cinematic that the hero go to sleep.
function map:launch_cinematic_1()
  
  local game = map:get_game()
  local camera = map:get_camera()
  local surface = camera:get_surface()
  local effect_model = require("scripts/gfx_effects/fade_to_white")
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, bed, snores}
    }
    map:set_cinematic_mode(true, options)
    local x, y, layer = placeholder_link_sleep:get_position()
    bed:get_sprite():set_animation("empty_open")
    audio_manager:play_music("36_falling_asleep")
    local timer = sol.timer.start(map, 6000, function()
      sol.audio.stop_music()
    end)
    hero:set_enabled(false)
    bed:get_sprite():set_animation("hero_goes_to_bed")
    timer:set_suspended_with_map(false)
    wait(1250)
    bed:get_sprite():set_animation("hero_sleeping")
    snores:set_enabled(true)
    wait(1000)
    for torch in map:get_entities("light_torch_1") do
      torch:set_lit(false)
    end
    wait(250)
    for torch in map:get_entities("light_torch_2") do
      torch:set_lit(false)
    end
    wait(250)
    for torch in map:get_entities("light_torch_3") do
      torch:set_lit(false)
    end
    wait(250)
    for torch in map:get_entities("light_torch_4") do
      torch:set_lit(false)
    end
    wait(1000)
    wait_for(effect_model.start_effect, surface, game, "in", false)
    game.map_in_transition = effect_model
    wait(2000)
    map:set_cinematic_mode(false, options)
    game:set_suspended(false)
    game:set_hud_enabled(true)
    game:set_pause_allowed(true)
    hero:teleport("houses/mabe_village/dream_shine_lower_level", "dream_shine_to_upper_1_A", "immediate")
  end)

end