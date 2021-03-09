----------------------------------
--
-- Slime Eel's Moldorm.
--
-- Moldorm type enemy that can sometimes substitute to the Slime Eel when catached.
-- Behaves the same as a normal Moldorm except it will explode and die on a single hit.
--
-- Methods : enemy:start_catched(length)
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
local tied_sprites_frame_lags = {}
local last_positions, frame_count
local walking_movement

-- Configuration variables
local walking_speed = 88
local walking_angle = 0.035
local tied_sprites_frame_lags = {20, 35, 50, 62}
local keeping_angle_duration = 1500

-- Constants
local highest_frame_lag = tied_sprites_frame_lags[#tied_sprites_frame_lags] + 1
local eighth = math.pi * 0.25
local quarter = math.pi * 0.5
local circle = math.pi * 2.0

-- Update head sprite direction, and tied sprites offset.
local function update_sprites()

  -- Save current position
  local x, y, _ = enemy:get_position()
  last_positions[frame_count] = {x = x, y = y}

  -- Set the head sprite direction.
  local direction4 = math.floor((enemy:get_movement():get_angle() + eighth) % circle / quarter)
  if head_sprite:get_direction() ~= direction4 then
    head_sprite:set_direction(direction4)
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

  -- Wait a few time, make tail then body sprites explode, wait a few time again and finally make the head explode and enemy die.
  enemy:start_death(function()
    for i = 1, #sprites, 1 do
      sprites[i]:set_animation(i == 1 and "hurt" or sprites[i].base_animation .. "_hurt")
    end

    sol.timer.start(enemy, 1000, function()
      local x, y = head_sprite:get_xy()
      enemy:start_brief_effect("entities/explosion_boss", nil, x, y)
      finish_death()
    end)
  end)
end

-- Start the enemy walking movement.
local function start_walking()

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

-- Start the catched movement to get out of the aperture.
function enemy:start_catched(length, speed)

  local movement = enemy:start_straight_walking(sprites[1]:get_direction() * quarter, speed, length, function()

    start_walking()
    sol.timer.start(enemy, 100, function() -- Workaround : Make sure the enemy won't be hurt with the hookshot return movement.
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
  end)
  movement:set_ignore_obstacles()

  function movement:on_position_changed()
    update_sprites()
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:set_size(24, 24)
  enemy:set_origin(12, 12)
  enemy:set_invincible()
  
  -- Create sprites in right z-order.
  sprites[5] = enemy:create_sprite("enemies/boss/slime_eel/body")
  sprites[5].base_animation = "tail"
  for i = 3, 1, -1 do
    sprites[i + 1] = enemy:create_sprite("enemies/boss/slime_eel/body")
    sprites[i + 1].base_animation = "body"
  end
  sprites[1] = enemy:create_sprite("enemies/boss/slime_eel")
  sprites[1].base_animation = "walking"

  head_sprite = sprites[1]
  tail_sprite = sprites[5]
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  last_positions = {}
  frame_count = 0
  for _, sprite in ipairs(sprites) do
    sprite:set_animation(sprite.base_animation)
  end
  enemy:set_can_attack(true)
  enemy:set_damage(4)
end)
