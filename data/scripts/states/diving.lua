-- Custom diving script.

-- Variables
local hero_meta = sol.main.get_metatable("hero")
local map_meta = sol.main.get_metatable("map")
local game_meta = sol.main.get_metatable("game")
-- Sounds:
local dinving_sound = "diving"

-- Parameters:
local is_hero_diving
local diving_state -- Values: nil, "stopped", "moving".

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")


function hero_meta:is_diving()
  
  return is_hero_diving
  
end

function hero_meta:set_diving(diving)
  
  is_hero_diving = diving
  
end

-- Restart variables.
game_meta:register_event("on_started", function(game)
    
  is_hero_diving = false
  
end)

-- Initialize diving state.
local state = sol.state.create()
state:set_description("diving")
state:set_can_control_movement(false)
state:set_can_control_direction(false)

function state:on_started(previous_state_name, previous_state)
  
  local psn = previous_state_name
  local hero = state:get_game():get_hero()
  local hero_sprite = hero:get_sprite()
  local sword_sprite = hero:get_sprite("sword")
  -- Change tunic animations during the diving state.
  hero_sprite:set_animation("sword_loading_walking") -- TODO
  
end

function state:on_finished(next_state_name, next_state)
  
  local hero = state:get_game():get_hero()
  diving_state = nil

end