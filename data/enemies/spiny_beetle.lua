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
local is_protected = false
local last_direction = nil
local waiting_timer = nil

-- Configuration variables
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96

local thickness = 16

-- Start the enemy movement.
function enemy:start_walking(direction)

  for entity, sprite in pairs(carried_sprites) do
    entity:set_layer(enemy:get_layer() + 1) -- Workaround: Move the layer up to allow the enemy to move even if entity is an obstacle.
    sprite:set_xy(0, -4)
  end
  last_direction = direction or enemy:get_direction4_to(hero)
  enemy:start_straight_walking(last_direction * quarter, walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()

    -- Continue walking if stopping here would make a carried object overlap the hero or an enemy, else restart.
    for entity in map:get_entities_in_region(enemy) do
      if entity:get_type() == "hero" or entity:get_type() == "enemy" then
        for carried_entity, _ in pairs(carried_sprites) do
          if entity:overlaps(carried_entity:get_bounding_box()) then
            enemy:start_walking(math.random(4) - 1)
            return
          end
        end
      end
    end
    enemy:restart()
  end)
end

-- Update protection state depending on current carried objects.
function enemy:update_protection()

  local is_protected = false
  for entity, _ in pairs(carried_sprites) do

    -- Protect if a heavy object is carried.
    if entity:get_weight() > 0 then
      is_protected = true
      break
    end
  end
end

-- Start carrying any entity that overlaps the enemy at this moment.
function enemy:start_carrying()

  local x, y, _ = enemy:get_position()
  for entity in map:get_entities_in_region(enemy) do
    if enemy:overlaps(entity:get_bounding_box()) and entity ~= enemy then
      carried_sprites[entity] = entity:get_sprite()
      local entity_x, entity_y, _ = entity:get_position()
      enemy:start_welding(entity, entity_x - x, entity_y - y)

      -- Update protection state once carried object removed.
      entity:register_event("on_removed", function(entity)
        carried_sprites[entity] = nil
        enemy:update_protection()
      end)
    end
  end
  enemy:update_protection()
end

-- Make enemy immobilized and wait for the hero to be close enough.
function enemy:wait()

  sprite:set_animation("immobilized")
  for entity, sprite in pairs(carried_sprites) do
    entity:set_layer(enemy:get_layer())
    sprite:set_xy(0, 0)
    if sprite:has_animation("on_ground") then
      sprite:set_animation("on_ground")
    end
  end

  if waiting_timer then
    waiting_timer:stop()
  end
  waiting_timer = sol.timer.start(enemy, 100, function()
    if not enemy:is_aligned(hero, thickness) or enemy:get_direction4_to(hero) == last_direction then
      return true
    end
    enemy:start_walking()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_carrying()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Default behavior for each items.
  enemy:set_hero_weapons_reactions(is_protected and "protected" or 1)

  -- States.
  enemy:set_drawn_in_y_order(false)
  enemy:bring_to_back()
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:wait()
end)
