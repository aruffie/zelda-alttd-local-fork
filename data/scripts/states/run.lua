-- Custom run script.
require("scripts/multi_events")
require("scripts/ground_effects")
local hero_meta = sol.main.get_metatable("hero")
local map_meta = sol.main.get_metatable("map")
local game_meta = sol.main.get_metatable("game")
local running_manager = {}
-- Sounds:
local running_sound = "running"
local running_obstacle_sound = "running_obstacle"
local walk_on_grass_sound = "walk_on_grass"
local walk_on_water_sound = "walk_on_water"
-- Parameters:
local is_hero_running
local running_state -- Values: nil, "stopped", "moving".
local speed = 175
local ground_effect_timer -- Timer for ground effects.
local ground_effects_time = 100 -- Time between ground effects.
local sounds_timer -- Timer for sounds.
local sounds_time = 200 -- Time between sounds.
local moving_timer -- Check if hero can start run movement.
local pressed_timer -- Check if command is kept pressed to start run.
local direction_timer -- Direction pressed timer.
local movement -- Movement on the hero.


function hero_meta:is_running()
  return is_hero_running
end

function hero_meta:set_running(running)
  is_hero_running = running
end

-- Restart variables.
game_meta:register_event("on_started", function(game)
  is_hero_running = false
end)

-- Initialize running state.
local state = sol.state.create()
state:set_description("run")
state:set_can_control_movement(false)
state:set_can_control_direction(false)
state:set_can_use_stairs(false)
state:set_can_traverse("stairs", false)


function state:on_started(previous_state_name, previous_state)
  local psn = previous_state_name
  local hero = state:get_game():get_hero()
  local hero_sprite = hero:get_sprite()
  local sword_sprite = hero:get_sprite("sword")
  -- Change tunic animations during the run state.
  hero_sprite:set_animation("sword_loading_walking")
  sword_sprite:set_animation("sword_loading_walking")
  sword_sprite:set_direction(hero_sprite:get_direction())
  hero:set_running(true)
end


function state:on_finished(next_state_name, next_state)
  local hero = state:get_game():get_hero()
  local sword_sprite = hero:get_sprite("sword")
  sword_sprite:stop_animation()
  -- Clear variables.
  if sounds_timer then
    sounds_timer:stop()
    sounds_timer = nil
  end
  if ground_effect_timer then
    ground_effect_timer:stop()
    ground_effect_timer = nil
  end
  if movement then
    movement:stop()
    movement = nil
  end
  running_state = nil
  hero:set_running(false)
  running_manager:clean_timers()
end

-- Determine if the hero can jump on this type of ground.
function map_meta:is_runable_ground(ground_type)
  local map = self
  local is_good_ground = ( (ground_type == "traversable")
    or (ground_type == "wall_top_right") or (ground_type == "wall_top_left")
    or (ground_type == "wall_bottom_left") or (ground_type == "wall_bottom_right")
    or (ground_type == "shallow_water") or (ground_type == "grass") )
  return is_good_ground
end


-- Function to start the running sequence before the movement.
function hero_meta:start_running_stopped(command)
  local game = self:get_game()
  local map = game:get_map()
  local hero = game:get_hero()
  local command = command

  -- Do not run if already running.
  if is_hero_running then return end
  
  -- Allow to run only under certain states.
  local hero_state = hero:get_state()
  if hero_state ~= "free" and hero_state ~= "sword swinging"
     and hero_state ~= "sword loading" and hero_state ~= "custom"
  then
    return
  end
  if hero_state == "custom" then
    local state_name = hero:get_state_object():get_description()
    return --if state_name ~= ALLOWED_STATES then return end
  end
  
  -- Allow to jump only on certain grounds.
  local ground_type = map:get_ground(hero:get_ground_position())
  local is_ground_runable = map:is_runable_ground(ground_type)
  local stream = hero:get_controlling_stream()
  local is_blocked_on_stream = stream and (not stream:get_allow_movement())
  if (not is_ground_runable) or is_blocked_on_stream then
    return
  end

  -- Set state properties.
  running_state = "stopped"
  local can_start_moving = false
  hero:start_state(state)

  -- Timer to check if the command button is being pressed enough time to use the boots.
  moving_timer = sol.timer.start(map, 1000, function()
    can_start_moving = true
  end)
  -- Timer for ground effects.
  ground_effect_timer = sol.timer.start(map, ground_effects_time, function()
    running_manager:create_ground_effect(hero)
    return true
  end)
  -- Timer for sounds.
  sounds_timer = sol.timer.start(map, sounds_time, function()
    running_manager:running_effect(hero)
    return true
  end)
  -- Check if the command button is being pressed enough time to use the boots.
  pressed_timer = sol.timer.start(map, 1, function() 
    if not game:is_command_pressed(command) then
      hero:unfreeze()
      return false
    elseif can_start_moving then
      hero:start_running_movement()
      return false
    end
    return true
  end)
