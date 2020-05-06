----------------------------------
--
-- Gohma.
--
-- Moves horizontally and change direction on wall reached.
-- Randomly throw a beam, then shake and charge the hero before start walking again.
-- Open his eye and become vulnerable just before throwing the beam.
-- Blue skin applied if another gohma enemy already exists on the map when created.
--
-- Methods : enemy:start_walking([direction2])
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local body_sprite, eye_sprite
local quarter = math.pi * 0.5

-- Configuration variables
local walking_speed = 88
local eye_closed_minimum_duration = 2000
local eye_closed_maximum_duration = 2000
local attack_triggering_distance = 80

-- Start the enemy movement.
function enemy:start_walking(direction2)

  direction2 = direction2 or 0

  -- Start walking and change direction on stopped.
  local movement = enemy:start_straight_walking(direction2 * math.pi, walking_speed, nil, function()
    enemy:start_walking((direction2 + 1) % 2)
  end)
  movement:set_smooth(false)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(6)
  enemy:set_size(40, 32)
  enemy:set_origin(20, 29)

  -- Create the first gohma with the classic red skin and others with the blue one.
  local body_sprite_name = "enemies/" .. enemy:get_breed()
  local eye_sprite_name = "enemies/" .. enemy:get_breed() .. "/eye"
  for map_enemy in map:get_entities_by_type("enemy") do
    if map_enemy ~= enemy and map_enemy:get_breed() == enemy:get_breed() then
      body_sprite_name = "enemies/" .. enemy:get_breed() .. "/blue"
      eye_sprite_name = "enemies/" .. enemy:get_breed() .. "/blue_eye"
      break
    end
  end
  body_sprite = enemy:create_sprite(body_sprite_name)
  eye_sprite = enemy:create_sprite(body_sprite_name)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("ignored", {
    bow = 2,
    hookshot = 1
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
end)
