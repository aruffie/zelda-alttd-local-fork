----------------------------------
--
-- Spiny Beetle.
--
-- Hides below any overlapping entity when created, then move to the hero and keep carry these entities when the he gets too close
--
-- Methods : enemy:start_carrying(entity)
-- Properties : carried_entity_[1 to 10]
--
----------------------------------

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

-- Update protection state depending on current carried objects.
local function update_protection()

  local is_protected = false
  for entity, _ in pairs(carried_sprites) do

    -- Protect if a heavy object is carried.
    if entity:get_weight() > 0 then
      is_protected = true
      break
    end
  end
end

-- Start the enemy movement.
local function start_walking(direction)

  for entity, sprite in pairs(carried_sprites) do
    sprite:set_xy(0, -4)
  end
  last_direction = direction or enemy:get_direction4_to(hero)
  enemy:start_straight_walking(last_direction * quarter, walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()

    -- Continue walking if stopping here would make a carried object overlap the hero or an enemy, else restart.
    for entity in map:get_entities_in_region(enemy) do
      if entity:get_type() == "hero" or entity:get_type() == "enemy" then
        for carried_entity, _ in pairs(carried_sprites) do
          if entity:overlaps(carried_entity:get_bounding_box()) then
            start_walking(math.random(4) - 1)
            return
          end
        end
      end
    end
    enemy:restart()
  end)
end

-- Start carrying any entity that overlaps the enemy at this moment.
local function start_carrying_overlapping_entities()

  local x, y, _ = enemy:get_position()
  for entity in map:get_entities_in_region(enemy) do
    if enemy:overlaps(entity:get_bounding_box()) and entity ~= enemy then
      enemy:start_carrying(entity)
    end
  end
end

-- Make enemy immobilized and wait for the hero to be close enough.
local function wait()

  sprite:set_animation("immobilized")
  for entity, sprite in pairs(carried_sprites) do
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
    start_walking()
  end)
end

-- Start carrying the given entity.
function enemy:start_carrying(entity)

  carried_sprites[entity] = entity:get_sprite()
  local x, y = enemy:get_position()
  local entity_x, entity_y = entity:get_position()
  enemy:start_welding(entity, entity_x - x, entity_y - y)
  enemy:register_event("on_dying", function(enemy)
    if entity:exists() then
      entity:remove()
    end
  end)

  -- Update protection state once carried object removed.
  entity:register_event("on_removed", function(entity)
    carried_sprites[entity] = nil
    update_protection()
  end)
  update_protection()
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  -- Start carrying entites given by custom properties.
  for i = 1, 10 do
    local entity_name = enemy:get_property("carried_entity_" .. i)
    if not entity_name then
      break
    end
    enemy:start_carrying(map:get_entity(entity_name))
  end
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  local reaction = is_protected and "protected" or 1
  enemy:set_hero_weapons_reactions({
  	arrow = reaction,
  	boomerang = reaction,
  	explosion = reaction,
  	sword = reaction,
  	thrown_item = reaction,
  	fire = reaction,
  	jump_on = "ignored",
  	hammer = reaction,
  	hookshot = reaction,
  	magic_powder = reaction,
  	shield = "protected",
  	thrust = reaction
  })

  -- States.
  enemy:set_drawn_in_y_order(false)
  enemy:bring_to_back()
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  wait()
end)
