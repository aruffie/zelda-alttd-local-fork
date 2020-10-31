----------------------------------
--
-- Smasher.
--
-- Hop to be horizontally aligned with the hero and randomly throw three to five sai, then start charging.
-- Hit the wall and be vulnerable if the charge started too close of a wall, else start a search animation and restart.
-- Slightly increase the speed each time the enemy is hurt.
--
--
-- Methods : enemy:start_moving()
--           enemy:start_throwing()
--           enemy:start_charging()
--           enemy:start_searching()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local eighth = math.pi * 0.25
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local is_ball_controlled_by_hero = false
local is_ball_controlled_by_enemy = false
local is_ball_carried_by_enemy = false
local ball, ball_sprite

-- Configuration variables
local ball_initial_offset_x = 80
local ball_initial_offset_y = 48
local jumping_speed = 80
local jumping_height = 6
local jumping_duration = 200
local jumping_speed_while_carrying = 20
local carrying_height = 30
local jump_count_before_throwing = 3
local throwing_speeds = {240, 40, 20}
local throwing_durations = {600, 160, 70}
local throwing_heights = {carrying_height, 4, 2}

-- Create the ball and related events.
local function create_ball()

  local x, y, layer = enemy:get_position()
  ball = map:create_custom_entity({
    direction = 0,
    x = x + ball_initial_offset_x,
    y = y + ball_initial_offset_y,
    layer = layer,
    width = 16,
    height = 16,
    model = "ball",
    sprite = "entities/iron_ball"
  })
  ball:set_traversable_by("enemy", true)
  ball:set_can_traverse("enemy", true)
  ball:register_event("on_interaction", function(ball)
    is_ball_controlled_by_hero = true
  end)
  ball:register_event("on_finish_throw", function(ball)
    is_ball_controlled_by_hero = false
  end)
  ball_sprite = ball:get_sprite()

  -- Make the ball welded to the enemy on carried.
  enemy:register_event("on_position_changed", function(enemy, x , y, layer)
    if is_ball_carried_by_enemy then
      ball:set_position(x, y, layer)
    end
  end)
  sprite:register_event("set_xy", function(ball, x ,y)
    if is_ball_carried_by_enemy then
      ball_sprite:set_xy(x, y - carrying_height)
    end
  end)

  -- Add the collision test to hurt the hero if the ball is controlled by the enemy.
  ball:add_collision_test("sprite", function(ball, entity)
    if is_ball_controlled_by_enemy and entity:get_type() == "hero" and not entity:is_blinking() then
      entity:start_hurt(ball, enemy:get_damage())
    end
  end)
end

-- Function to make the carriable not traversable by the hero and vice versa. 
-- Delay this moment if the hero would get stuck.
local function set_hero_not_traversable_safely()
  if not ball:overlaps(map:get_hero()) then
    ball:set_traversable_by("hero", false)
    ball:set_can_traverse("hero", false)
    return
  end
  sol.timer.start(ball, 10, function() -- Retry later.
    set_hero_not_traversable_safely()
  end)
end

-- Return the result of the xor operation.
local function xor(a, b)
  return (a or b) and not (a and b)
end

-- Return the normal angle of close obstacles as a multiple of pi/4, or nil if none.
local function get_obstacles_normal_angle(entity)

  local collisions = {
    [0] = entity:test_obstacles(-1,  0),
    [1] = entity:test_obstacles(-1,  1),
    [2] = entity:test_obstacles( 0,  1),
    [3] = entity:test_obstacles( 1,  1),
    [4] = entity:test_obstacles( 1,  0),
    [5] = entity:test_obstacles( 1, -1),
    [6] = entity:test_obstacles( 0, -1),
    [7] = entity:test_obstacles(-1, -1)
  }

  -- Return the normal angle for this direction if collision on the direction or the two surrounding ones, and no obstacle in the two next or obstacle in both.
  local function check_normal_angle(direction8)
    return ((collisions[direction8] or collisions[(direction8 - 1) % 8] and collisions[(direction8 + 1) % 8]) 
        and not xor(collisions[(direction8 - 2) % 8], collisions[(direction8 + 2) % 8])
        and direction8 * eighth)
  end

  -- Check for obstacles on each direction8 and return the normal angle if it is the correct one.
  local normal_angle
  for direction8 = 0, 7 do
    normal_angle = normal_angle or check_normal_angle(direction8)
  end

  return normal_angle
end

-- Return the angle after bouncing against close obstacles towards the given angle, or nil if no obstacles.
local function get_obstacles_bounce_angle(entity, angle)

  local normal_angle = get_obstacles_normal_angle(entity)
  if not normal_angle then
    return
  end

  return (2.0 * normal_angle - angle + math.pi) % circle
end

-- Check if the custom death as to be started before triggering the built-in hurt behavior.
local function hurt(damage)

  -- Custom die if no more life.
  if enemy:get_life() - damage < 1 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    enemy:start_death(function()
      sprite:set_animation("hurt")
      ball:remove() -- Avoid the ball to be carried again.
      sol.timer.start(enemy, 1500, function()
        enemy:start_close_explosions(32, 2500, "entities/explosion_boss", 0, -13, function()
          sol.timer.start(enemy, 1000, function()
            enemy:start_brief_effect("entities/explosion_boss", nil, 0, -13)
            finish_death()
          end)
        end)
        sol.timer.start(enemy, 200, function()
          enemy:start_close_explosions(32, 2300, "entities/explosion_boss", 0, -13)
        end)
      end)
    end)
    return
  end

  -- Else hurt normally.
  enemy:hurt(damage)
