-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite = entity:get_sprite()

-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

  local duration = 500 + math.random(1000)
  sol.timer.start(entity, duration, function()
    entity:move_frog()
  end)

end)

function entity:move_frog()

  local direction4 = math.random(3)
  local direction8 = 2 * direction4
  local duration = 500 + math.random(1000)
  local movement = sol.movement.create("jump")
  sprite:set_direction(direction4)
  sprite:set_animation("walking")
  movement:set_speed(50)
  movement:set_direction8(direction8)
  movement:set_distance(16)
  movement:start(entity)
  function movement:on_finished()
    sprite:set_animation("stopped")
    sol.timer.start(entity, duration, function()
      entity:move_frog()
    end)
  end

end
