-- Moldorm boss script.

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

local sprites_folder = "enemies/boss/moldorm/" -- Rename this if necessary.
local body_parts = {} -- In this order: head, body_1, body_2, body_3, tail.
local normal_angle_speed, max_angle_speed = 3*math.pi/4, 3*math.pi/2 -- Radians per second.
local life = 8
local min_radius, max_radius = 24, 80
local hurt_duration = 3000
local delay_between_parts = 120
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
  body_parts[6] = enemy
  
  -- Create remaining body parts.
  for i = 1, 5 do  
    local e = map:create_enemy({
      breed = enemy:get_breed(),
      direction = 3,  x = x, y = y, layer = layer, width = 32, height = 32,
    })
    body_parts[i] = e
    e:set_invincible()
    e:clear_movement_info() -- Prepare lists.
  end
  -- Clear variable after body parts creation (necessary for several Moldorms).
  map.moldorm_tail_exists = nil
  -- Create sprites. Part 5 is spriteless, used to move the tail,
  -- so that the tail keeps its current movement even when restarted.
  local body_names = {"head", "body_1", "body_2", "body_3"}
  for i = 1, 4 do 
    body_parts[i]:create_sprite(sprites_folder .. "moldorm_" .. body_names[i])
  end

  for i = 1, 6 do
    local e = body_parts[i]
    -- Define general properties.
    e:set_damage(1)
    e:set_life(life)
    e:set_hurt_style("boss")
    e:set_pushed_back_when_hurt(false)
    e:set_push_hero_on_sword(true)
    e:set_obstacle_behavior("normal")
    if i < 5 then e:set_attack_consequence("sword", "protected") end
  end

  -- Add index and parts getters.
  for i = 1, 6 do
    local e = body_parts[i]
    function e:get_index() return i end
    function e:get_body_part(i) return body_parts[i] end
    function e:get_head() return body_parts[1] end
    function e:get_tail() return body_parts[6] end
    function e:get_invisible_part() return body_parts[5] end
  end

  -- Define on_restarted event for the tail.
  local tail = body_parts[6] 
  function tail:on_restarted()
    tail:go_random()
    -- Destroy event to keep movements smooth when restarting.
    tail.on_restarted = nil
  end

  -- Kill invincible parts when tail is killed.
  function tail:on_dying()
    for i = 1, 6 do -- Stop all body parts.
      e = tail:get_body_part(i)
      e:stop_movement(); sol.timer.stop_all(e)
      e:set_life(0)
    end
    tail:get_invisible_part():remove()
  end

  -- Create eyes.
  local eye_1 = body_parts[1]:create_sprite(sprites_folder .. "moldorm_eyes", "eye_1")
  local eye_2 = body_parts[1]:create_sprite(sprites_folder .. "moldorm_eyes", "eye_2")
  body_parts[1]:set_eyes_direction(3)
  -- Synchronize sprites with tail sprite.
  function sprite:on_animation_changed(anim)
    for i = 1, 4 do
      local e = body_parts[i]
      for _, s in e:get_sprites() do s:set_animation(anim) end
    end
  end  

end

-- Getter/setter for hurt state.
function enemy:is_hurt() return is_hurt end
function enemy:set_hurt_state(hurt)
  is_hurt = hurt
  -- Tail part: invincibility properties.
  if enemy == enemy:get_tail() then
    if enemy:is_hurt() then
      enemy:set_invincible() -- Protection!
    else
      enemy:set_default_attack_consequences()
    end
  end
  -- Modify speed of current movement for all body parts.
  local m = enemy:get_movement()
  if m and sol.main.get_type(m) == "circle_movement" then
    if enemy:is_hurt() then
      m:set_angular_speed(max_angle_speed)
    else -- Not hurt.
      m:set_angular_speed(normal_angle_speed)
    end
  end
end

-- Stop movements and timers only on head when the tail is hurt.
function enemy:on_hurt()
  -- Start hurt states.
  for i = 1, 6 do
    local e = enemy:get_body_part(i)
    e:set_hurt_state(true)
    -- Finish hurt states.
    sol.timer.start(map, hurt_duration, function()
      e:set_hurt_state(false)
    end)
  end
end

-- Create list with new movement info: radius, center, is_clockwise, init_angle, max_angle.
-- Remark: Only the head can call this function.
function enemy:create_new_movement_info()
  if enemy ~= enemy:get_head() then return end
  -- Create random properties.
  local radius = math.floor(math.random(min_radius, max_radius))
  local max_angle
  if math.random(0, 100) <= 75 then -- Small angle: probability 75%
    max_angle = (math.pi/4) + (math.pi/4) * math.random()
  else -- Big angle: : probability 25%
    max_angle = math.max(1, 2 * math.pi * math.random())
  end
  -- Revert direction.
  local old_info = enemy:get_current_movement_info()
  local is_clockwise
  if old_info then is_clockwise = (not old_info.is_clockwise)
  else is_clockwise = math.random(0,1) == 1 end
  -- Calculate current angle from current center.
  local x, y, layer = enemy:get_position()
  local current_angle_center
  if old_info then
    local current_center = old_info.center
    current_angle_center = sol.main.get_angle(current_center.x, current_center.y, x, y)
  else -- Random angle.
    current_angle_center = 2 * math.pi * math.random()
  end
  -- Calculate new angle for the new center.
  local init_angle = current_angle_center + math.pi
  -- Calculate new center.
  local angle_enemy = init_angle +  math.pi
  local center = {x = x + radius * math.cos(angle_enemy), y = y - radius * math.sin(angle_enemy)}
  -- Return info.
  local info = {
    radius = radius, center = center, is_clockwise = is_clockwise,
    init_angle = init_angle, max_angle = max_angle
  }
  return info
