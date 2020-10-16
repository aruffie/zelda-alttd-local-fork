----------------------------------
--
-- Helmasaur.
--
-- Moves randomly over horizontal and vertical axis, and is invulnerable to front attacks.
-- Can be defeated by attacking him in the back, or take off his mask with the hookshot to set him weak from everywhere.
--
-- Methods : enemy:start_walking()
--           enemy:set_weak()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("enemies/lib/weapons").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_protected = true

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 32
local weak_walking_speed = 48
local weak_walking_minimum_distance = 16
local weak_walking_maximum_distance = 96
local front_angle = 7.0 * math.pi / 6.0

local speed = walking_speed
local minimum_distance = walking_minimum_distance
local maximum_distance = walking_maximum_distance

-- Hurt if the hero is in the back of the enemy.
local function on_sword_attack_received()

  enemy:set_invincible() -- Make sure to only trigger this event once by attack.

  if not is_protected or not enemy:is_entity_in_front(hero, front_angle) then
    enemy:hurt(1)
  else
    enemy:start_shock(hero, 100, 150, function()
      enemy:restart()
    end)
  end
end

-- Hurt if the hero is in the back of the enemy, else hurt the hero.
local function on_thrust_attack_received()

  if not is_protected or not enemy:is_entity_in_front(hero, front_angle) then
    enemy:set_invincible() -- Make sure to only trigger this event once by attack.
    enemy:hurt(1)
  else
    enemy:start_pushing_back(hero, 100, 150)
    hero:start_hurt(enemy:get_damage())
  end
end

-- Hurt if enemy and hero have same direction, else grab the mask and make enemy weak.
local function on_hookshot_attack_received()

  -- Make sure to only trigger this event once by attack.
  enemy:set_invincible()

  if not is_protected or not enemy:is_entity_in_front(hero, front_angle) then
    enemy:hurt(2)
  else
    
    -- Remove the mask from the enemy and attach it to the hookshot.
    local x, y, layer = enemy:get_position()
    local mask = map:create_custom_entity({
      sprite = "enemies/" .. enemy:get_breed() .. "/mask",
      x = x,
      y = y,
      layer = layer,
      width = 16,
      height = 16,
      direction = sprite:get_direction()
    })
    game:get_item("hookshot"):catch_entity(mask)
    mask:add_collision_test("overlapping", function(hookshot, entity)
      if entity:get_type() == "hero" then
        mask:remove()
      end
    end)
    
    enemy:set_weak()
  end
end

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], speed, math.random(minimum_distance, maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Make the enemy faster and maskless.
function enemy:set_weak()

  is_protected = false

  speed = weak_walking_speed
  minimum_distance = weak_walking_minimum_distance
  maximum_distance = weak_walking_maximum_distance

  enemy:remove_sprite(sprite)
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/maskless")
  enemy:start_brief_effect("entities/effects/sparkle_small", "default", 0, 0)
  enemy:restart()
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- TODO Check if mask collision test is needed for distance weapons.
  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    hookshot = on_hookshot_attack_received,
    sword = on_sword_attack_received,
    thrust = on_thrust_attack_received,
    jump_on = "ignored"
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:start_walking()
end)
