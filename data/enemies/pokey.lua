----------------------------------
--
-- Pokey.
--
-- Moves randomly over horizontal and vertical axis
-- Composed of as much sprites as its health point, a part of his body is propelled across the room each time a weak attack is received.
--
-- Methods : enemy:start_walking()
--           enemy:detach_body()
--           enemy:wait()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local head_sprite
local body_sprites = {}
local quarter = math.pi * 0.5
local before_walking_timer

-- Configuration variables
local life_point = enemy:get_property("life_point") or 3
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local before_walking_delay = 500
local projectile_invincible_duration = 300

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Detach the lowest body and make it bounce around the map.
function enemy:detach_body()

  -- Replace sprites position and detach a body if the body number is greater than the enemy life.
  local life = enemy:get_life()
  for i = 1, #body_sprites do
    if i > life - 2 then
      enemy:remove_sprite(body_sprites[i])
      body_sprites[i] = nil
    else
      body_sprites[i]:set_xy(0, -11 * (i - 1))
    end
  end
  head_sprite:set_xy(0, -11 * #body_sprites)

  -- Create bouncing body enemy.
  if life > 1 then
    local projectile = enemy:create_enemy({
      name = (enemy:get_name() or enemy:get_breed()) .. "_cactus",
      breed = "projectiles/cactus"
    })

    -- Make the cactus invincible for some time.
    projectile:set_invincible()
    sol.timer.start(projectile, projectile_invincible_duration, function()
      projectile:set_invincible()
    end)
  end

  enemy:hurt(1)
end

-- Wait a few time and start walking.
function enemy:wait()

  if before_walking_timer then
    before_walking_timer:stop()
  end
  before_walking_timer = sol.timer.start(enemy, before_walking_delay, function()
    enemy:start_walking()
  end)
end

-- Detach a body on weak attack received.
local function on_weak_attack_received()
  enemy:detach_body()
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(life_point)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()

  -- Create sprites in right z-order.
  for i = 1, life_point - 1 do
    body_sprites[i] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
  end
  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = on_weak_attack_received,
  	boomerang = 4,
  	explosion = on_weak_attack_received,
  	sword = on_weak_attack_received,
  	thrown_item = 4,
  	fire = 4,
  	jump_on = "ignored",
  	hammer = 4,
  	hookshot = 4,
  	magic_powder = 4,
  	shield = "protected",
  	thrust = 4
  })

  -- Sprites.
  for i = 1, #body_sprites do
    body_sprites[i]:set_xy(0, -11 * (i - 1))
  end
  head_sprite:set_xy(0, -11 * #body_sprites)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_damage(2)
  enemy:wait()
end)
