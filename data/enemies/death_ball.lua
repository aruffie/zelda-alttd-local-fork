----------------------------------
--
-- Death Ball.
--
-- Attract or expulse le hero depending on the current state, and pause the state action periodically.
--
-- Methods : enemy:start_state([state])
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local state_timer = nil
local is_exhausted = false

-- Configuration variables
local initial_state = enemy:get_property("initial_state")
local attracting_pixel_by_second = enemy:get_property("speed") or 88
local attracting_duration = 5000
local exhausted_duration = 2000

-- Function determining if the attraction should happen or not.
local function is_hero_attractable()

  if hero:get_state() == "falling" or is_exhausted then
    return false
  end
  return true
end

-- Start attracting and the sprite animation for a delay, then stop attracting for delay.
local function start_state_timer()

  is_exhausted = true
  sprite:set_frame_delay(0)
  state_timer = sol.timer.start(enemy, exhausted_duration, function()

    -- Start attracting.
    is_exhausted = false
    sprite:set_frame_delay(100)
    state_timer = sol.timer.start(enemy, attracting_duration, function()
      start_state_timer()
    end)
  end)
end

-- Start an enemy state.
function enemy:start_state(state)

  if state_timer then
    state_timer:stop()
  end

  if state == "attracting" then
    start_state_timer()
    enemy:start_attracting(hero, attracting_pixel_by_second, is_hero_attractable)
  elseif state == "expulsing" then
    start_state_timer()
    enemy:start_attracting(hero, -attracting_pixel_by_second, is_hero_attractable)
  else
    enemy:stop_attracting()
    sprite:set_frame_delay(0)
  end
end

-- Stop attracting when dead.
enemy:register_event("on_dying", function(enemy)
  
  if state_timer then
    state_timer:stop()
  end
  enemy:stop_attracting()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_drawn_in_y_order(false)
end)

enemy:register_event("on_restarted", function(enemy)
    
  enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})
  enemy:set_can_attack(false)
  enemy:set_pushed_back_when_hurt(false)

  -- Default state given by property.
  enemy:start_state(initial_state)
end)
