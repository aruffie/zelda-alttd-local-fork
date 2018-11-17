-- Custom runjump script.
require("scripts/multi_events")
require("scripts/ground_effects")
require("scripts/states/run")
require("scripts/states/jump")
local hero_meta = sol.main.get_metatable("hero")
local map_meta = sol.main.get_metatable("map")
local game_meta = sol.main.get_metatable("game")
local runjump_manager = {}
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
  
  -- Shift the sprite during the jump. Use a parabolic trajectory.
  local instant = 0
  sol.timer.start(self, 1, function()
    local tn = instant/jump_duration
    local height = math.floor(4*max_height*tn*(1-tn))
    hero:get_sprite():set_xy(0, -height)
    -- Continue shifting while jumping.
    instant = instant+1
    if hero:is_jumping() then return true end
  end)
  
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
        
    -- Finish the jump.
    hero:unfreeze()
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