end

-- Create a movement with the info.
function enemy:start_movement(info)
  local m = sol.movement.create("circle")
  m:set_radius(info.radius)
  m:set_center(info.center.x, info.center.y)
  m:set_clockwise(info.is_clockwise)
  m:set_angle_from_center(info.init_angle)
  m:set_max_rotations(0)
  if enemy:is_hurt() then m:set_angular_speed(max_angle_speed)
  else m:set_angular_speed(normal_angle_speed) end
  m:start(enemy)
end

-- Add next movement to the movement list.
function enemy:add_next_movement_info(info)
  local list = enemy.movement_list
  list[#list + 1] = info
end

-- Check if there is next movement in the movement list.
function enemy:has_next_movement_info()
  local list = enemy.movement_list
  return #list > 0
end

-- Get the info for the current movement.
function enemy:get_current_movement_info()
  return enemy.movement_list[1]
end

-- Destroy all movements info.
function enemy:clear_movement_info()
  enemy.movement_list = {}
end

-- Remove last movement to the movement list.
function enemy:remove_last_movement_info()
  if enemy:has_next_movement_info() then
    local list = enemy.movement_list
    for i = 1, #list -1 do
      list[i] = list[i + 1]
    end
    list[#list] = nil
  end
end

-- Start next movement, if any. If "is_random" is true, use random direction.
function enemy:start_next_movement(is_random)
  enemy:stop_movement() -- Stop previous movement.
  -- If the head needs next movement, create new movement info for all body parts.
  if enemy == enemy:get_head() then
    -- Replace previous info in "head" to get random direction, if necessary.
    if is_random then
      enemy:clear_movement_info()
      local info = enemy:create_new_movement_info()
      enemy:add_next_movement_info(info)
    end
    -- Create new movement info for all body parts.
    local info = enemy:create_new_movement_info()
    for i = 1, 5 do enemy:get_body_part(i):add_next_movement_info(info) end
  end
  -- Destroy old movement info.
  enemy:remove_last_movement_info()
  -- Start next movement if any.
  if enemy:has_next_movement_info() then
    local info = enemy:get_current_movement_info()
    enemy:start_movement(info)
  end
end

-- Create new movement in random direction when reaching obstacles.
function enemy:on_obstacle_reached(movement)
  enemy:start_next_movement(true) -- Start next movement.
end

-- Initialize a new random sequence of movements.
function enemy:go_random()
  local head = enemy:get_head()
  head:clear_movement_info() -- Clear info of previous iterations.
  local info = head:create_new_movement_info()
  for i = 1, 5 do
    local e = enemy:get_body_part(i)
    e:clear_movement_info()
    e:add_next_movement_info(info) -- This is removed in first iteration.
    sol.timer.start(map, 500 + i * delay_between_parts, function()
      e:start_next_movement()
    end)
  end
end

-- Check if the current movement has to be finished.
function enemy:on_position_changed(x, y, layer)
  -- Do nothing for the tail.
  if enemy == enemy:get_tail() then return end
  -- Move tail when the invisible part 5 moves. This avoids tail stopping when hurt.
  if enemy == enemy:get_invisible_part() then
    enemy:get_tail():set_position(x, y, layer)
  end
  -- Count the movements. This is used to check when to stop.
  local info = enemy:get_current_movement_info()
  local num_pos = info.num_positions_changed
  info.num_positions_changed = num_pos and num_pos + 1 or 0
  -- Calculate the differences of angles.
  local cx, cy = info.center.x, info.center.y
  local x, y, _ = enemy:get_position()
  local current_angle = sol.main.get_angle(cx, cy, x, y)
  local final_diff = info.max_angle % (2 * math.pi)
  local current_diff = (current_angle - info.init_angle) % (2 * math.pi)
  -- Stop if necessary, when the final angle is surpassed. Then start new movement.
  if current_diff >= final_diff and info.num_positions_changed > 0 then
    enemy:start_next_movement()
  end
  -- Update eyes for head part.
  if enemy == enemy:get_head() then
    local sign = info.is_clockwise and -1 or 1
    local eyes_dir = (enemy:get_direction8_to(cx, cy) - sign * 2) % 8
    enemy:set_eyes_direction(eyes_dir)
  end
end

-- Update position of eyes.
function enemy:set_eyes_direction(eyes_dir)
  if enemy ~= enemy:get_head() then return end
  -- Set directions.
  local eye_1 = enemy:get_sprite("eye_1")
  local eye_2 = enemy:get_sprite("eye_2")
  eye_1:set_direction(eyes_dir)
  eye_2:set_direction(eyes_dir)
  -- Shift positions.
  local shift_init_1 = {x = 5, y = -5}
  local shift_init_2 = {x = 5, y = 5}
  local angle = 2 * math.pi * eyes_dir/8
  local shift_1, shift_2 = {}, {}
  local cos, sin = math.cos(angle), math.sin(angle)
  shift_1.x = math.floor(cos * shift_init_1.x + sin * shift_init_1.y)
  shift_1.y = math.floor(cos * shift_init_1.x - sin * shift_init_1.y)
  shift_2.x = math.floor(cos * shift_init_2.x + sin * shift_init_2.y)
  shift_2.y = math.floor(cos * shift_init_2.x - sin * shift_init_2.y)
  local dy = -10
  eye_1:set_xy(shift_1.x, shift_1.y + dy)
  eye_2:set_xy(shift_2.x, shift_2.y + dy)
end

