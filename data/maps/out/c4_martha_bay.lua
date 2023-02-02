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
  -- Digging
  map:set_digging_allowed(true)

end)

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("10_overworld")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  -- Dungeon 5
  if game:is_step_done("ghost_returned_to_tomb") then
    dungeon_5_door:set_enabled(false)
  end
  -- Mermaid statue pushed
  if game:get_value("mermaid_statue_pushed") then
    map:open_mermaid_statue()
  end
  
end

-- Mermaid statue opening
function map:open_mermaid_statue()

  mermaid_statue_npc:set_enabled(false)
  mermaid_statue_1:set_position(448,424)
  mermaid_statue_2:set_position(448,408)


end

-- Discussion with Mermaid
function map:talk_to_mermaid() 

  game:start_dialog("maps.out.martha_bay.mermaid_1")

end

-- NPCs events
function mermaid:on_interaction()

  map:talk_to_mermaid()

end

function mermaid_statue_npc:on_interaction()

  if game:get_item("magnifying_lens"):get_variant() == 13 then
    audio_manager:play_sound("chest_open")
    game:start_dialog("maps.out.martha_bay.mermaid_statue_scale",function()
      map:launch_cinematic_1()
    end)
  else 
    game:start_dialog("maps.out.martha_bay.mermaid_statue_no_scale")
  end

end

-- Underwater teleporters.
local function underwater_teleport(map, destination)

  -- Teleport only if the hero is diving.
  local custom_state = hero:get_state_object()
  if custom_state and custom_state:get_description() == "diving" then
    hero:teleport(map, destination, "fade")
  end

end

function sideview_1_1_A:on_activated_repeat() -- Use the on_activated_repeat() event to take care of state changing to swimming while not moving.

  underwater_teleport("sideviews/martha_bay/sideview_1", "sideview_1_1_B")

end

function sideview_2_1_A:on_activated_repeat()

  underwater_teleport("sideviews/martha_bay/sideview_2", "sideview_2_1_B")

end

function sideview_2_2_A:on_activated_repeat()

  underwater_teleport("sideviews/martha_bay/sideview_2", "sideview_2_2_B")

end


-- Cinematics
-- This is the cinematic that mermaid statue must be opened
function map:launch_cinematic_1(destination)
  
  local hero = map:get_hero()
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, mermaid_statue_1, mermaid_statue_2}
    }
    map:set_cinematic_mode(true, options)
    audio_manager:play_sound("misc/chest_open")
    wait(2000)
    local timer_sound = sol.timer.start(hero, 0, function()
      audio_manager:play_sound("misc/dungeon_shake")
      return 450
    end)
    timer_sound:set_suspended_with_map(false)
    local shake_config = {
        count = 72,
        amplitude = 2,
        speed = 90
    }
    local camera = map:get_camera()
    camera:shake(shake_config)
    local movement1 = sol.movement.create("straight")
    movement1:set_angle(math.pi)
    movement1:set_max_distance(32)
    movement1:set_speed(16)
    movement1:set_ignore_suspend(true)
    movement1:set_ignore_obstacles(true)
    function movement1:on_position_changed(x, y, layer)
       local mermaid_statue_1_x,mermaid_statue_1_y = mermaid_statue_1:get_position()
       local mermaid_statue_2_x,mermaid_statue_2_y = mermaid_statue_2:get_position()
       mermaid_statue_2:set_position(mermaid_statue_1_x, mermaid_statue_2_y)
    end
  
    movement(movement1, mermaid_statue_1)
    timer_sound:stop()
    wait(2000)
    audio_manager:play_sound("misc/secret1")
    game:set_value("mermaid_statue_pushed",true)
    map:open_mermaid_statue()
    map:set_cinematic_mode(false)
  end)

end