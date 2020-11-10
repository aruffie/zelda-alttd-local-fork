----------------------------------
--
-- Gibdo.
--
-- Moves randomly over horizontal and vertical axis.
-- Transform into Red Stalfos on hit by fire.
--
-- Methods : enemy:start_walking()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_firing = false

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local stalfos_shaking_duration = 1000

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- On hit by fire, the gibdo become a red Stalfos.
local function transform_into_stalfos()

  if is_firing then
    return
  end
  is_firing = true

  local x, y, layer = enemy:get_position()
  local stalfos = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_stalfos",
    breed = "stalfos_red"
  })

  -- Make the Stalfos immobile, then shake for some time, and then restart.
  if stalfos and stalfos:exists() then -- If the Stalfos was not immediatly removed from the on_created() event.
    stalfos:set_invincible()
    stalfos:stop_movement()
    stalfos:set_exhausted(true)
    sol.timer.stop_all(stalfos)
    stalfos:set_treasure(enemy:get_treasure())
    stalfos:get_sprite():set_animation("shaking")
    sol.timer.start(stalfos, stalfos_shaking_duration, function()
      stalfos:restart()
    end)
  end

  enemy:set_treasure() -- Treasure will be dropped by the Stalfos.
  enemy:start_death()
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(6)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = 1,
  	boomerang = 2,
  	explosion = 3,
  	sword = 1,
  	thrown_item = 1,
  	fire = transform_into_stalfos,
  	jump_on = "ignored",
  	hammer = 2,
  	hookshot = "immobilized",
  	magic_powder = 1,
  	shield = "protected",
  	thrust = 1
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
end)
