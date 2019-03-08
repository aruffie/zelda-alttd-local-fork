-- Lua script of custom entity portable.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

----------------------------------
----------------------------------
--
-- This "portable" custom entity is an undestructible solarus destructible, 
-- behaving the same way than solarus destructible except it won't break.
-- 
-- If thrown on an entity that implements it, the entity:hit_by_portable_entity(portable) is called
-- Events : portable:on_finish_throw()
--
----------------------------------
----------------------------------

local portable = ...
local game = portable:get_game()
local map = portable:get_map()
local portable_name = portable:get_name()

-- Default properties for portable entities.
local default_properties = {

  vshift = 0, -- Vertical shift to draw the sprite while lifting/carrying.
  num_bounces = 3, -- Number of bounces when falling (it can be 0).
  bounce_distances = {80, 16, 4}, -- Distances for each bounce.
  bounce_heights = {"same", 4, 2}, -- Heights for each bounce.
  bounce_durations = {400, 160, 70}, -- Duration for each bounce.
  bounce_sound = "bomb", -- Default id of the bouncing sound.
  shadow_type = "normal", -- Type of shadow for the falling trajectory.
  hurt_damage = 2,  -- Damage to enemies.
}

-- Function to fix bug: the hero may get stuck with the portable if it falls over him.
-- Modify ground of the portable with a custom entity above, if necessary.
local function avoid_overlap_with_hero(entity)

  -- Check if this destructible and hero overlap.
  local hero = entity:get_map():get_hero()
  if not hero:overlaps(entity) then
    return -- No overlapping. No need to move the destructible.
  end

  -- There is an overlap. Put the entity in front of hero.
  local x, y, layer = hero:get_position()
  local dir = hero:get_direction()
  local angle = dir * math.pi / 2
  x, y = x + 16 * math.cos(angle), y - 16 * math.sin(angle)
  entity:set_position(x, y, layer)
end

