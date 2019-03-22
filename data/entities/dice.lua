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
-- Randomly change the entity direction at each bounce among all available ones.
--
----------------------------------

local dice = ...
local carriable_behavior = require("entities/lib/carriable")
carriable_behavior.apply(dice, {})

-- Behavior on bounce.
dice:register_event("on_bounce", function(dice, num_bounce)

  -- Randomly change the entity direction among all available ones.
  math.randomseed(sol.main.get_elapsed_time())
  dice:set_direction(math.random(0, dice:get_sprite():get_num_directions()-1))
end)