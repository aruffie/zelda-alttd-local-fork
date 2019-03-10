-- Lua script of custom entity dice.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

----------------------------------
--
-- A carriable entity that can be thrown and bounce like a ball.
-- Randomly change the direction of the current sprite animation at each bounce.
--
----------------------------------
local dice = ...
local carriable_behavior = require("entities/lib/carriable")

local properties = {

  vshift = 0, -- Vertical shift to draw the sprite while lifting/carrying.
  num_bounces = 3, -- Number of bounces when falling (it can be 0).
  bounce_distances = {80, 16, 4}, -- Distances for each bounce.
  bounce_heights = {"same", 4, 2}, -- Heights for each bounce.
  bounce_durations = {400, 160, 70}, -- Duration for each bounce.
  bounce_sound = "bomb", -- Default id of the bouncing sound.
  shadow_type = "normal", -- Type of shadow for the falling trajectory.
  hurt_damage = 2,  -- Damage to enemies.
}

dice:register_event("on_bounce", function(dice, num_bounce)

  math.randomseed(sol.main.get_elapsed_time())
  dice:set_direction(math.random(0, dice:get_sprite():get_num_directions()-1))
end)

carriable_behavior.apply(dice, properties)