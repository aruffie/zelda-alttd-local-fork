-- Custom runjump script.
require("scripts/multi_events")
require("scripts/ground_effects")
require("scripts/states/run")
require("scripts/states/jump")
local hero_meta = sol.main.get_metatable("hero")
local map_meta = sol.main.get_metatable("map")
local game_meta = sol.main.get_metatable("game")
local runjump_manager = {}
local sprites_info = {} -- Used to restore some properties when the state is changed.
-- Sounds:
local running_obstacle_sound = "running_obstacle"
local jumping_sound = "jump"
-- Parameters:
local movement
local jump_duration = 500 -- Change this for duration of the runjump.
local max_height = 16 -- Height of the jump in pixels.
local speed = 130 -- Walking speed during the runjump.

-- Initialize runjump state.
local state = sol.state.create()
state:set_description("runjump")
state:set_can_control_movement(false)
state:set_can_control_direction(false)
state:set_gravity_enabled(false)
state:set_can_come_from_bad_ground(false)
state:set_can_be_hurt(false)
state:set_can_push(false)
state:set_can_pick_treasure(false)
state:set_can_use_stairs(false)
state:set_can_use_jumper(false)
state:set_can_use_stairs(false)
state:set_can_traverse("stairs", false)
state:set_affected_by_ground("hole", false) 
state:set_affected_by_ground("lava", false) 
state:set_affected_by_ground("deep_water", false)


function state:on_started(previous_state_name, previous_state)
  local psn = previous_state_name
  local hero = state:get_game():get_hero()
  local hero_sprite = hero:get_sprite()
  local sword_sprite = hero:get_sprite("sword")
  -- Change tunic animations during the run-jump.
  hero_sprite:set_animation("jumping")
  -- Change run/jump state variables.
  hero:set_running(true)
  hero:set_jumping(true)
end

function state:on_finished(next_state_name, next_state)
  local hero = state:get_game():get_hero()
  -- Change run/jump state variables.
  hero:set_running(false)
  hero:set_jumping(false)
  if movement then
    movement:stop()
    movement = nil
  end
end

function state:on_command_pressed(command)  
  local game = state:get_game()
  local hero = game:get_hero()
  if command == "attack" then
  -- Do not stop movement of the hero if sword is used during a jump.
    if game:has_ability("sword") then
      state:set_can_control_direction(false)
      local tunic_sprite = hero:get_sprite("tunic")
      local dir = tunic_sprite:get_direction()
      local sword_sprite = hero:get_sprite("sword")
      tunic_sprite:set_animation("sword")
      sword_sprite:set_animation("sword")
      sword_sprite:set_direction(dir)
      return true
    end
  end
end


function state:on_command_released(command)
end


-- Finish jumping state.
function state:set_finished()
  -- If the hero is using the sword, keep it after the jump.
  local hero = state:get_game():get_hero()
  local hero_sprite = hero:get_sprite()
  local sword_sprite = hero:get_sprite("sword")
  if sword_sprite:is_animation_started() then
    -- Stop hero movement with a sword attack if sword was used during the jump.
    local sword_animation = sword_sprite:get_animation()
    if sword_animation == "sword" or sword_animation == "spin_attack" then
      hero:start_attack()
    else -- Sword loading. The hero should not be frozen.
      hero:unfreeze()
    end
    hero_sprite:set_animation(sprites_info["tunic"].animation)
    sword_sprite:set_animation(sprites_info["sword"].animation)
    hero_sprite:set_frame(sprites_info["tunic"].frame)
    sword_sprite:set_frame(sprites_info["sword"].frame)
  else
    hero:unfreeze()
  end
end
 
function state:update_sprites_info(hero)
  -- Save sprites info before changing state.
  sprites_info = {}
  --local hero = state:get_game():get_hero()
  for sprite_name, sprite in hero:get_sprites() do
    local info = {}
    sprites_info[sprite_name] = info
    info.animation = sprite:get_animation()
    info.frame = sprite:get_frame()
  end
end


-- Function to start the running movement.
function runjump_manager:start_runjump_movement(hero)
  -- Create movement and check for collisions with walls.
  local hero = hero
  local m = sol.movement.create("straight")
  local dir = hero:get_direction()
  movement = m -- Save movement in local variable of the script.
  m:set_speed(speed)
  m:set_angle(dir*math.pi/2)
  m:set_smooth(true)
  function m:on_obstacle_reached()
    runjump_manager:smash_wall(hero)
    return  
  end
  m:start(hero)
