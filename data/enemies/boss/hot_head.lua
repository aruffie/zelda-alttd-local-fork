----------------------------------
--
-- Hot Head.
--
-- Burning enemy that jumps over lava.
-- Can only be hurt with the fire rod. The first hit will make him vulnerable and fly over the room for some time, before dive again in lava.
-- Each fire rod hit after the fly began hurt one damage until two left life point, which will make the enemy weak.
-- Once weak the enemy won't fly again and can be hurt normally while jumping over lava.
--
----------------------------------

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")
common_actions.learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local trail_sprites = {}
local last_positions, frame_count
local thirty_second = math.pi * 0.0625
local eighth = math.pi * 0.25
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local flying_angle
local lava, lava_center
local step = "burning"

-- Configuration variables
local trail_sprites_frame_lags = {10, 20}
local minimum_waiting_duration = 1500
local maximum_waiting_duration = 2000
local jumping_angles = {thirty_second, math.pi - thirty_second, math.pi + thirty_second, circle - thirty_second}
local jumping_duration = 800
local jumping_height = 24
local jumping_speed = 120
local splash_duration = 500
local splash_height = 16
local splash_speed = 120
local flying_speed = 160
local flying_duration = 3000
local diving_duration = 200
local hurt_duration = 500
local molt_falling_duration = 600

local highest_frame_lag = trail_sprites_frame_lags[#trail_sprites_frame_lags] + 1

-- Create a lava drop enemy.
local function create_lava_drop(angle)

  local drop = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_drop",
    breed = "empty", -- Workaround: Breed is mandatory but a non-existing one seems to be ok to create an empty enemy though.
    direction = 0
  })
  common_actions.learn(drop)
  drop:set_invincible()
  drop:set_can_attack(true)
  drop:set_damage(16)
  drop:start_shadow("entities/shadows/shadow", "small")
  local drop_sprite = drop:create_sprite("enemies/" .. enemy:get_breed() .. "/lava_drop")

  -- Echo some of the main enemy methods
  enemy:register_event("on_removed", function(enemy)
    if drop:exists() then
      drop:remove()
    end
  end)
  enemy:register_event("on_enabled", function(enemy)
    drop:set_enabled()
  end)
  enemy:register_event("on_disabled", function(enemy)
    drop:set_enabled(false)
  end)
  enemy:register_event("on_dead", function(enemy)
    if drop:exists() then
      drop:remove()
    end
  end)

  -- Start richochet move.
  local movement = drop:start_jumping(splash_duration, splash_height, angle, splash_speed, function()
    drop_sprite:set_animation("splash", function()
      if drop:exists() then
        drop:remove()
      end
    end)
  end)
  movement:set_ignore_obstacles()
end

-- Create enemy trail.
local function create_trail()

  last_positions = {}
  frame_count = 0

  -- Create sprites.
  local sprite_x, sprite_y = sprite:get_xy()
  for i = 1, 2, 1 do
    local trail_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
    trail_sprite:set_animation("trail")
    trail_sprite:set_opacity(255 - 75 * i)
    trail_sprite:set_xy(sprite_x, sprite_y)
    enemy:bring_sprite_to_back(trail_sprite)
    table.insert(trail_sprites, trail_sprite)
  end

  -- Replace sprites each frame.
  local function replace_trail_sprite(sprite, frame_lag)
    local previous_position = last_positions[(frame_count - frame_lag) % highest_frame_lag] or last_positions[0]
    sprite:set_xy(previous_position.x - last_positions[frame_count].x + sprite_x, previous_position.y - last_positions[frame_count].y + sprite_y)
  end

  return sol.timer.start(enemy, 10, function()

    local x, y = enemy:get_position()
    last_positions[frame_count] = {x = x, y = y}
    for i, sprite in ipairs(trail_sprites) do
      replace_trail_sprite(sprite, trail_sprites_frame_lags[i])
    end
    frame_count = (frame_count + 1) % highest_frame_lag

    return true
  end)
end

-- Make the enemy dive creating a splash effect and 4 lava drops.
local function start_diving()

  enemy:stop_flying(diving_duration, function()
    if lava:overlaps(enemy) then
      enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/lava_splash", "default")
    end
    for i = 0, 3, 1 do
      create_lava_drop(eighth + quarter * i)
    end
    if step == "extinct" then
      step = "burning"
    end
    enemy:restart()
  end)
end

-- Makes the enemy go towards the given angle and bounce on obstacle reached.
local function start_flying()

  local function start_movement(angle)
    local movement = enemy:start_straight_walking(angle, flying_speed, nil, function()
      flying_angle = enemy:get_obstacles_bounce_angle(flying_angle)
      start_movement(flying_angle)
    end)
    movement:set_smooth(false)
  end
  
  start_movement(flying_angle)
  enemy:set_can_attack(true)
  sprite:set_animation(step)
  local trail_timer = create_trail()

  -- Dive in lava again after some time.
  sol.timer.start(enemy, flying_duration, function()

    -- Retry later if the enemy is not over lava.
    if not lava:overlaps(enemy, "containing") then
      return 10
    end

    trail_timer:stop()
    for i, trail_sprite in ipairs(trail_sprites) do
      enemy:remove_sprite(trail_sprite)
      trail_sprites[i] = nil
    end
    enemy:stop_movement()
    start_diving()
  end)
