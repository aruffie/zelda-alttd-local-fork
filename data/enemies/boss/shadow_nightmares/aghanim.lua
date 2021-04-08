----------------------------------
--
-- Aghanim's Shadow.
--
-- Start loading a shadowball and throw it to the hero, then reduce to particle form and change position
-- A shadowball may be hurtless or returnable, in which case it will hurt the enemy if hit while returned.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local loading_shadowball

-- Configuration variables
local waiting_duration = 1000
local after_shadowball_duration = 500
local particle_speed = 120
local square_spawn_width = 120
local square_spawn_height = 88
local before_reducing_duration = 500
local before_growing_duration = 800
local hurt_duration = 600
local dying_duration = 2000

-- Return a random position on the spawn square border.
local function get_random_position_on_spawn_square_border()

  local camera_x, camera_y, camera_width, camera_height = camera:get_bounding_box()
  local x = camera_x + (camera_width - square_spawn_width) * 0.5
  local y = camera_y + (camera_height - square_spawn_height) * 0.5
  local mid_point = square_spawn_width + square_spawn_height
  local random_point = math.random(mid_point * 2)

  return {x = x + (random_point > mid_point + square_spawn_width and 0 or math.min(square_spawn_width, random_point % mid_point)), 
          y = y + math.min(square_spawn_height, math.max(0, random_point - square_spawn_width) % mid_point)}
end

-- Return the shadowball offset depending on the sprite direction.
local function get_shadowball_offset()

  local direction = sprite:get_direction()
  return (direction == 0 and 32) or (direction == 2 and -32) or 0,
         (direction == 1 and -48) or (direction == 3 and 8) or -24
end

-- Reduce as particle, randomly go to another spot then grow up again.
local function change_spot(on_finished_callback)

  -- Choose a new position.
  local position = get_random_position_on_spawn_square_border()

  -- Go to the chosen position as a particle.
  sol.timer.start(enemy, before_reducing_duration, function()
    sprite:set_animation("reducing", function()
      sprite:set_animation("disappearing", function()
        local angle = enemy:get_angle(position.x, position.y)
        local distance = enemy:get_distance(position.x, position.y)
        local movement = enemy:start_straight_walking(angle, particle_speed, distance, function()
          sol.timer.start(enemy, before_growing_duration, function()
            sprite:set_animation("appearing", function()
              sprite:set_animation("growing", function()
                if on_finished_callback then
                  on_finished_callback()
                end
              end)
            end)
          end)
        end)
        movement:set_ignore_obstacles()
        sprite:set_animation("particle")
      end)
    end)
  end)
end

-- Check if the custom death as to be started before triggering the built-in hurt behavior.
local function hurt()

  sol.timer.stop_all(enemy)

  -- Die if no more life.
  if enemy:get_life() - 1 < 1 then
    enemy:start_death(function()
      sprite:set_animation("hurt")
      sol.timer.start(enemy, hurt_duration, function()
        sprite:set_animation("spinning")
        sol.timer.start(enemy, dying_duration, function()
          finish_death()
        end)
      end)
    end)
    return
  end

  -- Make the enemy manually hurt, then change the spot and restart.
  enemy:set_life(enemy:get_life() - 1)
  sprite:set_animation("hurt")
  sol.timer.start(enemy, hurt_duration, function()
   change_spot(function()
      enemy:restart()
    end)
  end)

  if enemy.on_hurt then
    enemy:on_hurt()
  end
end

-- Start loading then throw a shadowball.
local function start_shadowball()

  sprite:set_animation("loading")

  local x, y = get_shadowball_offset()
  local shadowball = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_shadowball",
    breed = "boss/shadow_nightmares/projectiles/shadowball",
    direction = 0,
    x = x,
    y = y
  })
  loading_shadowball = shadowball

  function shadowball:on_throwed()
    loading_shadowball = nil
    sprite:set_animation("throwing")
  end

  function shadowball:on_returned()
    function shadowball:on_collision_enemy(hit_enemy, shadowball_sprite, enemy_sprite)
      if enemy == hit_enemy then
        shadowball:start_death()
        hurt()
      end
    end
  end

  function shadowball:on_dead()
    sol.timer.start(enemy, after_shadowball_duration, function()
      change_spot(function()
        enemy:restart()
      end)
    end)
  end
end

-- Wait a few time before attacking.
local function start_waiting()

  sprite:set_animation("stopped")
  sol.timer.start(enemy, waiting_duration, function()
    start_shadowball()
  end)
end

-- Update sprite direction every frame if animation is growing, waiting or loading.
enemy:register_event("on_update", function(enemy)

  local animation = sprite:get_animation()
  if animation == "growing" or animation == "stopped" or animation == "loading" then
    local direction = enemy:get_direction4_to(hero)
    if sprite:get_direction() ~= direction then
      sprite:set_direction(direction)
      if loading_shadowball then
        local x, y = enemy:get_position()
        local offset_x, offset_y = get_shadowball_offset()
        loading_shadowball:set_position(x + offset_x, y + offset_y)
      end
    end
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = "protected",
  	boomerang = "protected",
  	explosion = "ignored",
  	sword = "protected",
  	thrown_item = "protected",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = "protected",
  	magic_powder = "protected",
  	shield = "protected",
  	thrust = "protected",
  })

  -- States.
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  start_waiting()
end)
