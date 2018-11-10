-- Custom jump script.

require("scripts/multi_events")
require("scripts/ground_effects")
require("scripts/maps/unstable_floor_manager.lua")
local hero_meta = sol.main.get_metatable("hero")
local map_meta = sol.main.get_metatable("map")
local game_meta = sol.main.get_metatable("game")

-- Initialize parameters for custom jump.
local is_hero_jumping
local jump_duration = 430 -- Duration of jump in milliseconds.
local max_height_normal = 16 -- Default height, do NOT change!
local max_height_sideview = 20 -- Default height for sideview maps, do NOT change!
local max_height -- Height of jump in pixels.
local max_distance = 31 -- Max distance of jump in pixels.
local jumping_speed = math.floor(1000 * max_distance / jump_duration)
local sprites_info = {} -- Used to restore some properties when the state is changed.

function hero_meta:is_jumping()
  return is_hero_jumping
end

-- Restart variables.
game_meta:register_event("on_started", function(game)
  is_hero_jumping = false
end)

-- Initialize jumping state.
local state = sol.state.create()
state:set_affected_by_ground("hole", false) --state:set_touching_ground(false)
state:set_can_use_stairs(false)
--state:set_can_traverse("stairs", false)

function state:on_started(previous_state_name, previous_state)

  local psn = previous_state_name
  local hero = state:get_game():get_hero()
  local hero_sprite = hero:get_sprite()
  local sword_sprite = hero:get_sprite("sword")
  -- Change tunic animations during the jump.
  if psn == "free" then
    hero_sprite:set_animation("jumping")
  elseif psn == "sword loading"
      or psn == "sword spin attack"
      or psn == "sword swinging"
      then
    local callback = function()
      hero_sprite:set_animation("jumping")
      sword_sprite:stop_animation()
      state:set_can_control_direction(true)
    end
    state:set_can_control_direction(false)
    hero_sprite:set_animation(sprites_info["tunic"].animation, callback)
    sword_sprite:set_animation(sprites_info["sword"].animation)
    hero_sprite:set_frame(sprites_info["tunic"].frame)
    sword_sprite:set_frame(sprites_info["sword"].frame)
  end
end

function state:on_finished(next_state_name, next_state)
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
  local game = state:get_game()
  local hero = game:get_hero()
  if command == "attack" then
  -- Release spin attacks during jumps too, without stopping the movement.
    if game:has_ability("sword") then
      local tunic_sprite = hero:get_sprite("tunic")
      local dir = tunic_sprite:get_direction()
      local sword_sprite = hero:get_sprite("sword")
      local sword_animation = sword_sprite:get_animation()
      if sword_animation == "sword_loading_stopped"
          or sword_animation == "sword_loading_walking" then
        tunic_sprite:set_animation("spin_attack")
        sword_sprite:set_animation("spin_attack")
        sword_sprite:set_direction(dir)
        return true
      end
    end
  end
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

-- Determine if the hero can jump on this type of ground.
function map_meta:is_jumpable_ground(ground_type)
  local map = self
  if map.is_side_view ~= nil and map:is_side_view() then
    local is_good_ground = ( (ground_type == "traversable")
      or (ground_type == "wall_top_right") or (ground_type == "wall_top_left")
      or (ground_type == "wall_bottom_left") or (ground_type == "wall_bottom_right")
      or (ground_type == "shallow_water") or (ground_type == "grass")
      or (ground_type == "ice")  or (ground_type == "ladder") )
    return is_good_ground
  else
    local is_good_ground = ( (ground_type == "traversable")
      or (ground_type == "wall_top_right") or (ground_type == "wall_top_left")
      or (ground_type == "wall_bottom_left") or (ground_type == "wall_bottom_right")
      or (ground_type == "shallow_water") or (ground_type == "grass")
      or (ground_type == "ice") )
    return is_good_ground
  end
end

-- Returns true if there are "blocking streams" below the hero.
function hero_meta:is_blocked_on_stream()
  local hero = self
  local map = hero:get_map()
  local x, y, _ = hero:get_position()
  for e in map:get_entities_in_rectangle(x, y, 1 , 1) do
    if e:get_type() == "stream" then
      return (not e:get_allow_movement())
    end
  end
  return false
end


