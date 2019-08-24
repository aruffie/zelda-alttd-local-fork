-- Lua script of enemy zol_red.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local zol_behavior = require("enemies/lib/zol")
require("scripts/multi_events")

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local map = enemy:get_map()
local hero = map:get_hero()

-- Configuration variables
local dying_duration = 300

-- Create two gels when dead.
function enemy:on_dying()

  -- TODO Get the exact list of weapons that kills the zol immediately, and ones that split it into gels.
  local x, y, layer = enemy:get_position()
  local function create_gel(x_offset)
    local gel = map:create_enemy({
      breed = "gel",
      x = x + x_offset,
      y = y,
      layer = layer,
      direction = enemy:get_direction4_to(hero)
    })
  end

  sol.timer.start(map, dying_duration, function()
    if enemy:exists() then
      enemy:remove()
    end
    create_gel(-5)
    create_gel(5)
  end)
end

-- Start walking again when the attack finished.
enemy:register_event("on_jump_finished", function(enemy)
  enemy:restart()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)
  zol_behavior.apply(enemy, {sprite = sprite})
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_attack_consequence("thrown_item", 1)
  enemy:set_attack_consequence("hookshot", 1)
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("arrow", 1)
  enemy:set_attack_consequence("boomerang", 1)
  enemy:set_attack_consequence("explosion", 1)
  enemy:set_hammer_reaction(1)
  enemy:set_fire_reaction(1)

  -- States.
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_damage(2)
  enemy:start_walking()
end)