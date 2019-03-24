----------------------------------
--
-- A carriable entity that can be thrown and bounce like a ball.
--
----------------------------------

local ball = ...
local carriable_behavior = require("entities/lib/carriable")
carriable_behavior.apply(ball, {bounce_sound = "items/shield", respawn_delay = 2000})

-- Behavior when hitting an entity or an obstacle.
ball:register_event("on_hit", function(ball, entity)

  -- If the entity is an enemy other than the bubble, hurt him.
  if entity and entity:get_type() == "enemy" and entity:get_breed() ~= "bubble" then
    entity:hurt(2)
  end
end)