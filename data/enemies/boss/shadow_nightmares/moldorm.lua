----------------------------------
--
-- Moldorm's Shadow.
--
-- Caterpillar enemy with three body parts and one tail that will follow the head move.
-- Moves in curved motion, and randomly change the direction of the curve.
-- Speed up the move if set_angry() or hurt.
--
-- Methods : enemy:start_walking()
--           enemy:set_angry()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprites = {}
local head_sprite, tail_sprite
local last_positions, frame_count
local walking_movement
local is_angry

-- Configuration variables
local walking_speed = 88
local walking_angle = 0.035
local running_speed = 140
local tied_sprites_frame_lags = {25, 45, 61, 73}
local keeping_angle_duration = 250
local angry_duration = 3000

-- Constants
local highest_frame_lag = tied_sprites_frame_lags[#tied_sprites_frame_lags] + 1
local sixteenth = math.pi * 0.125
local eighth = math.pi * 0.25
local quarter = math.pi * 0.5
local circle = math.pi * 2.0

-- Update head sprite direction, and tied sprites offset.
local function update_sprites()

  -- Save current position
  local x, y, _ = enemy:get_position()
  last_positions[frame_count] = {x = x, y = y}

  -- Set the head sprite direction.
  local direction8 = math.floor((enemy:get_movement():get_angle() + sixteenth) % circle / eighth)
  if head_sprite:get_direction() ~= direction8 then
    head_sprite:set_direction(direction8)
  end

  -- Replace part sprites on a previous position.
  local function replace_part_sprite(sprite, frame_lag)
    local previous_position = last_positions[(frame_count - frame_lag) % highest_frame_lag] or last_positions[0]
    sprite:set_xy(previous_position.x - x, previous_position.y - y)
  end
  for i = 1, 4 do
    replace_part_sprite(sprites[i + 1], tied_sprites_frame_lags[i])
  end

  frame_count = (frame_count + 1) % highest_frame_lag
end

-- Hurt or repulse the hero depending on touched sprite.
local function on_attack_received()

  -- Make sure to only trigger this event once by attack.
  enemy:set_invincible()

  -- Don't hurt and only repulse if the hero sword sprite doesn't collide with the tail sprite.
  if not enemy:overlaps(hero, "sprite", tail_sprite, hero:get_sprite("sword")) then
    enemy:start_pushing_back(hero, 200, 100, sprite, nil, function()
      enemy:set_hero_weapons_reactions({
      	arrow = on_attack_received,
      	boomerang = on_attack_received,
      	explosion = on_attack_received,
      	sword = on_attack_received,
      	thrown_item = on_attack_received,
      	fire = on_attack_received,
      	jump_on = "ignored",
      	hammer = on_attack_received,
      	hookshot = on_attack_received,
      	magic_powder = on_attack_received,
      	shield = "protected",
      	thrust = on_attack_received
      })
    end)
    return
  end

  -- Custom die if only one more life point.
  if enemy:get_life() < 2 then

    enemy:start_death(function()
      for _, sprite in enemy:get_sprites() do
        if sprite:has_animation("hurt") then
          sprite:set_animation("hurt")
        end
      end

      sol.timer.start(enemy, 2000, function()
        finish_death()
      end)
    end)
    return
  end

  -- Else hurt normally.
  enemy:hurt(1)
end

-- Start the enemy movement.
function enemy:start_walking()

  walking_movement = sol.movement.create("straight")
  walking_movement:set_speed(walking_speed)
  walking_movement:set_angle(math.random(4) * quarter)
  walking_movement:set_smooth(false)
  walking_movement:start(enemy)

  -- Take the obstacle normal as angle on obstacle reached.
  function walking_movement:on_obstacle_reached()
    walking_movement:set_angle(enemy:get_obstacles_normal_angle(walking_movement:get_angle()))
  end

  -- Regularly and randomly change the angle.
  sol.timer.start(enemy, keeping_angle_duration, function()
    if math.random(2) == 1 then
      walking_angle = 0 - walking_angle
    end
    return true
  end)

  -- Update walking angle, head sprite direction and tied sprites positions
  sol.timer.start(enemy, 10, function()
    walking_movement:set_angle((walking_movement:get_angle() + walking_angle) % circle)
    update_sprites()
    return walking_speed / walking_movement:get_speed() * 10 -- Schedule for each frame while walking and more while running, to keep the same curve and sprites distance.
  end)
end

-- Increase the enemy speed for some time.
function enemy:set_angry()

  is_angry = true
  walking_movement:set_speed(running_speed)
  sol.timer.start(enemy, angry_duration, function()
    is_angry = false
    walking_movement:set_speed(walking_speed)
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(16)
  enemy:set_size(24, 24)
  enemy:set_origin(12, 12)
  
  -- Create sprites in right z-order.
  sprites[5] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/tail")
  for i = 3, 1, -1 do
    sprites[i + 1] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body_" .. i)
  end
  sprites[1] = enemy:create_sprite("enemies/" .. enemy:get_breed())

  head_sprite = sprites[1]
  tail_sprite = sprites[5]
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = on_attack_received,
  	boomerang = on_attack_received,
  	explosion = on_attack_received,
  	sword = on_attack_received,
  	thrown_item = on_attack_received,
  	fire = on_attack_received,
  	jump_on = "ignored",
  	hammer = on_attack_received,
  	hookshot = on_attack_received,
  	magic_powder = on_attack_received,
  	shield = "protected",
  	thrust = on_attack_received
  })

  -- States.
  last_positions = {}
  frame_count = 0
  is_angry = false
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
  if enemy:get_life() < 16 then -- Don't be angry on the first start.
    enemy:set_angry()
  end
end)