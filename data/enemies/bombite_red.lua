----------------------------------
--
-- Bombite Red.
--
-- Moves randomly over horizontal and vertical axis.
-- Propelled across the room when attacked and bounce on obstacle, exploding after some time or hitting another enemy.
--
-- Methods : enemy:explode()
--           enemy:start_walking()
--           enemy:start_propelled([angle])
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_propelled = false
local is_explosing = false

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local propelled_speed = 300
local propelled_duration = 2000

-- Behavior on effective shot received.
local function on_attack_received()

  -- Start propelled and a timer before explosion.
  if not is_propelled then
    is_propelled = true
    enemy:start_propelled()
    sol.timer.start(enemy, propelled_duration, function()
      enemy:explode()
    end)
  end
end

-- Make the enemy explode
function enemy:explode()

  if is_explosing then
    return
  end
  is_explosing = true

  local x, y, layer = enemy:get_position()
  local explosion = map:create_custom_entity({
    model = "explosion",
    direction = 0,
    x = x,
    y = y,
    layer = layer,
    width = 16,
    height = 16,
    properties = {
      {key = "strength", value = "4"},
      {key = "hurtable_type_1", value = "hero"},
      {key = "hurtable_type_2", value = "enemy"}
    }
  })
  enemy:stop_all()
  enemy:set_visible(false)

  function explosion:on_finished()
    enemy:start_death()
  end
end

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Start propelled away to the hero and bounce.
function enemy:start_propelled(angle)

  angle = angle or hero:get_angle(enemy)
  local movement = enemy:start_straight_walking(angle, propelled_speed, nil, function()
    enemy:start_propelled(enemy:get_obstacles_bounce_angle(angle))
  end)
  movement:set_smooth(false)
end

-- Explode on collision with another enemy while propelled.
enemy:register_event("on_collision_enemy", function(enemy, other_enemy, other_sprite, my_sprite)

  if is_propelled then
    enemy:explode()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(on_attack_received, {jump_on = "ignored"})

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
end)
