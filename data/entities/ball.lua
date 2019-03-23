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
----------------------------------

local ball = ...
local carriable_behavior = require("entities/lib/carriable")
carriable_behavior.apply(ball, {bounce_sound = "items/shield", respawn_delay = 2000})

-- Behavior when hitting an entity or an obstacle while the thrown movement is still running.
ball:register_event("on_hit", function(ball, entity)

  -- If the entity is an enemy other than the bubble, hurt him.
  if entity and entity:get_type() == "enemy" and entity:get_breed() ~= "bubble" then
    entity:hurt(2)
  end
end)