----------------------------------
--
-- A carriable bomb entity that can be thrown and explode after some time.
-- The timer is reseted each time the bomb is carried.
--
----------------------------------

-- Global variables.
local bomb = ...
local carriable_behavior = require("entities/lib/carriable")
carriable_behavior.apply(bomb, {bounce_sound = "items/shield"})

local map = bomb:get_map()
local sprite = bomb:get_sprite()
local exploding_timer, blinking_timer

-- Configuration variables.
local countdown_duration = tonumber(bomb:get_property("countdown_duration")) or 2000
local blinking_duration = 1000

-- Make the bomb explode.
local function explode()

  local x, y, layer = bomb:get_position()
  --[[map:create_custom_entity({
    model = "explosion",
    direction = 0,
    x = x,
    y = y - 5,
    layer = layer,
    width = 16,
    height = 16
  })--]]
  map:create_explosion({ -- TODO Use the above code as soon as possible instead of built-in explosion.
    x=x, 
    y=y-5,
    layer=layer,
  })
  bomb:remove()
end

-- Start the countdown before explosion.
local function start_countdown()

  exploding_timer = sol.timer.start(bomb, countdown_duration, function()
    explode()
  end)
  blinking_timer = sol.timer.start(bomb, math.max(0, countdown_duration - blinking_duration), function()
    blinking_timer = nil
    sprite:set_animation("stopped_explosion_soon")
  end)
end

-- Stop the exploding timer on carrying.
bomb:register_event("on_carrying", function(bomb)

  exploding_timer:stop()
  if blinking_timer then
    blinking_timer:stop()
  end
  sprite:set_animation("stopped")
end)

-- Restart the bomb timer before exploding on thrown.
bomb:register_event("on_thrown", function(bomb, direction)

  start_countdown()
end)

-- Setup traversable rules and start the bomb timer before exploding.
bomb:register_event("on_created", function(bomb)

  bomb:set_traversable_by(true)
  start_countdown()
end)