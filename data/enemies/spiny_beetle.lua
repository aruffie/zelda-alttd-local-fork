-- Lua script of enemy spiny beetle.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local carried_sprites = {}
local quarter = math.pi * 0.5
local direction = nil

-- Configuration variables
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96

local thickness = 16

-- Start the enemy movement.
function enemy:start_walking()

  for entity, sprite in pairs(carried_sprites) do
    entity:set_layer(enemy:get_layer() + 1) -- Move the layer up to allow the enemy to move even if entity is an obstacle.
    sprite:set_xy(0, -4)
  end
  direction = enemy:get_direction4_to(hero)
  enemy:start_straight_walking(direction * quarter, walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:restart()
  end)
end

-- Start carrying any entity that overlaps the enemy at this moment.
function enemy:start_carrying()

  local x, y, _ = enemy:get_position()
  for entity in map:get_entities_in_region(enemy) do
    if enemy:overlaps(entity) and entity ~= enemy then
      carried_sprites[entity] = entity:get_sprite()
      local entity_x, entity_y, _ = entity:get_position()
      enemy:start_welding(entity, x - entity_x, entity_y - y)

      -- If a liftable is carried, only make enemy vulnerable once removed.
      if entity:get_weight() > 0 then
        is_protected = true
      end
      entity:register_event("on_removed", function(entity)
        is_protected = false
        carried_sprites[entity] = nil
        enemy:restart()
      end)
    end
  end
end

-- Make enemy immobilized and wait for the hero to be close enough.
function enemy:wait()

  for entity, sprite in pairs(carried_sprites) do
    entity:set_layer(enemy:get_layer())
    sprite:set_xy(0, 0)
    if sprite:has_animation("on_ground") then
      sprite:set_animation("on_ground")
    end
  end
  sprite:set_animation("immobilized")

  sol.timer.start(enemy, 100, function()
    if enemy:is_aligned(hero, thickness) and enemy:get_direction4_to(hero) ~= direction then
      enemy:start_walking()
      return false
    end
    return true
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_carrying()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Default behavior for each items.
  if is_protected then
    enemy:set_hero_weapons_reactions("protected")
  else
    enemy:set_hero_weapons_reactions(2, {
      sword = 1
    })
  end

  -- States.
  enemy:set_drawn_in_y_order(false)
  enemy:bring_to_back()
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:wait()
end)
