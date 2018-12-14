-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

  self:add_collision_test("containing", function(entity, other, entity_sprite, other_sprite)
    if other:get_type() == "pickable" then
      local direction = entity:get_direction()
      local movement = sol.movement.create("straight")
      local angle = direction * math.pi / 2
      movement:set_speed(20)
      movement:set_angle(angle)
      movement:set_max_distance(16)
      movement:set_ignore_obstacles(true)
      movement:start(other)
    end
  end)

end)
