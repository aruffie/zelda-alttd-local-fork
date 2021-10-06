--[[
Sideview manager

This script implements gravity and interaction of the hero with ladders, which are used in sideview maps.

To initialize, just require it in a game setup script, like features.lua, 
   then call map:set_sidewiew(true) in the on_started event of each map you want to be in sideview mode.
   
If you need to make things jump like the hero when he uses the feather, then simply do <your_entity>.vspeed=<some_negative_number>, then the gravity will do the rest.

In the same way, you can make any entity be affected by gravity by adding "has_gravity" in its custom properties.
--]]

local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
local game_meta = sol.main.get_metatable("game")
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local swimming_manager = require("scripts/swimming_manager")
local walking_speed = 88
local ladder_speed = 52
local gravity = 0.2
local max_vspeed = 2

--[[
  Returns whether the ground at given XY coordinates is a ladder.
  This is actually a shortcut to avoid multiples instances of "map:get_ground(x,y, layer)=="ladder" in tests.
  Parameters : 
   map, the map object
   x,y, the corrdinates of the point to test
--]]
local function is_ladder(map, x, y)
  
  for entity in map:get_entities_in_rectangle(x, y, 1, 1) do
    if entity:get_type() == "custom_entity" and entity:get_model() == "ladder" then
      return true
    end
  end

  return false
end

--[[
  Sets whether we are in sideview mode in the current map.
  Parameter: enabled (boolean or nil).
--]]
function map_meta.set_sideview(map, enabled)
  map.sideview = enabled or false
end

--[[
  Returns whether the current map is in sideview mode.
--]]
function map_meta.is_sideview(map)
  return map.sideview or false
end

--[[
  Sets the vertical speed on the entity, in pixels/frame.
  Parameter: vspeed, the new vertical speed.
--]]
function map_meta.set_vspeed(entity, vspeed)
  entity.vspeed = vspeed
end

--[[
  Returns whether the current vertical speed of the entity, in pixels/frame.
--]]
function map_meta.get_vspeed(entity)
  return entity.vspeed or 0
end

--[[
  Checks if the ground under the top-middle or the bottom-middle points of the bounding box of a given entity is a ladder.
  Returns : xhether a ladder was detected
--]]
local function check_for_ladder(entity)

  local map = entity:get_map()
  local x, y = entity:get_position() 
  return is_ladder(map, x, y - 2) or is_ladder(map, x, y + 2)
end

local function is_on_ground(entity, dy)
  dy = dy or 0
  local x,y, layer = entity:get_position()
  return entity:test_obstacles(0, 1) or not check_for_ladder(entity) and is_ladder(entity:get_map(), x, y + 3)
end

-- Check if an enemy sensible to jump is overlapping the hero, then hurt it and bounce.
local function on_bounce_possible(entity)

  local map = entity:get_map()
  local hero = map:get_hero()
  for enemy in map:get_entities_by_type("enemy") do
    if hero:overlaps(enemy, "overlapping") and enemy:get_life() > 0 and not enemy:is_immobilized() then
      local reaction = enemy:get_jump_on_reaction()
      if reaction ~= "ignored" then
        enemy:receive_attack_consequence("jump_on", reaction)
        entity.vspeed = 0 - math.abs(entity.vspeed)
      end
    end
  end
  return entity.vspeed or 0
end

--[[
  This is the core function of the side views : 
  it applies a semi-realistic gravity to the given entity, and resets the vertical speed if :
    we reached a solid obstacle,
    we laanded on top of a ladder
    Parameter : entity, the entity to apply the gravity on.
--]]
local function apply_gravity(entity)
  local x, y, layer = entity:get_position()
  local map = entity:get_map()
  local w, h = map:get_size()

  -- Update the vertical speed.
  local vspeed = entity.vspeed or 0 
  if vspeed > 0 then
    vspeed = on_bounce_possible(entity)

    -- Try to apply downwards movement.
    if entity:test_obstacles(0,1) or entity.has_grabbed_ladder or
    not check_for_ladder(entity) and is_ladder(entity:get_map(), x, y + 3) then

      -- We are on an obstacle, reset the speed and bail.
      if entity:get_type()=="hero" and not entity.landing_sound_played then
        entity.landing_sound_played=true
        audio_manager:play_sound("hero/land")
      end
      entity.vspeed = nil
      return false
    end
    entity:set_position(x, y + 1)
  elseif vspeed < 0 then

    -- Try to get up.
    if not entity:test_obstacles(0, -1) then
      entity:set_position(x, y - 1)
    end
  end

  -- Update the vertical speed.
  entity.vspeed = math.min(vspeed + gravity, max_vspeed)

  -- Set the new delay for the timer.
  return math.min(math.floor(10 / math.abs(vspeed)), 100)
