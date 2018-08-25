-- Moldorm boss script.

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

local sprites_folder = "enemies/boss/moldorm/" -- Rename this if necessary.
local body_parts = {} -- In this order: head, body_1, body_2, body_3, tail.
local normal_angle_speed, max_angle_speed = 128, 180
local min_radius, max_radius = 24, 80
local delay_between_parts = 250
local is_hurt

-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Check the number of parts already created (by recurrence).
  local exists = map.moldorm_tail_exists
  if exists then return end -- Exit function.
  map.moldorm_tail_exists = true

  -- Define tail properties.
  local x, y, layer = enemy:get_position()
  local sprite = enemy:create_sprite(sprites_folder .. "moldorm")
  sprite:set_direction(3)
  enemy:set_life(5)
  enemy:set_damage(1)
  enemy:set_hurt_style("boss")
  body_parts[5] = enemy
  
  -- Create remaining body parts.
  local body_names = {"head", "body_1", "body_2", "body_3"}
  for i = 1, 4 do  
    local e = map:create_enemy({
      breed = enemy:get_breed(),
      direction = 3,  x = x, y = y, layer = layer, width = 32, height = 32,
    })
    e:create_sprite(sprites_folder .. "moldorm_" .. body_names[i])
    e:set_invincible(true)
    body_parts[i] = e
  end
  -- Clear variable after body parts creation (necessary for several Moldorms).
  map.moldorm_tail_exists = nil

  -- Define on_restarted events.
  for i = 1, 4 do
    body_parts[i].on_restarted = function() end
    body_parts[i]:restart()
  end
  function enemy:on_restarted() enemy:go_random() end

  -- Add index and parts getters. Create lists for next movement.
  for i = 1, 5 do
    local e = body_parts[i] 
    function e:get_index() return i end
    function e:get_body_part(i) return body_parts[i] end
    e.movement_list = {}
  end 
end

-- Stop movements and timers only on head when hurt.
function enemy:on_hurt()
  enemy:get_body_part(1):restart()
  is_hurt = true
end

-- Create list with circle movement info: radius, center, is_clockwise, init_angle, max_rotations, is_hurt.
function enemy:create_new_movement_info()
  -- Only the head can call this function.
  if enemy:get_index() ~= 1 then return end
  -- Create random properties.
  local radius = math.floor(math.random(min_radius, max_radius))
  local is_clockwise = math.random(0,1) == 1
  local max_angle = math.max(1, 2 * math.pi * math.random())
  local max_rotations = max_angle / (2 * math.pi)
  -- Keep the same enemy "angle" of the head part if already moving.
  local x, y, layer = enemy:get_position()
  local m = enemy.movement_list[1]
  local current_angle_center, current_is_clockwise
  if m then
    current_is_clockwise = m:is_clockwise()
    current_angle_center = m:get_angle_from_center()
  else
    current_is_clockwise = is_clockwise
    current_angle_center = 2 * math.pi * math.random()
  end
  local init_angle = (is_clockwise == current_is_clockwise) and current_angle_center
    or ((-1) * current_angle_center)
  local angle_enemy = current_is_clockwise and (current_angle_center - math.pi/2)
      or (current_angle_center + math.pi/2)
  local center = {x = x + radius * math.cos(angle_enemy), y = y + radius * math.sin(angle_enemy)}
  -- Return info.
  local info = {
    radius = radius, center = center, is_clockwise = is_clockwise,
    init_angle = init_angle, max_rotations = max_rotations, is_hurt = is_hurt
  }
  return info
end

-- Create a movement with the info.
function enemy:start_movement(info)
  local m = sol.movement.create("circle")
  m:set_radius(info.radius)
  m:set_center(info.center.x, info.center.y)
  if info.is_hurt then m:set_angle_speed(max_angle_speed)
  else m:set_angle_speed(normal_angle_speed) end
  m:set_clockwise(info.is_clockwise)
  m:set_angle_from_center(info.init_angle)
  m:set_max_rotations(info.max_rotations)
  m:start(enemy)
end

-- Add next movement to the movement list.
function enemy:add_next_movement(info)
  local list = enemy.movement_list
  list[#list + 1] = info
end

-- Remove last movement to the movement list.
function enemy:remove_last_movement()
  local list = enemy.movement_list
  for i = 1, #list -1 do
    list[i] = list[i + 1]
  end
  list[#list] = nil
end

-- Check if there is next movement in the movement list.
function enemy:has_next_movement()
  local list = enemy.movement_list
  return #list > 0
end

-- Start next movement, if any, and delete its info from the list.
function enemy:start_next_movement()
  if enemy:has_next_movement() then
    local info = enemy.movement_list[1]
    enemy:start_movement(info)
    enemy:remove_last_movement()
  end
end

-- Start next movement when a movement has finished.
-- The head creates a new movement when necessary.
function enemy:on_movement_finished()
  if enemy:get_index() ~= 1 then -- The body part is not the head.
    enemy:start_next_movement()
    enemy:remove_last_movement(enemy)
  else -- The body part is the head.
    -- Add new movement info to all body parts.
    local info = enemy:create_new_movement_info()
    for i = 1, 5 do
      enemy:get_body_part(i):add_next_movement(info)
    end
    -- Start movement on head.
    enemy:start_next_movement()
  end
end

-- Start random sequence of movements.
function enemy:go_random()
  -- Create and initialize movements.
  local tail = enemy:get_body_part(5)
  local head = enemy:get_body_part(1)
  local info = head:create_new_movement_info()
  for i = 1, 5 do
    sol.timer.start(tail, (i-1) * delay_between_parts, function() 
      enemy:get_body_part(i):add_next_movement(info)
      enemy:get_body_part(i):start_next_movement()
    end)
  end
end
