local item = ...

require("scripts/multi_events")
require("scripts/ground_effects")
require("scripts/maps/control_manager")
local hero_meta = sol.main.get_metatable("hero")

-- Initialize parameters for custom jump.
local is_hero_jumping = false
local jump_duration = 430 -- Duration of jump in milliseconds.
local max_height_normal = 16 -- Default height, do NOT change!
local max_height_sideview = 20 -- Default height for sideview maps, do NOT change!
local max_height -- Height of jump in pixels.
local max_distance = 31 -- Max distance of jump in pixels.
local jumping_speed = math.floor(1000 * max_distance / jump_duration)

-- Set properties.
function item:on_created()

  item:set_savegame_variable("possession_feather")
  item:set_sound_when_brandished("treasure_2")
  item:set_assignable(true)
end

-- Define event for the use the item.
function item:on_using()
  -- TODO: check conditions of use here.
  -- Start the jump.
  item:start_jump()
end

-- Used to detect if custom jump is being used.
-- Necessary to determine if other items can be used.
function item:is_jumping() return is_hero_jumping end
function hero_meta:is_jumping()
  return self:get_game():get_item("feather"):is_jumping()
end

-- Function to determine if the hero can jump on this type of ground.
function item:is_jumpable_ground(ground_type)
  local game = self:get_game()
  local map = self:get_map()
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
local function blocking_stream_below_hero(map)
  local hero = map:get_hero()
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
function item:start_jump()

  local game = self:get_game()
  local map = self:get_map()
  local hero = map:get_hero()
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
  local is_ground_jumpable = self:is_jumpable_ground(ground_type)
  local is_blocked_on_stream = blocking_stream_below_hero(map)

  if is_hero_frozen or is_hero_jumping or is_hero_builtin_jumping or is_hero_carrying
    or (not is_ground_jumpable) or is_blocked_on_stream or is_on_stairs then
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
  sol.audio.play_sound("jump")
  -- Save last stable position.
  hero:save_solid_ground(hero:get_last_stable_position())
  -- Prepare and start control menu.
  local control_menu = game:create_control_menu()
  control_menu:set_fixed_animations("jumping", "jumping")
  control_menu:set_speed(jumping_speed)
  control_menu:start(hero)

  -- If the map NOT sideview, prepare ground below .
  local tile -- Custom entity used to modify the ground and show the shadow.
  if not is_sideview_map then
    -- Create shadow platform with traversable ground that follows the hero under him.
    local x, y, layer = hero:get_position()
    local platform_properties = {x=x,y=y,layer=layer,direction=0,width=8,height=8}
    tile = map:create_custom_entity(platform_properties)
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
  end


  -- Create parabolic trajectory.
  local instant = 0
  -- If the map NOT sideview, shift all sprites during jump with parabolic trajectory.
  -- We use a parametrization of the height.
  if not is_sideview_map then
    sol.timer.start(item, 1, function()
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
    sol.timer.start(item, 1, function()
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
  sol.timer.start(item, jump_duration, function()

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
      local is_good_ground = self:is_jumpable_ground(ground_type)
      if is_good_ground then
        hero:reset_solid_ground()
        if hero.initialize_unstable_floor_manager then hero:initialize_unstable_floor_manager() end
        return false
      end
      return true
    end)   

    -- Finish jump.
    sol.timer.stop_all(item)
    control_menu:stop()
    is_hero_jumping = false
    item:set_finished()
  end)

end