-- Define falling trajectory for the thrown portable
function portable:throw(direction)

  -- Initialize optional arguments and properties.
  local fdir = direction
  local vshift = default_properties.vshift
  local num_bounces = default_properties.num_bounces
  local bounce_distances = default_properties.bounce_distances
  local bounce_heights = default_properties.bounce_heights
  local bounce_durations = default_properties.bounce_durations
  local bounce_sound = default_properties.bounce_sound
  local shadow_type = default_properties.shadow_type
  local hurt_damage = default_properties.hurt_damage
  local current_bounce = 1
  local current_instant = 0
  local sprite = portable:get_sprite()
  local dx, dy = math.cos(fdir * math.pi / 2), -math.sin(fdir * math.pi / 2)
  local is_obstacle_reached = false

  portable:set_traversable_by(true)
  portable:set_direction(fdir)
  sprite:set_xy(0, -22 + vshift)

  -- Hit effects
  function hit_effects(portable, entity)
    if not is_obstacle_reached then
      -- Call the hit_by_portable_entity() function if implemented by the entity
      if entity.hit_by_portable_entity then
        entity:hit_by_portable_entity(portable)
        is_obstacle_reached = true
      end
      -- If the entity is an enemy, hurt it
      if entity:get_type() == "enemy" then
        entity:hurt(hurt_damage)
        is_obstacle_reached = true
      end
      -- Stop the movement if a hit effect is triggered
      if is_obstacle_reached then
        portable:stop_movement()
      end
    end
  end

  -- The collision test has to be setup for both touching and sprite collision mode to handle all cases
  -- Non-traversable entities need the touching collision while sprite collision is needed when entities are not on the same row nor column
  portable:add_collision_test("sprite", hit_effects)
  portable:add_collision_test("touching", hit_effects)

  -- Create a custom_entity for shadow (this one is drawn below).
  local px, py, pz = portable:get_position()
  if shadow_type then
    local shadow_properties = {x = px, y = py, layer = pz, direction = 0, width = 16, height = 16}
    shadow = map:create_custom_entity(shadow_properties)
    if shadow_type == "normal" then
      shadow:create_sprite("entities/shadows/shadow")
      shadow:bring_to_back()
    end
    -- Remove shadow and/or traversable ground when the portable is removed.
    function portable:on_removed() shadow:remove() end
  end

  -- Function called when the portable has fallen.
  function portable:finish_bounce()
    portable:clear_collision_tests()
    portable:set_traversable_by(false)
    avoid_overlap_with_hero(portable) -- Put in front of hero if they overlaps.
    if shadow then
      shadow:remove()
    end
    if portable.on_finish_throw then
      portable:on_finish_throw()
    end
  end
    
  -- Function to bounce when portable is thrown.
  function portable:bounce()
    -- Finish bouncing if we have already done all bounces.
    if current_bounce > num_bounces then 
      portable:finish_bounce()    
      return
    end  
    -- Initialize parameters for the bounce.
	  local x, y, z
    local _, sy = sprite:get_xy()
    local dist = bounce_distances[current_bounce]
    local h = bounce_heights[current_bounce]
    if h == "same" then h = -sy end
    local dur = bounce_durations[current_bounce]  
    local speed = 1000 * dist / dur -- Speed of the straight movement (pixels per second).
    local t = current_instant
    
    -- Function to compute height for each fall (bounce).
    function portable:current_height()
      if current_bounce == 1 then return h * ((t / dur) ^ 2 - 1) end
      return 4 * h * ((t / dur) ^ 2 - t / dur)
    end
    -- Start straight movement if necessary. Stop movement for collisions with obstacle.
    if fdir and not is_obstacle_reached then
      local movement = sol.movement.create("straight")
      movement:set_angle(fdir * math.pi / 2)
      movement:set_speed(speed)
      movement:set_max_distance(dist)
      movement:set_smooth(true) -- TODO check for collision bugs when set to false
      movement:start(portable)
    end
    
    -- Start shifting height of the portable at each instant for current bounce.
    local refreshing_time = 5 -- Time between computations of each position.
    sol.timer.start(self, refreshing_time, function()
      t = t + refreshing_time
      current_instant = t
      if shadow then shadow:set_position(portable:get_position()) end
      -- Update shift of sprite.
      if t <= dur then 
        sprite:set_xy(0, portable:current_height() + vshift)
      -- Stop the timer. Start next bounce or finish bounces. 
      else -- The portable hits the ground.
        map:ground_collision(portable, bounce_sound) -- TODO Check for bad ground.
        -- Check if the portable exists (it can be removed on holes, water and lava).
        if portable:exists() then 
          current_bounce = current_bounce + 1
          current_instant = 0
          portable:bounce() -- Start next bounce.
        end
        return false
      end
      return true
    end)
  end

  -- Start the bounces in the given direction.
  portable:bounce()
end

portable:register_event("on_created", function(portable)

  -- General properties
  portable:set_traversable_by(false)
  portable:set_drawn_in_y_order(true)
  portable:set_weight(0)

  -- Traversable rules
  portable:set_can_traverse_ground("deep_water", true)
  portable:set_can_traverse_ground("shallow_water", true)
  portable:set_can_traverse_ground("hole", true)
  portable:set_can_traverse_ground("lava", true)
  portable:set_can_traverse_ground("grass", true)
  portable:set_can_traverse_ground("prickles", true)
  portable:set_can_traverse_ground("low_wall", true)
  portable:set_can_traverse("hero", true)
  portable:set_can_traverse("stream", true)
  portable:set_can_traverse("switch", true)
  portable:set_can_traverse("teletransporter", true)
  portable:set_can_traverse(false)

  -- Behavior when carried
  portable:register_event("on_lifting", function(portable, hero, carried_portable)
    
    -- Remove the build-in carried_object when thrown and replace it by the initial custom entity with custom thrown trajectory.
    carried_portable:register_event("on_thrown", function(carried_portable)

      local hero = map:get_hero()
      local x, y, layer = hero:get_position()
      local direction = hero:get_direction()
      local animation_set = carried_portable:get_sprite():get_animation_set()
      local properties = {model = "portable", name = portable_name,
          x = x, y = y, layer = layer, direction = direction, sprite = animation_set,
          width = 16, height = 16, sprite = animation_set}
      carried_portable:remove()

      local thrown_portable = map:create_custom_entity(properties)
      thrown_portable:throw(direction)
    end)
  end)
end)
