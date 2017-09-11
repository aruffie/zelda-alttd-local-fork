local item = ...

local hero_meta = sol.main.get_metatable("hero")

-- Initialize parameters for custom jump.
local is_hero_jumping = false
local jump_duration = 600 -- Duration of jump in milliseconds.
local max_height = 16 -- Height of jump in pixels.
local max_distance = 31 -- Max distance of jump in pixels.
local jumping_speed = math.floor(1000 * max_distance / jump_duration)

function item:on_created()
  self:set_savegame_variable("possession_feather")
  self:set_assignable(true)
  self:set_sound_when_brandished("treasure_2")
end

function item:on_using()
  local hero = self:get_game():get_hero()
  if item:get_variant() == 0 then -- Built-in jump.
    sol.audio.play_sound("jump")
    local direction4 = hero:get_direction()
    hero:start_jumping(direction4 * 2, 32, false)
    self:set_finished()
  else -- Custom jump.
    hero:start_custom_jump()
  end
end

-- Used to detect if custom jump is being used.
-- Necessary to determine if other items can be used.
function hero_meta:is_jumping()
  return is_hero_jumping
end

-- Function to determine if the hero can jump on this type of ground.
local function is_jumpable_ground(ground_type)
  return (
    (ground_type == "traversable")
    or (ground_type == "wall_top_right") or (ground_type == "wall_top_left")
    or (ground_type == "wall_bottom_left") or (ground_type == "wall_bottom_right")
    or (ground_type == "shallow_water") or (ground_type == "grass")
    or (ground_type == "ice")
  )
end

-- Define custom jump on hero metatable.
function hero_meta:start_custom_jump()

  local hero = self
  local game = self:get_game()
  local map = self:get_map()
  local item = game:get_item("feather")

  -- Do nothing if the hero is frozen, carrying, "custom jumping",
  -- or if there is bad ground below. [Add more restrictions if necessary.]
  local hero_state = hero:get_state()
  local is_hero_frozen = hero_state == "frozen"
  local is_hero_carrying = hero_state == "carrying"
  local ground_type = map:get_ground(hero:get_position())
  local is_ground_jumpable = is_jumpable_ground(ground_type)

  if is_hero_frozen or is_hero_jumping or is_hero_carrying or (not is_ground_jumpable) then
    return
  end

  -- Prepare hero for jump.
  hero:unfreeze()  
  is_hero_jumping = true
  hero:save_solid_ground(hero:get_position()) -- Save solid position.
  local ws = hero:get_walking_speed() -- Default walking speed.
  hero:set_walking_speed(jumping_speed)
  hero:set_invincible(true, jump_duration)
  sol.audio.play_sound("jump")
 
  -- Change and fix tunic animations to display the jump.
  local state = hero:get_state()
  if state == "free" then
    hero:set_fixed_animations("jumping", "jumping")
    hero:set_animation("jumping")
  elseif state == "sword loading" then
    hero:set_fixed_animations("sword_loading_stopped", "sword_loading_stopped")
  elseif state == "sword spin attack" then
    hero:set_fixed_animations("spin_attack", "spin_attack")
  end

  -- Create shadow platform with traversable ground that follows the hero under him.
  local x, y, layer = hero:get_position()
  local platform_properties = {x=x,y=y,layer=layer,direction=0,width=8,height=8}
  local tile = map:create_custom_entity(platform_properties)
  tile:set_origin(4, 4)
  tile:set_modified_ground("traversable")
  local sprite = tile:create_sprite("shadows/shadow_big_dynamic")
  local nb_frames = sprite:get_num_frames()
  local frame_delay = math.floor(jump_duration/nb_frames)
  sprite:set_frame_delay(frame_delay)
  -- Shadow platform has to follow the hero.
  sol.timer.start(tile, 1, function()
    tile:set_position(hero:get_position())
    return true
  end)

  -- Shift all sprites during jump with parabolic trajectory.
  local instant = 0
  sol.timer.start(self, 1, function()
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

  -- Finish the jump.
  sol.timer.start(item, jump_duration, function()
    hero:set_walking_speed(ws) -- Restore initial walking speed.
    hero:set_fixed_animations(nil, nil) -- Restore tunic animations.
    tile:remove()  -- Delete shadow platform tile.
    -- If ground is empty, move hero to lower layer.
    local x,y,layer = hero:get_position()
    local ground = map:get_ground(hero:get_position())
    local min_layer = map:get_min_layer()
    while ground == "empty" and layer > min_layer do
      layer = layer-1
      hero:set_position(x,y,layer)
      ground = map:get_ground(hero:get_position())    
    end
    -- Reset sprite shifts.
    for _, s in hero:get_sprites() do s:set_xy(0, 0) end
    
    -- Create ground effect.
    -- item:create_ground_effect(x, y, layer)

    -- Restore solid ground as soon as possible.
    sol.timer.start(self, 1, function()
      local ground_type = map:get_ground(hero:get_position())    
      local is_good_ground = is_jumpable_ground(ground_type)
      if is_good_ground then
        hero:reset_solid_ground()
        return false
      end
      return true
    end)   

    -- Finish jump.
    is_hero_jumping = false
    item:set_finished()
  end)
end

-- Create ground effects for hero landing after jump.
-- TODO: DELETE THIS FUNCTION AND USE THE ONE IN "SCRIPTS/GROUND_EFFECTS.LUA"
function item:create_ground_effect(x, y, layer)

  local map = item:get_map()
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