end

-- Start jump while running.
function hero_meta:start_runjump()
  local hero = self
  local game = hero:get_game()
  local map = hero:get_map()
  local is_sideview_map = map.is_side_view and map:is_side_view()
  
  -- Do not runjump if the hero is not moving (i.e., "running stopped").
  if not hero:is_walking() then return end
  
  -- Allow to jump only under certain states.
  local hero_state = hero:get_state()
  if hero_state ~= "custom" then
    return
  end
  if hero_state == "custom" then
    local state_name = hero:get_state_object():get_description()
    if state_name ~= "run" then
      return --if state_name ~= ALLOWED_STATES then return end
    end
  end

  -- Allow to jump only on certain grounds.
  local ground_type = map:get_ground(hero:get_ground_position())
  local is_ground_jumpable = map:is_jumpable_ground(ground_type)
  local stream = hero:get_controlling_stream()
  local is_blocked_on_stream = stream and (not stream:get_allow_movement())
  if (not is_ground_jumpable) or is_blocked_on_stream then
    return
  end

  -- We need solid ground or ladder "below" to jump in sideview maps!
  if is_sideview_map then
    local x, y, layer = hero:get_position()
    local is_grabbed_to_ladder = map:get_ground(x, y - 4, layer) == "ladder"
        or map:get_ground(x, y + 3, layer) == "ladder"
    if (not hero:test_obstacles(0, 1) and (not is_grabbed_to_ladder)) then return end
  end

  -- Play jump sound.
  sol.audio.play_sound(jumping_sound)
  -- Start jumping state.
  hero:start_state(state)
  -- Start runjump movement.
  runjump_manager:start_runjump_movement(hero)
  
  -- Create shadow that follows the hero under him.
  local x,y,layer = hero:get_position()
  local tile = map:create_custom_entity({x=x,y=y,layer=layer,direction=0,width=8,height=8})
  tile:set_origin(4, 4)
  local sprite = tile:create_sprite("shadows/shadow_big_dynamic")
  local nb_frames = 32 -- Number of frames of the current animation.
  local frame_delay = jump_duration/nb_frames
  sprite:set_animation("walking")
  sprite:set_frame_delay(frame_delay) 
  function tile:on_update() tile:set_position(hero:get_position()) end -- Follow the hero.

  -- Create parabolic trajectory.
  local instant = 0
  -- If the map NOT sideview, shift all sprites during jump with parabolic trajectory.
  -- We use a parametrization of the height.
  if not is_sideview_map then
    sol.timer.start(map, 1, function()
      if not hero:is_jumping() then return false end
      local tn = instant/jump_duration
      local height = math.floor(4*max_height*tn*(1-tn))
      for _, s in hero:get_sprites() do
        s:set_xy(0, -height)
      end
      -- Continue shifting while jumping.
      instant = instant + 1
      return true
    end)
  end
  -- If the map IS sideview, shift the position with parabolic trajectory.
  -- We calculate the variations of height at each instant.
  if is_sideview_map then
    local d = 0 -- Accumulative decimal part, for better accuracy.
    local pheight = 0 -- Previous height.
    sol.timer.start(map, 1, function()
      if not hero:is_jumping() then return false end
      local x, y, layer = hero:get_position()
      local tn = instant/jump_duration
      local height = 4*max_height*tn*(1-tn)
      local dh = (height - pheight) + d -- Variation of height.
      d = dh - math.floor(dh)
      dh = math.floor(dh)
      pheight = height
      if not hero:test_obstacles(0, -dh) then
        hero:set_position(x, y - dh, layer)
      end
      -- Continue shifting while jumping.
      instant = instant + 1
      return true
    end)
  end 
  
  -- Finish the jump.
  sol.timer.start(self, jump_duration, function()
  
    tile:remove()    
    -- If ground is empty, move hero to lower layer.
    local x,y,layer = hero:get_position()
    local ground = hero:get_ground_below()
    local min_layer = map:get_min_layer()
    while ground == "empty" and layer > min_layer do
      layer = layer-1
      hero:set_position(x,y,layer)
      ground = hero:get_ground_below() 
    end
    
    -- Create ground effect.
    map:ground_collision(hero)
     
    -- Finish jump.
    state:update_sprites_info(hero)
    state:set_finished() -- Finish jumping state.
  end)
end

-- Function for the crash effect against walls.
function runjump_manager:smash_wall(hero)
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
end