end

-- Start the breaking animation.
local function start_breaking()

  local _, height = sprite:get_xy()
  height = -height
  
  for i = 0, 2, 2 do
    local molt = enemy:create_enemy({
      name = (enemy:get_name() or enemy:get_breed()) .. "_molt",
      breed = "empty", -- Workaround: Breed is mandatory but a non-existing one seems to be ok to create an empty enemy though.
      x = (i - 1) * -16,
      y = 1,
      width = 16,
      height = 16
    })
    common_actions.learn(molt)
    molt:set_can_attack(false)
    molt:set_invincible()
    molt:set_obstacle_behavior("flying")
    molt:start_shadow("entities/shadows/shadow")

    local molt_sprite = molt:create_sprite("enemies/" .. enemy:get_breed())
    molt_sprite:set_animation("breaking")
    molt_sprite:set_direction(i)

    molt:start_throwing(molt, molt_falling_duration, height, height + 6, quarter * i, 32, function()
      if lava:overlaps(molt) then
        molt:start_brief_effect("enemies/" .. enemy:get_breed() .. "/lava_splash", "default")
      end
      molt:remove()
    end)
  end
end

-- Behavior on hit by fire.
local function on_hurt()

  -- Freeze the enemy for some time.
  enemy:set_hero_weapons_reactions({fire = "protected"})
  enemy:stop_movement()
  sol.timer.stop_all(enemy)
  for i, trail_sprite in ipairs(trail_sprites) do
    enemy:remove_sprite(trail_sprite)
    trail_sprites[i] = nil
  end
  sol.timer.start(enemy, hurt_duration, function()
    enemy:set_hero_weapons_reactions({fire = on_hurt})
    if step == "weak" then
      start_diving()
    else
      start_flying()
    end
  end)

  -- Just extinguish the enemy fire on burning step to make it vulnerable.
  if step == "burning" then
    step = "extinct"
    sprite:set_animation(step)
    return
  end

  -- Custom die if no more life.
  if enemy:get_life() < 2 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    local x, y = sprite:get_xy()
    enemy:start_death(function()
      sprite:set_animation("weak_hurt")
      sol.timer.start(enemy, 1500, function()
        enemy:start_close_explosions(32, 2500, "entities/explosion_boss", x, y - 13, function()
          sol.timer.start(enemy, 1000, function()
            enemy:start_brief_effect("entities/explosion_boss", nil, x, y - 13)
            finish_death()
          end)
        end)
        sol.timer.start(enemy, 200, function()
          enemy:start_close_explosions(32, 2300, "entities/explosion_boss", x, y - 13)
        end)
      end)
    end)
    return
  end

  -- Else manually hurt it, and make it weak if only two more life points left.
  enemy:set_life(enemy:get_life() - 1)
  sprite:set_animation(step .. "_hurt")
  if enemy:get_life() == 2 then
    step = "weak"
    start_breaking()
  end
  if enemy.on_hurt then
    enemy:on_hurt()
  end
end

-- Start a jump that will end in lava.
local function start_jumping()

  -- Jump and create for splash enemies when finished.
  local jumping_angle = jumping_angles[math.floor((enemy:get_angle(lava_center.x, lava_center.y)) / quarter) % 4 + 1]
  local movement = enemy:start_jumping(jumping_duration, jumping_height, jumping_angle, jumping_speed, function()
    start_diving()
  end)
  movement:set_ignore_obstacles()
  enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/lava_splash", "default")
  enemy:set_hero_weapons_reactions({fire = on_hurt})
  enemy:set_visible()
end

-- Start waiting before jumping.
local function start_waiting()

  -- Start from random point in lava.
  local random_x, random_y = enemy:get_random_position_in_area("lava")
  enemy:set_position(random_x, random_y)

  sol.timer.start(enemy, math.random(minimum_waiting_duration, maximum_waiting_duration), function()
    start_jumping()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(10)
  enemy:set_size(32, 16)
  enemy:set_origin(16, 13)
  enemy:set_visible(false)
  enemy:start_shadow()

  -- Get lava center, assuming only one entity for lava area.
  for entity in map:get_entities_in_region(enemy) do
    if entity:get_type() ~= "enemy" and entity:get_property("area") == "lava" then
      local x, y = entity:get_position()
      local width, height = entity:get_size()
      lava = entity
      lava_center = {x = x + width * 0.5, y = y + height * 0.5}
      return
    end
  end
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  flying_angle = circle - eighth
  enemy:set_damage(16)
  enemy:set_can_attack(false)
  enemy:set_visible(false)
  enemy:set_invincible()
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_obstacle_behavior("flying")
  sprite:set_animation(step)
  start_waiting()
end)
