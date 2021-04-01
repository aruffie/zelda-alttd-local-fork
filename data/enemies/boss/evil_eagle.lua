----------------------------------
--
-- Evil Eagle.
--
-- Flying enemy for sideview map.
-- It have three random attacks. The first is just an horizontal fly around the screen, the second is a dive to the center of the floor platform,
-- and the last one is a wind repulsing the hero with a barrage of feathers.
-- The second and third attacks can only happens if the enemy lost at least three health point, and the first and second attacks loops until the enemy is hurt.
--
-- Methods : enemy:start_fighting()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local hurt_shader = sol.shader.create("hurt")
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local sixteenth = math.pi * 0.125
local map_width, map_height = map:get_size()
local attacks = {}
local next_attack
local floor_y
local is_ready = false
local is_on_left_side = true

-- Configuration variables
local rushing_speed = 240
local flying_speed = 120
local diving_speed = 280
local between_attacks_duration = 2000
local before_diving_duration = 1000
local feather_speed = 240
local wind_speed = 104
local before_wind_duration = 1000
local wind_duration = 5000
local after_wind_duration = 1000
local between_feathers_duration = 500
local hurt_duration = 600
local rushing_probability = 0.2
local diving_probability = 0.3

-- Choose the next attack randomly.
local function set_next_attack()

  local rng = math.random()
  if enemy:get_life() > 18 or rng < rushing_probability then
    next_attack = "rushing"
  elseif rng < rushing_probability + diving_probability then
    next_attack = "diving"
  else
    next_attack = "wind"
  end
end

-- Behavior on hit.
local function on_hurt(damage)

  enemy:set_invincible()
  enemy:set_can_attack(false)
  enemy:stop_movement()
  sol.timer.stop_all(enemy)

  -- Custom die if no more life.
  if enemy:get_life() - damage < 1 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    local x, y = sprite:get_xy()
    enemy:start_death(function()
      sprite:set_animation("hurt")
      sprite:set_shader(hurt_shader)
      sol.timer.start(enemy, 1500, function()
        enemy:start_close_explosions(32, 2500, "entities/explosion_boss", x, y, function()
          sol.timer.start(enemy, 1000, function()
            enemy:start_brief_effect("entities/explosion_boss", nil, x, y)
            finish_death()
          end)
        end)
        sol.timer.start(enemy, 200, function()
          enemy:start_close_explosions(32, 2300, "entities/explosion_boss", x, y)
        end)
      end)
    end)
    return
  end

  -- Else manually hurt it, and choose the next attack.
  local direction = sprite:get_direction()
  enemy:set_life(enemy:get_life() - damage)
  sprite:set_animation("hurt")
  sprite:set_shader(hurt_shader)
  set_next_attack()

  if enemy.on_hurt then
    enemy:on_hurt()
  end

  -- Start a movement to the north after some time then restart.
  sol.timer.start(enemy, hurt_duration, function()
    sprite:set_animation("flying")
    sprite:set_shader(nil)
    local movement = enemy:start_straight_walking(quarter, flying_speed)
    movement:set_ignore_obstacles()

    function movement:on_position_changed()
      if not camera:overlaps(enemy:get_max_bounding_box()) then
        local hero_x = hero:get_position()
        movement:stop()
        is_on_left_side = hero_x < map_width * 0.5
        enemy:restart()
      end
    end
    sprite:set_direction(direction)
  end)
end

-- Make the boss able to interact and visible, or not.
local function start_vulnerable(vulnerable)

  enemy:set_visible(vulnerable)
  enemy:set_can_attack(vulnerable)
  if vulnerable then
    enemy:set_hero_weapons_reactions({
    	arrow = function() on_hurt(2) end,
    	boomerang = function() on_hurt(3) end,
    	explosion = function() on_hurt(8) end,
    	sword = function() on_hurt(2) end,
    	thrown_item = "protected",
    	fire = function() on_hurt(6) end,
    	jump_on = "ignored",
    	hammer = "protected",
    	hookshot = function() on_hurt(3) end,
    	magic_powder = "ignored",
    	shield = "protected",
    	thrust = function() on_hurt(8) end
    })
  else
    enemy:set_invincible()
  end
end

-- Charge on a random height, or on the hero height if he is on the ladder.
local function start_rushing_step()

  local _, hero_y = hero:get_position()
  sprite:set_animation("rushing")
  enemy:set_position(is_on_left_side and - 48 or map_width + 48, hero_y > floor_y and hero_y or math.random(16, floor_y))
  local movement = enemy:start_straight_walking(is_on_left_side and 0 or math.pi, rushing_speed)
  movement:set_ignore_obstacles()

  function movement:on_position_changed()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      movement:stop()
      is_on_left_side = not is_on_left_side
      enemy:restart()
    end
  end

  start_vulnerable(true)
end