-- MAIN FUNCTION.
-- Define custom jump on hero metatable.
function hero_meta:start_custom_jump()
  local hero = self
  local game = self:get_game()
  local map = self:get_map()
  local is_sideview_map = map.is_side_view ~= nil and map:is_side_view()
   -- Select Max height.
  if is_sideview_map then max_height = max_height_sideview
  else max_height = max_height_normal end

  -- Do nothing if the hero is frozen, carrying, jumping, "custom jumping",
  -- or if there is bad ground below. [Add more restrictions if necessary.]
  local hero_state = hero:get_state()
  local is_hero_frozen = hero_state == "frozen"
  local is_hero_carrying = hero_state == "carrying"
  local is_hero_builtin_jumping = hero_state == "jumping"
  local is_on_stairs = hero_state == "stairs"
  local ground_type = map:get_ground(hero:get_ground_position())
  local is_ground_jumpable = map:is_jumpable_ground(ground_type)
  local is_blocked_on_stream = hero:is_blocked_on_stream()

  if is_hero_frozen or is_hero_jumping or is_hero_builtin_jumping or is_hero_carrying
    or is_using_shield or (not is_ground_jumpable) or is_blocked_on_stream 
    or is_on_stairs then
    return
  end

  -- We need solid ground or ladder "below" to jump in sideview maps!
  if is_sideview_map then
    local x, y, layer = hero:get_position()
    local is_grabbed_to_ladder = map:get_ground(x, y - 4, layer) == "ladder"
        or map:get_ground(x, y + 3, layer) == "ladder"
    if (not hero:test_obstacles(0, 1) and (not is_grabbed_to_ladder)) then return end
  end

  -- Prepare hero for jump.
  is_hero_jumping = true
  hero:save_solid_ground(hero:get_last_stable_position()) -- Save last stable position.
  local ws = hero:get_walking_speed() -- Default walking speed.
  hero:set_walking_speed(jumping_speed)
  hero:set_invincible(true, jump_duration)
  sol.audio.play_sound("jump")

  -- Save sprites info before changing state.
  state:update_sprites_info(hero)
  hero:start_state(state) -- Start jumping state.

  -- If the map NOT sideview, prepare ground below .
  local tile -- Custom entity used to modify the ground and show the shadow.
  if not is_sideview_map then
    -- Create shadow platform with traversable ground that follows the hero under him.
    local x, y, layer = hero:get_position()
    local platform_properties = {x=x,y=y,layer=layer,direction=0,width=8,height=8}
    tile = map:create_custom_entity(platform_properties)
    tile:set_origin(4, 4)
    local sprite = tile:create_sprite("shadows/shadow_big_dynamic")
    local nb_frames = sprite:get_num_frames()
    local frame_delay = math.floor(jump_duration/nb_frames)
    sprite:set_frame_delay(frame_delay)
    -- Shadow platform has to follow the hero.
    sol.timer.start(tile, 1, function()
      tile:set_position(hero:get_position())
      return true
    end)
  end


  -- Create parabolic trajectory.
  local instant = 0
  -- If the map NOT sideview, shift all sprites during jump with parabolic trajectory.
  -- We use a parametrization of the height.
  if not is_sideview_map then
    sol.timer.start(map, 1, function()
      if not is_hero_jumping then return false end
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
      if not is_hero_jumping then return false end
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
  local jump_timer = sol.timer.start(map, jump_duration, function()

    hero:set_walking_speed(ws) -- Restore initial walking speed.
    if map.is_side_view == nil or map:is_side_view() == false then
      tile:remove()  -- Delete shadow platform tile.
    end
    -- If ground is empty, move hero to lower layer.
    local x,y,layer = hero:get_position()
    local ground = map:get_ground(hero:get_position())
    local min_layer = map:get_min_layer()
    while ground == "empty" and layer > min_layer do
      layer = layer-1
      hero:set_position(x,y,layer)
      ground = map:get_ground(hero:get_ground_position())    
    end
    -- Reset sprite shifts.
    for _, s in hero:get_sprites() do s:set_xy(0, 0) end

    -- Create ground effect.
    map:ground_collision(hero)
    
    -- Restore solid ground as soon as possible.
    sol.timer.start(map, 1, function()
      local ground_type = map:get_ground(hero:get_ground_position())    
      local is_good_ground = map:is_jumpable_ground(ground_type)
      if is_good_ground then
        hero:reset_solid_ground()
        if hero.initialize_unstable_floor_manager then hero:initialize_unstable_floor_manager() end
        return false
      end
      return true
    end)   

    -- Finish jump.
    is_hero_jumping = false
    state:update_sprites_info(hero)
    state:set_finished() -- Finish jumping state.
  end)
end

-- Create ground effects for hero landing after jump.
-- TODO: DELETE THIS FUNCTION AND USE THE ONE IN "SCRIPTS/GROUND_EFFECTS.LUA"
function map_meta:create_ground_effect(x, y, layer)

  local map = self
  local ground = map:get_ground(x, y, layer)
  if ground == "deep_water" or ground == "shallow_water" then
    -- If the ground has water, create a splash effect.
    map:create_ground_effect("water_splash", x, y, layer, "splash")
  elseif ground == "grass" then
    -- If the ground has grass, create leaves effect.
    map:create_ground_effect("falling_leaves", x, y, layer, "bush")
  else
    -- For other grounds, make landing sound.
    sol.audio.play_sound("hero_lands")      
  end
end