end

-- Loop through all entities in the map and tries to enable the gravity timer onto them if they met the requirements.
local function update_entities(map)
 
  for entity in map:get_entities() do
    if entity:is_enabled() then

      -- Check entitites that can fall.
      local is_affected
      local has_property = entity:get_property("has_gravity")
      local e_type = entity:get_type()
      is_affected = e_type == "carried_object" or e_type == "hero" or e_type == "bomb"

      if e_type == "pickable" and entity:get_property("was_created_from_custom_pickable") ~= "true" then
        --convert to custom entity with same properties
        local x, y, layer = entity:get_position()
        local w, h = entity:get_size()
        local ox, oy = entity:get_origin()
        local s=entity:get_sprite()
        local item, variant, savegame_variable=entity:get_treasure()
        local e=map:create_custom_entity({
          x = x,
          y = y,
          layer = layer,
          width = w,
          height = h,
          direction = 0,
          sprite = s:get_animation_set(),
          model = "pickable_underwater",
          properties = {
            {
              key = "has_gravity",
              value = "true",
            },
            {
              key = "treasure_name",
              value = item:get_name(),
            },
            {
              key = "treasure_variant",
              value = tostring(variant),
            },
          },
        })
        if savegame_variable then
          e:set_property({
            key="treasure_savegame_variable",
            value=savegame_variable,
          })
        end
        e:set_origin(ox,oy)
        local sprite = e:get_sprite()
        sprite:set_animation(s:get_animation())
        sprite:set_direction(variant - 1)
        sprite:set_xy(0, 2) -- Shift down the visual.
        entity:remove()
      elseif has_property or is_affected then -- Try to make entity be affected by gravity.
        show_hitbox(entity)
        if entity:get_type() ~= "hero" and not entity.water_processed and not entity.vspeed and entity:test_obstacles(0, 1) and swimming_manager.check_for_water(entity) then
          --Force the entity to get down when in a water pool
          entity.water_processed = true

          sol.timer.start(entity, 50, function()
            entity.water_processed = nil
            local x, y = entity:get_position()
            entity:set_position(x, y + 1)
          end)
        end

        if entity.vspeed and entity.vspeed < 0 or not entity:test_obstacles(0, 2) then
          --Start gravity effect timer loop
          if not entity.gravity_timer then
            if entity:get_type() == "hero" then
              local x, y = entity:get_position()
              if not check_for_ladder(entity) and not is_ladder(map, x, y + 3) then
                entity.landing_sound_played = nil
              end
            end

            entity.gravity_timer = sol.timer.start(entity, 10, function()
              local new_delay = apply_gravity(entity)
              if not new_delay then
                entity.gravity_timer = nil
              end
              return new_delay
            end)
          end
        end
      end
    end
  end
end

