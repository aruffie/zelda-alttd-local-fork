----------------------------------
--
-- A carriable entity that can be thrown and bounce like a ball.
--
----------------------------------

local ball = ...
local carriable_behavior = require("entities/lib/carriable")
carriable_behavior.apply(ball, {bounce_sound = "items/shield", respawn_delay = 2000})

local map = ball:get_map()

-- Function to make the carriable not traversable by the hero and vice versa. 
-- Delay this moment if the hero would get stuck.
local function set_hero_not_traversable_safely(entity)

  entity:set_traversable_by("hero", true)
  entity:set_can_traverse("hero", true)
  if not entity:overlaps(map:get_hero()) then
    entity:set_traversable_by("hero", false)
    entity:set_can_traverse("hero", false)
    return
  end
  sol.timer.start(entity, 10, function() -- Retry later.
    set_hero_not_traversable_safely(entity)
  end)
end

-- Make the hero traversable on thrown to not get stuck.
ball:register_event("on_thrown", function(ball, direction)

  set_hero_not_traversable_safely(ball)
end)

-- Setup traversable rules for the ball.
ball:register_event("on_created", function(ball)

  -- Traversable rules.
  ball:set_traversable_by(false)
  ball:set_can_traverse_ground("deep_water", true)
  ball:set_can_traverse_ground("grass", true)
  ball:set_can_traverse_ground("hole", true)
  ball:set_can_traverse_ground("lava", true)
  ball:set_can_traverse_ground("low_wall", true)
  ball:set_can_traverse_ground("prickles", true)
  ball:set_can_traverse_ground("shallow_water", true)
  ball:set_can_traverse(true) -- No way to get traversable entities later, make them all traversable.

  -- Set the hero not traversable as soon as possible, to avoid being stuck if the carriable is (re)created on the hero.
  set_hero_not_traversable_safely(ball)
end)