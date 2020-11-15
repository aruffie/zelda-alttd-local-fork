----------------------------------
--
-- Explosion allowing some additional properties.
--
-- Custom properties : damage_on_hero
--                     explosive_type_[1 to 10]
-- Events :            on_finished()
--
----------------------------------

local explosion = ...
local map = explosion:get_map()
local sprite = explosion:create_sprite("entities/explosion")

-- Configuration variables.
local explosed_entities = {}
local damage_on_hero = tonumber(explosion:get_property("damage_on_hero")) or 2
local explosive_types = {}
for i = 1, 10 do
  local type = explosion:get_property("explosive_type_" .. i)
  if not type then
    break
  end
  table.insert(explosive_types, type)
end
if #explosive_types == 0 then
  explosive_types = {"crystal", "destructible", "door", "enemy", "hero", "sensor"}
end

-- Interact with explosive entities..
explosion:add_collision_test("sprite", function(explosion, entity)

  -- Ensure to explode an entity only once by explosion.
  for _, explosed_entity in pairs(explosed_entities) do 
    if entity == explosed_entity then
      return
    end
  end
  table.insert(explosed_entities, entity)

  -- Only try to explode the entity if this explosion can interact with its type.
  local type
  for _, explosive_type in pairs(explosive_types) do
    if entity:get_type() == explosive_type then
      type = explosive_type
      break
    end
  end
  if not type then
    return
  end

  -- Explode the entity if possible.
  if type == "crystal" then
    map:set_crystal_state(not map:get_crystal_state())

  elseif type == "destructible" and entity:get_can_explode() then
    entity:get_sprite():set_animation("destroy", function()
      entity:remove()
    end)

  elseif type == "door" then
    -- TODO No fucking way to know if the door can be opened with an explosion.
    --[[if entity:get_can_explode() then
      entity:open()
    end--]]

  elseif type == "enemy" then
    entity:receive_attack_consequence("explosion", entity:get_attack_consequence("explosion"))

  elseif type == "hero" and not entity:is_invincible() and not entity:is_blinking() then
    entity:start_hurt(explosion, damage_on_hero)

  elseif type == "sensor" then 
    -- TODO Use another collision mode as sensor has no sprite.
    --[[if entity.on_collision_explosion then
      entity:on_collision_explosion()
    end--]]

  else -- Else can interact with any type of entity if the on_explosion() method is registered.
    if entity.on_explosion then
      entity:on_explosion()
    end
  end
end)

-- Explode on created.
explosion:register_event("on_created", function(explosion)

  sprite:set_animation("explosion", function()
    if explosion.on_finished then
      explosion:on_finished()
    end
    explosion:remove()
  end)
end)