end

-- Create ground effects if necessary.
function running_manager:create_ground_effect(hero)
  -- Get ground type.
  local hero = hero
  local game = hero:get_game()
  local map = game:get_map()
  local x,y,layer = hero:get_position()
  local ground = hero:get_ground_below()
  -- Create ground effect.
  if ground == "deep_water" or ground == "shallow_water" then
    -- If the ground has water, create a splash effect.
    map:create_ground_effect("water_splash", x, y, layer, nil)
  elseif ground == "grass" then
    -- If the ground has grass, create leaves effect.
    map:create_ground_effect("falling_leaves", x, y, layer, nil)
  end
end

-- Start a running sound.
function running_manager:running_effect(hero)
  -- Get ground type.
  local hero = hero
  local ground = hero:get_ground_below()
  -- Create sound effect.
  if ground == "deep_water" or ground == "shallow_water" then
    sol.audio.play_sound(walk_on_water_sound)
  elseif ground == "grass" then
    sol.audio.play_sound(walk_on_grass_sound)
  else 
    sol.audio.play_sound(running_sound)
  end
end

-- Function to start the running movement.
function hero_meta:start_running_movement()
  local hero = self
  local map = hero:get_map()
  local game = hero:get_game()
  local dir = hero:get_direction()
  local dirs = {[0]="right",[1]="up",[2]="left",[3]="down"}
  local command_dir = dirs[dir] -- Current direction.
  -- Restart state. Necessary if running_stopped is skipped.
  if not running_state then hero:start_state(state) end
  running_state = "moving"  
  -- Create movement and check for collisions with walls.
  local m = sol.movement.create("straight")
  movement = m -- Save movement in local variable of the script.
  m:set_speed(speed)
  m:set_angle(dir*math.pi/2)
  m:set_smooth(true)
  function m:on_obstacle_reached()
    running_manager:smash_wall(hero)
    return  
  end
  m:start(hero)
  -- Check for commands pressed to interrupt movement or use weapons.
  local is_using_other_item = false
  direction_timer = sol.timer.start(map, 1, function()
    -- Stop movement if some direction command (different from 
    -- the current direction) is pressed.
    local interrupt = false
    for _,str_dir in pairs(dirs) do
      interrupt = interrupt or 
        (game:is_command_pressed(str_dir) and command_dir ~= str_dir)
    end
    if interrupt then
      m:stop()
      hero:unfreeze()
      return false
    end   
    -- Keep checking.
    return true
  end)
end

-- Clean timers.
function running_manager:clean_timers()
  -- Destroy ground effect timer.
  if ground_effect_timer then 
    ground_effect_timer:stop()
    ground_effect_timer = nil
  end
  -- Destroy sound timer.
  if sounds_timer then
    sounds_timer:stop()
    sounds_timer = nil
  end
  -- Destroy moving timer.
  if moving_timer then
    moving_timer:stop()
    moving_timer = nil
  end
  -- Destroy pressed timer.
  if pressed_timer then
    pressed_timer:stop()
    pressed_timer = nil
  end
  -- Destroy direction timer.
  if direction_timer then
    direction_timer:stop()
    direction_timer = nil
  end
end

-- Function for the crash effect against walls.
function running_manager:smash_wall(hero)
  -- Crash animation and sound.
  local hero = hero
  sol.audio.play_sound(running_obstacle_sound)
  hero:set_animation("hurt")
  
  -- Call collision events of entities when the hero crashes against them.
  local map = hero:get_map()
  for e in map:get_entities_in_rectangle(hero:get_bounding_box()) do
    if hero:overlaps(e, "facing") then
      if e.on_boots_crash ~= nil then
        e:on_boots_crash()
      end
    end
  end
  
  -- Create bounce movement.
  local dir = hero:get_direction()
  dir = (dir+2)%4
  local m = sol.movement.create("straight")
  m:set_speed(75)
  m:set_angle(dir*math.pi/2)
  m:set_smooth(true)
  m:set_max_distance(12)
  m:start(hero)
  function m:on_obstacle_reached()
    hero:unfreeze()
  end
  function m:on_finished()
    hero:unfreeze()
  end
end
