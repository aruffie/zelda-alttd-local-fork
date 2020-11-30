----------------------------------
--
-- A carriable entity that can be thrown and bounce like a ball.
-- Randomly change the entity direction at each bounce among all "stopped" ones.
--
----------------------------------

local dice = ...
local carriable_behavior = require("entities/lib/carriable")
carriable_behavior.apply(dice, {})

local map = dice:get_map()
local sprite = dice:get_sprite()

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

-- Set the stopped animation on bounce and randomly change the direction among all available ones.
dice:register_event("on_bounce", function(dice, num_bounce)

  sprite:set_animation("stopped")
  dice:set_direction(math.random(0, dice:get_sprite():get_num_directions() - 1))
end)

-- Make the hero traversable on thrown to not get stuck.
dice:register_event("on_thrown", function(dice, direction)

  set_hero_not_traversable_safely(dice)
end)

-- Setup traversable rules for the dice.
dice:register_event("on_created", function(dice)

  -- Traversable rules.
  dice:set_traversable_by(false)

  -- Set the hero not traversable as soon as possible, to avoid being stuck if the carriable is (re)created on the hero.
  set_hero_not_traversable_safely(dice)
end)