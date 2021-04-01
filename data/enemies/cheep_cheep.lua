----------------------------------
--
-- Cheep Cheep.
--
-- Swimming enemy for sideview maps.
-- Go to the given target position then go back to the initial place.
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local targets = {}
local current_target = -1
targets[0] = {}
targets[1] = {}

-- Configuration variables.
local target_x = tonumber(enemy:get_property("target_x"))
local target_y = tonumber(enemy:get_property("target_y"))
local swimming_speed = 40
local waiting_duration = 800

-- Start the enemy movement.
local function start_swimming()

  current_target = (current_target + 1) % 2
  sol.timer.start(enemy, waiting_duration, function()

    local movement = sol.movement.create("target")
    movement:set_speed(swimming_speed)
    movement:set_target(targets[current_target].x, targets[current_target].y)
    movement:start(enemy)
    sprite:set_direction(movement:get_direction4())

    function movement:on_obstacle_reached()
      movement:stop()
      start_swimming()
    end

    function movement:on_finished()
      start_swimming()
    end
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  -- Set a default first target if not given.
  local x, y = enemy:get_position()
  if not target_x or not target_y then
    target_x = x + 100
    target_y = y
  end
  
  targets[0].x, targets[0].y = target_x, target_y
  targets[1].x, targets[1].y = x, y
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
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
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  start_swimming()
end)