end

-- Start the enemy jumping movement.
local function start_jumping(angle, speed, on_finished_callback)

  local movement = enemy:start_jumping(jumping_duration, jumping_height, angle, speed, function()
    on_finished_callback()
  end)
  sprite:set_direction(angle > quarter and angle < 3.0 * quarter and 2 or 0)
end

-- Start throwing the ball to the hero.
local function start_throwing()

  is_ball_carried_by_enemy = false

  local time = 0
  local function get_throwing_height(current_bounce)
    time = time + 10
    local progress = time / throwing_durations[current_bounce]
    if current_bounce == 1 then
      return 3 * throwing_heights[current_bounce] * (progress ^ 2 - progress) - (throwing_heights[current_bounce] * (1.0 - progress))
    end
    return 4 * throwing_heights[current_bounce] * (progress ^ 2 - progress)
  end

  sprite:set_animation("throwing", function()
    sprite:set_animation("throwed")
    local bounce_count = 1
    local angle = ball:get_angle(hero)
    local movement = sol.movement.create("straight")
    movement:set_speed(throwing_speeds[bounce_count])
    movement:set_angle(angle)
    movement:set_smooth(false)
    movement:start(ball)

    -- Update the ball height each frames.
    local throwing_timer = sol.timer.start(ball, 10, function()
      local height = get_throwing_height(bounce_count)
      if time <= throwing_durations[bounce_count] then
        ball_sprite:set_xy(0, height)
      else

        -- Restart the enemy on the first bounce, and start three additionnal ones.
        if bounce_count == 1 then
          enemy:restart()
          movement:set_speed(10)
        elseif bounce_count == 3 then
          is_ball_controlled_by_enemy = false
          movement:stop()
          set_hero_not_traversable_safely()
          ball:set_weight(1)
          return
        end
        bounce_count = bounce_count + 1
        movement:set_speed(throwing_speeds[bounce_count])
        time = 0
      end
      return true
    end)

    -- Bonk on obstacle reached.
    function movement:on_obstacle_reached()
      movement:set_angle(get_obstacles_bounce_angle(ball, movement:get_angle()))
    end
  end)
end

-- Start carrying the ball.
local function start_carrying()

  local x, y = enemy:get_position()
  local direction = sprite:get_direction()
  local lifting_trajectories = {
  {{-20, 0}, {0, 0}, {6, -12},  {7, -12}, {7, -carrying_height + 24}},
  {{20, 0}, {0, 0}, {-6, -12}, {-7, -12},  {-7, -carrying_height + 24}}}
  local movement = sol.movement.create("pixel")
  movement:set_trajectory(lifting_trajectories[direction == 2 and 1 or 2])
  movement:set_ignore_obstacles(true)
  movement:set_delay(100)

  ball:set_position(x , y)
  ball_sprite:set_xy(0, 0)
  movement:start(ball_sprite)
  sprite:set_animation("carrying")
  enemy:bring_to_front() -- Ensure the enemy is displayed over the carraible shadow.

  -- Make three little jumps when carrying finished then start throwing the ball.
  local function jump_before_throwing(jump_count)
    start_jumping(enemy:get_angle(hero), jumping_speed_while_carrying, function()
      if jump_count < jump_count_before_throwing then
        jump_before_throwing(jump_count + 1)
      else
        start_throwing()
      end
    end)
  end
  function movement:on_finished()
    is_ball_controlled_by_enemy = true
    is_ball_carried_by_enemy = true
    jump_before_throwing(0)
  end

  -- Make the ball not carriable by the hero and hurt him on touched.
  ball:set_weight(-1) -- Avoid the ball to be lifted by the hero.
  ball:set_traversable_by("hero", true)
  ball:set_can_traverse("hero", true)
end

-- Start the enemy panic jumping movement.
local function start_panicking()

  sprite:set_animation("panicking")
  start_jumping(math.random() * math.pi, jumping_speed, function()
    enemy:restart()
  end)
end

-- Start the enemy movement to the ball.
local function start_moving_to_ball()

  sprite:set_animation("walking")
  start_jumping(enemy:get_angle(ball), jumping_speed, function()
    enemy:restart()
  end)
end

-- Enable the ball on enabled.
enemy:register_event("on_enabled", function(enemy)
  ball:set_enabled()
end)

-- Disable the ball on disabled.
enemy:register_event("on_disabled", function(enemy)
  ball:set_enabled(false)
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:set_size(48, 48)
  enemy:set_origin(24, 45)
  enemy:start_shadow("enemies/boss/armos_knight/shadow") -- TODO Create a specific shadow.
  enemy:set_drawn_in_y_order(false) -- Display the enemy as a flat entity to ensure the ball is always displayed over it.

  create_ball()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_xy(0, 0)
  enemy:set_hero_weapons_reactions("protected", {thrown_item = function() hurt(1) end})
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:set_pushed_back_when_hurt(false)
  if not is_ball_controlled_by_hero then
    if not enemy:overlaps(ball, "touching") then
      start_moving_to_ball()
    else
      start_carrying()
    end
  else
    start_panicking()
  end
end)
