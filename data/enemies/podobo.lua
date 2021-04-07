----------------------------------
--
-- Podobo.
--
-- Jumping enemy for sideview maps.
-- Wait for some time then jump with a trail behind him.
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local trail_sprites = {}
local last_positions = {}
local frame_count = 0
local x, y

-- Configuration variables.
local jumping_duration = 2000
local jumping_height = 120
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 3000
local trail_sprites_frame_lags = {5, 10}

local highest_frame_lag = trail_sprites_frame_lags[#trail_sprites_frame_lags] + 1

-- Update all sprites animation.
local function set_sprite_animations(animation)

  for _, sprite in enemy:get_sprites() do
    sprite:set_animation(animation)
  end
end

-- Start waiting for the jump.
local function start_waiting()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    enemy:start_jumping(jumping_duration, jumping_height, nil, nil, function()
      sol.timer.stop_all(enemy)
      start_waiting()
    end)
    set_sprite_animations("jumping")

    -- Change the animation at the middle of the jump.
    sol.timer.start(enemy, jumping_duration * 0.5, function()
      set_sprite_animations("falling")
    end)
  end)
end

-- Draw the trail behind the enemy.
enemy:register_event("on_pre_draw", function(enemy)

  local sprite_x, sprite_y = sprite:get_xy()
  last_positions[frame_count] = {x = sprite_x, y = sprite_y}
  for i = 2, 1, -1 do -- Draw in right order.
    local previous_position = last_positions[(frame_count - trail_sprites_frame_lags[i]) % highest_frame_lag] or last_positions[0]
    map:draw_visual(trail_sprites[i], x + previous_position.x, y + previous_position.y)
  end
  frame_count = (frame_count + 1) % highest_frame_lag
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  -- Create trail sprites on the map to not make them hurt the hero nor affected by enemy:start_jumping().
  x, y = enemy:get_position()
  for i = 1, 2, 1 do
    local trail_sprite = sol.sprite.create("enemies/" .. enemy:get_breed())
    trail_sprite:set_opacity(255 - 75 * i)
    table.insert(trail_sprites, trail_sprite)
  end
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  set_sprite_animations("jumping")
  enemy:set_invincible()
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  start_waiting()
end)