-- Appear and pause, then dive to the center of the screen.
local function start_diving_step()

  local hero_x = hero:get_position()
  is_on_left_side = hero_x > map_width * 0.5
  sprite:set_animation("flying")
  enemy:set_position(is_on_left_side and 48 or map_width - 48, -48)

  local appearing_movement = enemy:start_straight_walking(quarter * 3.0, flying_speed, 96, function()
    sol.timer.start(enemy, before_diving_duration, function()
      local diving_movement = enemy:start_straight_walking(enemy:get_angle(map_width * 0.5, floor_y), diving_speed)
      diving_movement:set_ignore_obstacles()

      function diving_movement:on_position_changed()
        if not camera:overlaps(enemy:get_max_bounding_box()) then
          diving_movement:stop()
          is_on_left_side = not is_on_left_side
          enemy:restart()
        end
      end
    end)
  end)
  appearing_movement:set_ignore_obstacles()
  sprite:set_direction(is_on_left_side and 0 or 2)
  start_vulnerable(true)
end

-- Start a wind that repulse the hero.
local function start_wind(speed, to_left)

  local move_x = to_left and -1 or 1
  local move_delay = 1000 / speed

  return sol.timer.start(enemy, move_delay, function()
    local hero_x, hero_y, hero_layer = hero:get_position()
    if ignore_obstacles or not hero:test_obstacles(move_x, 0) then
      hero:set_position(hero_x + move_x, hero_y, hero_layer)
    end
    return true
  end)
end

-- Throw a feather to the hero.
local function throw_feather()

  local feather = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_feather",
    breed = "empty", -- Workaround: Breed is mandatory but a non-existing one seems to be ok to create an empty enemy though.
    direction = 0
  })
  feather:set_invincible()
  feather:set_can_attack(true)
  feather:set_damage(4)
  local feather_sprite = feather:create_sprite("enemies/" .. enemy:get_breed() .. "/feather")
  feather_sprite:set_animation("throwed")
  feather_sprite:set_direction(sprite:get_direction())

  -- Go to the hero.
  local movement = sol.movement.create("straight")
  movement:set_speed(feather_speed)
  movement:set_angle(enemy:get_angle(hero) + math.random() % 0.05 - 0.025)
  movement:set_ignore_obstacles()
  movement:start(feather)

  function movement:on_position_changed()
    if not camera:overlaps(feather:get_max_bounding_box()) then
      feather:remove()
    end
  end

  -- Protect from feather with the shield.
  feather:set_hero_weapons_reactions({shield = function()
    feather:set_can_attack(false)
    feather:set_invincible(true)
    movement:set_angle(math.acos(math.cos(movement:get_angle())))
    feather_sprite:set_animation("repulsed")
  end})

  -- Echo some of the main enemy methods
  enemy:register_event("on_removed", function(enemy)
    if feather:exists() then
      feather:remove()
    end
  end)
  enemy:register_event("on_enabled", function(enemy)
    feather:set_enabled()
  end)
  enemy:register_event("on_disabled", function(enemy)
    feather:set_enabled(false)
  end)
  enemy:register_event("on_dead", function(enemy)
    if feather:exists() then
      feather:remove()
    end
  end)
end

-- Start a wind that repulse the hero and throw some feather to the hero.
local function start_wind_step()

  local hero_x = hero:get_position()
  is_on_left_side = hero_x > map_width * 0.5
  sprite:set_animation("flying")
  enemy:set_position(is_on_left_side and -48 or map_width + 48, 24)

  local appearing_movement = enemy:start_straight_walking(sixteenth * (is_on_left_side and 15 or 9), flying_speed, 122, function()
    sol.timer.start(enemy, before_wind_duration, function()

      -- Start the actual wind a feather throws.
      start_wind(wind_speed, not is_on_left_side)
      sol.timer.start(enemy, between_feathers_duration, function()
        throw_feather()
        return true
      end)

      -- Start escaping.
      sol.timer.start(enemy, wind_duration, function()
        sol.timer.stop_all(enemy) -- Stop wind and feather throw.
        sol.timer.start(enemy, after_wind_duration, function()
          sprite:set_animation("rushing")
          local escaping_movement = enemy:start_straight_walking(sixteenth * (is_on_left_side and 1 or 7), rushing_speed)
          escaping_movement:set_ignore_obstacles()

          function escaping_movement:on_position_changed()
            if not camera:overlaps(enemy:get_max_bounding_box()) then
              escaping_movement:stop()
              is_on_left_side = not is_on_left_side
              set_next_attack()
              enemy:restart()
            end
          end
          sprite:set_direction(is_on_left_side and 0 or 2)
        end)
      end)
    end)
  end)
  appearing_movement:set_ignore_obstacles()
  sprite:set_direction(is_on_left_side and 0 or 2)
  start_vulnerable(true)
end

-- Set the boss begin the first step, restarting its life if needed.
enemy:register_event("start_fighting", function(enemy)

  is_ready = true
  next_attack = "rushing"
  sol.timer.stop_all(enemy)
  enemy:stop_movement()
  enemy:set_life(24)
  enemy:restart()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(24)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 8)
  enemy:set_damage(8)
  _, floor_y = enemy:get_position()

  -- Store attacks.
  attacks["rushing"] = start_rushing_step
  attacks["diving"] = start_diving_step
  attacks["wind"] = start_wind_step
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_obstacle_behavior("flying")
  enemy:set_pushed_back_when_hurt(false)
  start_vulnerable(false)
  if is_ready then
    sol.timer.start(enemy, between_attacks_duration, function()
      attacks[next_attack]()
    end)
  end
end)
