----------------------------------
--
-- Bombite Red.
--
-- Moves randomly over horizontal and vertical axis.
-- Propelled across the room when attacked and bounce on obstacle, exploding after some time or hitting another enemy.
--
-- Methods : enemy:start_propelled([angle])
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
local circle = math.pi * 2.0
local propelled_angle
local is_propelled = false
local is_explosing = false
local is_hero_pushed = false

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local propelled_speed = 300
local propelled_duration = 2000

-- Make the enemy explode
local function explode()

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
local function start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    start_walking()
  end)
end

-- Make the enemy bounce on the shield.
local function bounce_on_shield()

  if is_hero_pushed then
    return
  end
  is_hero_pushed = true

  local normal_angle = hero:get_direction() * quarter
  if math.cos(math.abs(normal_angle - propelled_angle)) <= 0 then -- Don't bounce if the enemy is walking away the hero.
    enemy:start_propelled((2.0 * normal_angle - propelled_angle + math.pi) % circle)
  end
  enemy:start_pushing_back(hero, 150, 100, sprite, nil, function()
    is_hero_pushed = false
  end)
end

-- Start propelling on effective attack received.
local function on_attack_received()

  if not is_propelled then
    enemy:start_propelled()
  end
end

-- Start propelled away to the hero and bounce against obstacles, .
function enemy:start_propelled(angle)

  -- Start a timer before explosion the first time the enemy is propelled.
  if not is_propelled then
    is_propelled = true
    sol.timer.start(enemy, propelled_duration, function()
      explode()
    end)
  end

  -- Start the movement.
  propelled_angle = angle or hero:get_angle(enemy)
  local movement = enemy:start_straight_walking(propelled_angle, propelled_speed, nil, function()
    enemy:start_propelled(enemy:get_obstacles_bounce_angle(propelled_angle))
  end)
  movement:set_smooth(false)

  enemy:set_hero_weapons_reactions({shield = bounce_on_shield}) -- Bounce on shield attack once propelled.
end

-- Explode on collision with another enemy while propelled.
enemy:register_event("on_collision_enemy", function(enemy, other_enemy, other_sprite, sprite)

  if is_propelled and enemy:get_can_attack() and other_enemy:get_can_attack() then -- If both enemies are able to attack.
    if other_enemy:get_breed() == enemy:get_breed() then
      other_enemy:start_propelled(enemy:get_angle(other_enemy))
    end
    explode()
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

  enemy:set_hero_weapons_reactions({
  	arrow = "protected",
  	boomerang = "immobilized",
  	explosion = on_attack_received,
  	sword = on_attack_received,
  	thrown_item = "protected",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = "immobilized",
  	magic_powder = "ignored",
  	shield = "protected",
  	thrust = on_attack_received
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  start_walking()
end)
