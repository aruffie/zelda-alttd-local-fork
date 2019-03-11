-- Lua script of carriable custom entity.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

----------------------------------
--
-- A carriable entity that can be thrown and bounce like a ball.
--
-- Events : ball:on_bounce(num_bounce), ball:on_finish_throw(), entity:hit_by_carriable(ball)
-- Methods : ball:throw(direction)
----------------------------------

local ball = ...
local carriable_behavior = require("entities/lib/carriable")

local properties = {
  hurt_damage = 2
}

carriable_behavior.apply(ball, properties)