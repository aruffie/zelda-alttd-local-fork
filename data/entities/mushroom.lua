-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

  entity:add_collision_test("sprite", function(entity, other_entity)
    if other_entity:get_type()== "hero" then
      entity:on_picked()
      entity:remove()
    end
  end)

end)

entity:register_event("on_picked", function()
  
  local hero = map:get_hero()
  hero:start_treasure("mushroom", 1, "mushroom")

end)