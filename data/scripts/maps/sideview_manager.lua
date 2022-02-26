--[[
Sideview manager

This script implements gravity and interaction of the hero with ladders, which are used in sideview maps.

To initialize, just require it in a game setup script, like features.lua, 
   then call map:set_sidewiew(true) in the on_started event of each map you want to be in sideview mode.
   
If you need to make things jump like the hero when he uses the feather, then simply do <your_entity>.vspeed=<sosv_utils:me_negative_number>, then the gravity will do the rest.

In the same way, you can make any entity be affected by gravity by adding "has_gravity" in its custom properties.
--]]

local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
local game_meta = sol.main.get_metatable("game")
require("scripts/multi_events")
local sv_utils = require("scripts/tools/sideview_utils")
local audio_manager = require("scripts/audio_manager")
local swimming_manager = require("scripts/maps/sideview_swimming_manager")
local walking_speed = 88
local ladder_speed = 52
local gravity = 0.2
local max_vspeed = 2


-- Set the sideview mode flag for the map to the given parameter.
function map_meta.set_sideview(map, enabled)
  map.sideview = enabled or false
end

-- Returns whether the current map is in sideview mode.
function map_meta.is_sideview(map)
  return map.sideview or false
end

-- Set the vertical speed on the entity, in pixels/frame.
function map_meta.set_vspeed(entity, vspeed)
  entity.vspeed = vspeed
end

-- Returns the current vertical speed of the entity, in pixels/frame.
function map_meta.get_vspeed(entity)
  return entity.vspeed or 0
end


-- Applies a semi-realistic gravity to the given entity, and resets the vertical speed if the reached a solid obstacle or is above a ladder
local function update_gravity(entity)

  local x, y, layer = entity:get_position()
  local map = entity:get_map()
  local w, h = map:get_size()

  -- Update the vertical speed.
  local vspeed = entity.vspeed or 0
  if vspeed > 0 then
    vspeed = sv_utils:on_bounce_possible(entity)

    -- Try to apply downwards movement.
    if entity:has_grabbed_ladder or sv_utils:is_above_ladder(entity) then

      -- We are on an obstacle, reset the speed and bail.
      if entity:get_type() == "hero" and not entity.landing_sound_played then
        entity.landing_sound_played = true
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
  if not entity:test_obstacles(0, 1) or vspeed > 0 then
    entity.vspeed = math.min(vspeed + gravity, max_vspeed)
  end

  -- Set the new delay for the timer.
  return vspeed == 0 and 10 or math.min(math.floor(10 / math.abs(vspeed)), 100)
end

-- Try to start the gravity timer on every map entities if they met the requirements.
local function start_gravity(map)
 
  for entity in map:get_entities() do
    if entity:is_enabled() then

      -- Check entitites that can fall.
      local has_property = entity:get_property("has_gravity")
      local e_type = entity:get_type()
      local is_affected = e_type == "carried_object" or e_type == "hero" or e_type == "bomb"

      if e_type == "pickable" and entity:get_property("was_created_from_custom_pickable") ~= "true" then

        -- Convert to custom entity with same properties
        local x, y, layer = entity:get_position()
        local w, h = entity:get_size()
        local ox, oy = entity:get_origin()
        local s = entity:get_sprite()
        local item, variant, savegame_variable = entity:get_treasure()
        local e = map:create_custom_entity({
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
            key = "treasure_savegame_variable",
            value = savegame_variable,
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

        -- Start gravity effect timer loop
        if entity.vspeed and entity.vspeed < 0 or not entity:test_obstacles(0, 2) then
          if not entity.gravity_timer then
            if entity:get_type() == "hero" then
              local x, y = entity:get_position()
              if not sv_utils:is_on_ladder(entity) and not sv_utils:is_position_on_ladder(map, x, y + 3) then
                entity.landing_sound_played = nil
              end
            end

            entity.gravity_timer = sol.timer.start(entity, 10, function()
              local delay
              if not entity:is_swimming() then
                delay = update_gravity(entity)

                -- Start swimming if touching deep water.
                if entity:get_type() == "hero" and swimming_manager:is_in_water(entity) then
                  entity:start_swimming()
                  return false
                end
              end

              return delay or 10
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
  local ladder_found = sv_utils:is_on_ladder(hero)

  --------------------
  -- Command inputs --
  --------------------

  if command("up") and not command("down") then
    _up = true
    if ladder_found then
      hero.has_grabbed_ladder = true
      if sv_utils:is_position_on_ladder(map, x, y) then
        speed = ladder_speed
      end
    else
      can_move_vertically = false
    end
  elseif command("down") and not command("up") then
    _down = true
    if ladder_found or sv_utils:is_position_on_ladder(map, x, y + 3) then
      hero.has_grabbed_ladder = true
      if sv_utils:is_position_on_ladder(map, x, y) then
        speed = ladder_speed
      end
    else
      can_move_vertically = false
    end
  end

  -- Check if we are on the top of a ladder
  if not (ladder_found or sv_utils:is_position_on_ladder(map, x, y + 3)) then
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
  if hero:test_obstacles(0, 1) and sv_utils:is_on_ladder(hero) and sv_utils:is_position_on_ladder(map, x, y + 3) then
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

  if state == "lifting" then
    new_animation = "lifting_heavy"
  end

  if state == "free" and not (hero.frozen) then
    if hero.has_grabbed_ladder and sv_utils:is_on_ladder(hero) then
      new_animation = speed == 0 and "climbing_stopped" or "climbing_walking"
    elseif not sv_utils:is_above_ladder(hero) then
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
    hero.land_sound_played = true -- Don't play landing sound at the start of the map
    hero.has_grabbed_ladder = sv_utils:is_on_ladder(hero, -1) 
    if hero.has_grabbed_ladder then
      hero:set_walking_speed(ladder_speed)
    end
    start_gravity(map)
  else
    hero:set_walking_speed(88)
  end
end)

-- Passive behavior on position changes.
hero_meta:register_event("on_position_changed", function(hero, x, y, layer)

  local map = hero:get_map()
  if map:is_sideview() then
    local w, h = map:get_size()
    
    -- Respawn when falling into a pit
    if y + 3 >= h then
      hero:set_position(hero:get_solid_ground_position())
      hero:start_hurt(1)
    end
    
    -- Save last stable ground
    if y + 2 < h and hero:test_obstacles(0, 1) and map:get_ground(x, y + 3,layer) == "wall" and hero:get_ground_below() ~= "prickles" then
      hero:save_solid_ground(x, y, layer)
    end
  end
end)

-- Start the sideview passive behavior if needed on hero state changed.
hero_meta:register_event("on_state_changed", function(hero, state)

  local game = hero:get_game()
  local map = hero:get_map()

  if map:is_sideview() then
    if state == "free" or state == "carrying" or state == "sword loading" or state == "custom" then --TODO identify every applicable states

      if hero.timer == nil then
        hero.timer = sol.timer.start(hero, 10, function()
          if not hero:is_swimming() then
            update_hero(hero)
          end
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