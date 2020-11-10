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
local is_active = true

-- Configuration variables
local initial_state = enemy:get_property("initial_state")
local attracting_pixel_by_second = enemy:get_property("speed") or 88
local active_duration = enemy:get_property("active_duration") or 4000
local inactive_duration = enemy:get_property("inactive_duration") or 1000

-- Callback function allowing the attraction or not.
local function is_hero_attractable()

  -- Don't attract if the enemy is not active, if the hero is falling or overlaps a separator.
  if not is_active or hero:get_state() == "falling" then
    return false
  end
  for separator in map:get_entities_by_type("separator") do
    if separator:overlaps(hero) then
      return false
    end
  end

  return true
end

-- Start attracting and the sprite animation for a delay, then stop attracting for delay.
local function start_state_timer()

  is_active = false
  sprite:set_frame_delay(0)
  state_timer = sol.timer.start(enemy, inactive_duration, function()

    -- Start attracting.
    is_active = true
    sprite:set_frame_delay(100)
    state_timer = sol.timer.start(enemy, active_duration, function()
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
    
  enemy:set_hero_weapons_reactions({
  	arrow = 1,
  	boomerang = 1,
  	explosion = 1,
  	sword = 1,
  	thrown_item = 1,
  	fire = 1,
  	jump_on = "ignored",
  	hammer = 1,
  	hookshot = 1,
  	magic_powder = 1,
  	shield = "protected",
  	thrust = 1
  })

  -- States.
  enemy:set_can_attack(false)
  enemy:set_pushed_back_when_hurt(false)
  enemy:start_state(initial_state)
end)
