----------------------------------
--
-- Slime Eel's Flail.
--
-- Tail of the Slime Eel with a spiked ball at the end, used as a flail.
-- The flail turn around itself, successively slow down to arm a strike, then speed up to actually strike.
-- Can be manually pulled in ground by a length value where it stop its movement for some time, then manually rising to go back to its initial length and strike again.
--
-- Methods : enemy:stop_moving()
--           enemy:start_rising([speed])
--           enemy:start_spinning()
--           enemy:start_pulled([length, [speed]])
--           enemy:start_exploding()
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprites = {}
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local striking_timer
local is_spinning = false

local spin_angle = quarter
local strike_angle = -1.5
local rotation_ratio = 1

-- Configuration variables.
local part_distances = {16, 36, 52, 68, 84}
local revolution_duration = 5000
local striking_duration = 1500
local rising_speed = 192

-- Start the regular tail movement.
local function start_regular_movement()

  rotation_ratio = rotation_ratio == 1 and -1 or 1 -- Reverse the rotation sense.

  local spin_time = spin_angle / circle * revolution_duration
  local strike_time = strike_angle / circle * striking_duration
  striking_timer = sol.timer.start(enemy, 10, function()

    -- Compute the spin angle if spinning, and a sinus variation to apply on it to simulate the striking.
    if is_spinning then
      spin_time = (spin_time + 10 * rotation_ratio) % revolution_duration
      spin_angle = spin_time / revolution_duration * circle
    end
    strike_time = (strike_time + 10 * rotation_ratio) % striking_duration
    strike_angle = math.sin(strike_time / striking_duration * circle) * 1.5

    -- Set sprite positions where the further the sprite is, the more the striking variation is fully applied.
    for i = 1, #part_distances, 1 do
      local angle = spin_angle - part_distances[i] / part_distances[#part_distances] * strike_angle
      sprites[i]:set_xy(part_distances[i] * math.cos(angle), -part_distances[i] * math.sin(angle))
    end
    return true
  end)
end

-- Update the sprite positions to simulate their height when rising or pulled.
local function update_sprite_elevations(direction_ratio, distance, speed, on_finished_callback)

  sol.timer.stop_all(enemy)

  local x, y = sprites[#part_distances]:get_xy()
  local initial_length = sol.main.get_distance(0, 0, x, y)
  local initial_tail_distance = initial_length - part_distances[#part_distances]

  distance = distance or (direction_ratio == 1 and part_distances[#part_distances] - initial_length or initial_length)
  speed = speed or rising_speed

  local duration = distance / speed * 1000
  local time = 0
  sol.timer.start(enemy, 10, function()
    time = time + 10
    
    local traveled_distance = distance * time / duration * direction_ratio
    for i = 1, #part_distances, 1 do
      local length = math.min(part_distances[i], math.max(0, initial_tail_distance + part_distances[i] + traveled_distance))
      local angle = spin_angle - length / part_distances[#part_distances] * strike_angle

      -- Set sprite positions and hide ones that are on the exact enemy position.
      sprites[i]:set_xy(length * math.cos(angle), -length * math.sin(angle))
      sprites[i]:set_opacity(length > 0 and 255 or 0)
    end

    if time <= duration then
      return true
    end

    if on_finished_callback then
      on_finished_callback()
    end
  end)
end

-- Make the tail stop rising.
enemy:register_event("stop_moving", function(enemy, speed)

  is_spinning = false
  sol.timer.stop_all(enemy)
end)

-- Make the tail rise to its fighting position.
enemy:register_event("start_rising", function(enemy, speed)

  is_spinning = false
  update_sprite_elevations(1, nil, speed, function()
    start_regular_movement() -- Start the regular movement once ready.
  end)
end)

-- Make the tail start spinning.
enemy:register_event("start_spinning", function(enemy)

  is_spinning = true
end)

-- Pull the tail onto the ground.
enemy:register_event("start_pulled", function(enemy, length, speed)

  update_sprite_elevations(-1, length, speed)
end)

-- Start the dying behavior of the enemy.
enemy:register_event("start_exploding", function(enemy)

  enemy:start_death(function()
    local sorted_tied_sprites = {}
    for i = #sprites, 1, -1 do
      if sprites[i]:get_opacity() == 255 then
        sprites[i]:set_animation(sprites[i].base_animation .. "_hurt")
        table.insert(sorted_tied_sprites, sprites[i])
      end
    end

    sol.timer.start(enemy, 2000, function()
      enemy:start_sprite_explosions(sorted_tied_sprites, "entities/explosion_boss", 0, 0, function()
        finish_death()
      end)
    end)
  end)
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(32, 32)
  enemy:set_origin(16, 29)

  -- Create the tail sprites.
  sprites[1] = enemy:create_sprite("enemies/boss/slime_eel/body")
  sprites[1].base_animation = "base"
  sprites[1]:set_opacity(0)
  for i = 2, #part_distances - 1, 1 do
    sprites[i] = enemy:create_sprite("enemies/boss/slime_eel/body")
    sprites[i].base_animation = "body"
    sprites[i]:set_opacity(0)
  end
  sprites[#part_distances] = enemy:create_sprite("enemies/boss/slime_eel/body")
  sprites[#part_distances].base_animation = "tail"
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

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
    magic_powder = "ignored",
    shield = "protected",
    thrust = "protected"
  })

  enemy:set_damage(4)
  enemy:set_can_attack(true)
  enemy:set_obstacle_behavior("flying") -- Don't fall in holes.
  enemy:set_pushed_back_when_hurt(false)
  for _, sprite in ipairs(sprites) do
    sprite:set_animation(sprite.base_animation)
  end
  enemy:start_rising()
end)