--[[
  TODO find a better explanation for this core function
  
  Updates the internal movement of the hero, by reading the currently pressed arrow keys commands.
  This is also where it get attached to the ladder if it is against one by pressing
  
  Then, updates the sprite according to the new parameters
--]]
local function update_hero(hero)

  local movement = hero:get_movement()
  local game = hero:get_game()

  local function command(id)
    return game:is_command_pressed(id)
  end
  local state, cstate = hero:get_state()
  local desc = cstate and cstate:get_description() or ""
  local x, y, layer = hero:get_position()
  local map = game:get_map()
  local speed = 88
  local wanted_angle
  local can_move_vertically = true
  local _left, _right, _up, _down
  local ladder_found = check_for_ladder(hero)

  --------------------
  -- Command inputs --
  --------------------

  if command("up") and not command("down") then
    _up = true
    if ladder_found then --and not check_for_ground(hero) then
      hero.has_grabbed_ladder = true
      if is_ladder(map, x, y) then
        speed = ladder_speed
      end
    else
      can_move_vertically = false
    end
  elseif command("down") and not command("up") then
    _down = true
    if ladder_found or is_ladder(map, x, y + 3) then
      hero.has_grabbed_ladder = true
      if is_ladder(map, x, y) then
        speed = ladder_speed
      end
    else
      can_move_vertically = false
    end
  end

  -- Check if we are on the top of a ladder
  if not (ladder_found or is_ladder(map, x, y + 3)) then
    hero.has_grabbed_ladder = false
  end

  if command("right") and not command("left") then
    _right = true
    wanted_angle = 0
    speed = walking_speed

  elseif command("left") and not command("right") then
    _left = true
    speed = walking_speed
    wanted_angle = math.pi
  end

  -- Force the hero on a ladder if we came from the side
  if hero:test_obstacles(0, 1) and check_for_ladder(hero) and is_ladder(map, x, y + 3) then
    hero.is_jumping = nil
    hero.has_grabbed_ladder = true
  end

  -- Handle movement for vertical and/or diagonal input
  if not can_move_vertically then

    if movement then
      local angle = movement:get_angle()
      if _up then
        if _left or _right then
          if wanted_angle ~= angle then 
            movement:set_angle(wanted_angle)
          end
        else
          speed = 0
        end
      elseif _down then
        if _left or _right then
          movement:set_angle(wanted_angle)
          if wanted_angle ~= angle then 
            movement:set_angle(wanted_angle)
          end
        else
          speed = 0
        end
      end
    end
  end

  if speed and speed ~= hero:get_walking_speed() then
    hero:set_walking_speed(speed)
  end

  ----------------
  -- Animations --
  ----------------

  speed = movement and movement:get_speed() or 0
  local sprite = hero:get_sprite("tunic")
  local direction = sprite:get_direction()
  local new_animation

  if state == "swimming" or desc=="sideview_swim" then
    if speed ~= 0 then
      new_animation = "swimming_scroll"
    else
      new_animation = "stopped_swimming_scroll"
    end
  end

  if state == "lifting" then
    new_animation = "lifting_heavy"
  end

  if state=="free" and not (hero.frozen) then
    if hero.has_grabbed_ladder and check_for_ladder(hero) then
      new_animation = speed == 0 and "climbing_stopped" or "climbing_walking"
    elseif not is_on_ground(hero) then
      new_animation = "jumping"
    else
      new_animation = speed == 0 and "stopped" or "walking" 
    end 
  end

  if new_animation and new_animation ~= sprite:get_animation() then
    sprite:set_animation(new_animation)
  end
end


-- Redeclaration of the "on map changed' event to take account of the sideview mode.
-- This override starts the routine which updates the gravity of the entitites for sideviews, and sets up the sprite of the hero by shifting it by 2 pixels when in sideviews.
game_meta:register_event("on_map_changed", function(game, map)

  local hero = map:get_hero()
  hero.vspeed = 0

  if map:is_sideview() then
    hero.land_sound_played=true -- Don't play landing sound at the start of the map
    hero.has_grabbed_ladder = check_for_ladder(hero, -1) 
    if hero.has_grabbed_ladder then
      hero:set_walking_speed(ladder_speed)
    end
    sol.timer.start(map, 10, function()
      update_entities(map)
      return true
    end)
  else
    hero:set_walking_speed(88)
  end
end)

-- Manage the hero respawn.
hero_meta:register_event("on_position_changed", function(hero, x, y, layer)

  local map = hero:get_map()
  if map:is_sideview() then
    local w, h = map:get_size()

    --Respawn wnen falling into a pit
    if y + 3 >= h then
      hero:set_position(hero:get_solid_ground_position())
      hero:start_hurt(1)
    end
    
    --save last stable ground
    if y+2<h and hero:test_obstacles(0, 1) and map:get_ground(x,y+3,layer) == "wall" and hero:get_ground_below() ~= "prickles" then
      hero:save_solid_ground(x,y,layer)
    end
  end
end)

-- Start the sideview passive behavior if needed on hero state changed.
hero_meta:register_event("on_state_changed", function(hero, state)

  local game = hero:get_game()
  local map = hero:get_map()

  if map:is_sideview() then
    if state == "free" or state == "carrying" or state == "sword loading"
    or state == "swimming" or state == "custom" then --TODO identify every applicable states

      -- Start swimming if touching deep water.
      if state == "swimming" or state =="free" and map:get_ground(hero:get_position())=="deep_water" then
        hero:start_swimming()
      end
      if hero.timer == nil then
        hero.timer = sol.timer.start(hero, 10, function()
          update_hero(hero) 
          return true
        end)
      end
    elseif state == "grabbing" then -- Prevent the hero from pulling things in sideview mode.
      hero:unfreeze()
    end
    return
  end

  local timer = hero.timer
  if timer then
    timer:stop()
    hero.timer = nil
  end
end)