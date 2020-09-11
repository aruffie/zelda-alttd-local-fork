-- Lua script of item "shield".
-- This script is executed only once for the whole game.

--[[ Pushing commands for the shield:
This is defined for entities of types: "hero", "enemy" and "sprite".
Collisions with sprites of enemies override collisions with enemies.
This script can be extended to other types of entities.

-------- CUSTOM EVENTS:
enemy/sprite:on_shield_collision(shield) -- Overrides push behavior.
enemy/sprite:on_pushed_by_shield(shield) -- Called after creating the push.
enemy/sprite:on_pushing_hero_on_shield(shield) -- Called after creating the push.
enemy/sprite:on_finished_pushed_by_shield()
enemy/sprite:on_finished_pushed_hero_on_shield()
enemy/sprite:on_shield_collision_test(shield_collision_mask) -- Test: true to confirm collision.

-------- FUNCTIONS:
enemy/sprite:get_can_be_pushed_by_shield()
enemy/sprite:set_can_be_pushed_by_shield(boolean)
enemy/sprite:get_pushed_by_shield_properties()
enemy/sprite:set_pushed_by_shield_properties(properties)
enemy/sprite:get_pushed_by_shield_property(property_name)
enemy/sprite:set_pushed_by_shield_property(property_name, value)

hero:is_using_shield()
hero:is_shield_protecting_from_enemy(enemy, enemy_sprite)

enemy/sprite:get_can_push_hero_on_shield()
enemy/sprite:set_can_push_hero_on_shield(boolean)
enemy/sprite:get_push_hero_on_shield_properties()
enemy/sprite:set_push_hero_on_shield_properties(properties)
enemy/sprite:get_push_hero_on_shield_property(property_name)
enemy/sprite:set_push_hero_on_shield_property(property_name, value)

item:set_collision_mask() 
item:get_collision_mask_visible() 
item:set_collision_mask_visible(visible)

-------- Default shield BEHAVIORS (string values):
enemy/sprite:set_default_behavior_on_hero_shield(behavior)
"normal_shield_push", "enemy_weak_to_shield_push", "enemy_strong_to_shield_push", "block_push", nil.

-------- VARIABLES in tables of properties:
-distance
-speed
-sound_id
-push_delay
-num_directions: 4 or "any".
--]]

-- Variables
local item = ...
local audio_manager = require("scripts/audio_manager")
local enemy_meta = sol.main.get_metatable("enemy")
local hero_meta = sol.main.get_metatable("hero")
local sprite_meta = sol.main.get_metatable("sprite")
local game = item:get_game()
local direction_fix_enabled = true
local shield_state -- Values: "preparing", "using".
local shield_command_released
local shield, shield_below -- Custom entity shield.
local collision_mask -- Custom entity used to detect collisions.
local path_collision_mask_sprite = "hero/shield_collision_mask"
local collision_mask_visible = false -- Change this to debug.
local normal_sound_id = "shield_push"
local block_sound_id = "shield2"
local strong_sound_id = "shield"
local weak_sound_id = "shield_push"

require("scripts/maps/pushing_manager")

-- Event called when the game is initialized.
function item:on_created()
  
  self:set_savegame_variable("possession_shield")
  self:on_variant_changed(self:get_variant())
  self:set_sound_when_brandished(nil)
  
end

function item:on_variant_changed(variant)
  if variant > 0 then self:set_assignable(true)
  else self:set_assignable(false) end
end

function item:on_obtaining()
  
  audio_manager:play_sound("items/fanfare_item_extended")
        
end

-- Event called when the hero is using this item.
function item:on_using()
  local map = self:get_map()
  local hero = game:get_hero()
  local hero_tunic_sprite = hero:get_sprite()
  local variant = item:get_variant()

  -- Do nothing if game is suspended or if shield is being used.
  if variant == 0 then return end
  if game:is_suspended() or hero:is_using_shield() then return end
  -- Do not use if there is bad ground below or while jumping.
  if not map:is_solid_ground(hero:get_ground_position()) then return end 
  if hero.is_jumping and hero:is_jumping() then return end
    
  -- Play shield sound.
  audio_manager:play_sound("items/shield")

  -- Freeze hero and save state.
  hero:set_using_shield(true)
  if hero:get_state() ~= "frozen" then
    hero:freeze() -- Freeze hero if necessary.
  end
  shield_command_released = false
  -- Remove fixed animations (used if jumping).
  hero:set_fixed_animations(nil, nil)
  -- Show "shield_brandish" animation on hero.
  if hero:get_sprite():has_animation("shield_brandish") then
    shield_state = "preparing"
    hero:set_animation("shield_brandish")
  end
  
  -- Disable hero abilities.
  item:set_grabing_abilities_enabled(0)
  
  -- Create shield.
  self:create_shield()

  -- Stop using item if there is bad ground under the hero.
  sol.timer.start(item, 5, function()
    if not self:get_map():is_solid_ground(hero:get_ground_position()) then
      self:finish_using()
    end
    return true
  end)

  -- Check if the item command is being hold all the time.
  local slot = game:get_item_assigned(1) == item and 1 or 2
  local command = "item_" .. slot
  sol.timer.start(item, 1, function()
    local is_still_assigned = game:get_item_assigned(slot) == item
    if not is_still_assigned or not game:is_command_pressed(command) then 
      -- Notify that the item button was released.
      shield_command_released = true
      return
    end
    return true
  end)
  
  -- Stop fixed animations if the command is released.
  sol.timer.start(item, 1, function()
    if shield_state == "using" then
      if shield_command_released == true then
      -- Finish using if shield command is released.
        self:finish_using()
        return
      elseif hero:get_state() == "sword swinging" then 
      -- Finish using if sword is used.
        self:finish_using()
        -- Restart sword attack.
        local sword = game:get_item("sword")
        game:get_hero():start_attack()
        return
      end
    end
    return true
  end)

  local function start_using_shield_state()
    -- Do not allow walking with shield if the command was released.
    if shield_command_released == true then
      self:finish_using()
      return
    end
    -- Start loading sword if necessary. Fix direction and loading animations.
    shield_state = "using"
    hero:set_fixed_animations("shield_stopped", "shield_walking")
    local dir = direction_fix_enabled and hero:get_direction() or nil
    hero:set_fixed_direction(dir)
    hero:set_animation("shield_stopped")
    hero:unfreeze() -- Allow the hero to walk.
  end
  
  if shield_state == "preparing" then
    -- Start custom shield state when necessary: allow to sidle with shield.
    local num_frames = hero_tunic_sprite:get_num_frames()
    local frame_delay = hero_tunic_sprite:get_frame_delay()
    -- Prevent bug: if frame delay is nil (which happens with 1 frame) stop using shield.
    if not frame_delay then self:finish_using() return end  
    local anim_duration = frame_delay * num_frames
    sol.timer.start(map, anim_duration, function()
      start_using_shield_state()
    end)
  else
    start_using_shield_state()
  end
end

-- Map transition events: stop using when changing maps.
function item:on_map_finished(map)
  local hero = game:get_hero()
  if hero and hero:is_using_shield() then self:finish_using() end
end
function item:on_map_changed(map)
  map:register_event("on_finished", function()
    item:on_map_finished(map)
  end)
end

function item:finish_using()
  -- Stop all timers (necessary if the map has changed, etc).
  sol.timer.stop_all(self)
  -- Finish using item.
  self:set_finished()
  -- Reset fixed animations/direction. (Used while sidling with shield
  local hero = game:get_hero()
  hero:set_fixed_direction(nil)
  hero:set_fixed_animations(nil, nil)
  shield_state = nil
  -- Destroy shield.
  if shield and shield:exists() then
    shield:remove()
    shield = nil
  end
  -- Enable hero abilities.
  item:set_grabing_abilities_enabled(1)
  -- Unfreeze the hero if necessary.
  hero:unfreeze() -- This updates direction too, preventing moonwalk!
  hero:set_using_shield(false)
end


function item:create_shield()

  -- Create shield entities, including collision_mask.
  local map = self:get_map()
  local hero = game:get_hero()
  local hx, hy, hlayer = hero:get_position()
  local hdir = hero:get_direction()
  local prop = {x=hx, y=hy+2, layer=hlayer, direction=hdir, width=2*16, height=2*16}
  shield = map:create_custom_entity(prop) -- (Script variable.)
  shield_below = map:create_custom_entity(prop)
  collision_mask = map:create_custom_entity(prop)
  function shield:on_removed()
    if shield_below then shield_below:remove() end
    collision_mask:remove()
  end
  
  -- Create visible sprites.
  local variant = item:get_variant()
  local shield_below_path = "hero/shield_"..variant.."_below"
  local shield_above_path = "hero/shield_"..variant.."_above"
  local sprite_shield, sprite_shield_below
  if sol.file.exists("sprites/"..shield_below_path..".dat") then
    sprite_shield_below = shield_below:create_sprite(shield_below_path)
    sprite_shield_below:set_direction(hdir)
  else
    shield_below:remove(); shield_below = nil
  end
  sprite_shield = shield:create_sprite(shield_above_path)
  sprite_shield:set_direction(hdir)
  
  -- Create (invisible) collision mask sprite.
  local sprite_collision_mask = collision_mask:create_sprite(path_collision_mask_sprite)
  sprite_collision_mask:set_direction(hdir)
  collision_mask:set_visible(collision_mask_visible)
  
  -- Redefine functions to draw "shield" above hero and "shield_below" below hero.
  shield:set_drawn_in_y_order(true)
  shield.old_set_position = shield.set_position
  function shield:set_position(x, y, layer) self:old_set_position(x, y + 2, layer) end
  sprite_shield.old_set_xy = sprite_shield.set_xy
  function sprite_shield:set_xy(x, y) self:old_set_xy(x, y-2) end
  
  -- Update position and sprites.
  sol.timer.start(shield, 1, function()
    local tunic_sprite = hero:get_sprite()
    local x, y, layer = hero:get_position()
    for _, sh in pairs({shield, shield_below, collision_mask}) do
      sh:set_position(x, y, layer)
      sh:set_direction(hero:get_direction())
      local s = sh:get_sprite()
      local anim = tunic_sprite:get_animation()
      if s:has_animation(anim) then s:set_animation(anim) end
      local frame = tunic_sprite:get_frame()
      if frame > s:get_num_frames()-1 then frame = 0 end
      s:set_frame(frame)
      local x, y = tunic_sprite:get_xy()
      s:set_xy(x, y)
    end
    -- Disable shield on jumpers.
    if hero:get_state() == "jumping" then
      self:finish_using()
      return
    end
    return true
  end)
  -- Define collision test to detect enemies with shield.
  -- A pixel-precise collision between enemy and shield is assumed before calling this test.
  local function shield_collision_test(shield, entity, shield_sprite, entity_sprite)
    
    -- Check collision conditions. Sprite collision overrides entity collision.
    if (not entity) or (not entity_sprite) then return end
    for _, e in ipairs({entity_sprite, entity}) do
      
      local custom_test = (e.on_shield_collision_test == nil)
            or e:on_shield_collision_test(collision_mask)

      -- Check for overriding event. Do not push if event exists.
      if custom_test and e.on_shield_collision then
        e:on_shield_collision(shield)
        return
      end

      if custom_test and e.get_can_be_pushed_by_shield
          and e:get_can_be_pushed_by_shield()
          and (not entity:is_being_pushed()) then
        
        -- Push entity.
        local p = {}
        if e.get_pushed_by_shield_properties then 
          p = e:get_pushed_by_shield_properties()
        end
        p.pushing_entity = shield
        p.on_pushed = function()
          if e.on_finished_pushed_by_shield then
            e:on_finished_pushed_by_shield()
          end
        end
        entity:push(p)
        -- Custom event.
        if e.on_pushed_by_shield then
          e:on_pushed_by_shield(shield)
        end
      end
      
      -- Check if hero can be pushed.
      if custom_test and e.get_can_push_hero_on_shield
          and e:get_can_push_hero_on_shield() 
          and (not hero:is_being_pushed()) then

        local p = {}
        if e.get_push_hero_on_shield_properties then 
          p = e:get_push_hero_on_shield_properties()
        end
        p.pushing_entity = entity
        p.on_pushed = function()
          if e.on_finished_pushed_hero_on_shield then
            e:on_finished_pushed_hero_on_shield()
          end
        end   
        hero:push(p)
        -- Custom event.
        if e.on_pushing_hero_on_shield then
          e.on_pushing_hero_on_shield(shield)
        end
      end
      
      -- Sprite behavior, if any, overrides entity behavior (in the first loop).
      if e.get_can_be_pushed_by_shield and e:get_can_be_pushed_by_shield() 
          or e.get_can_push_hero_on_shield and e:get_can_push_hero_on_shield() then
        return
      end
    end
  end
  
  -- Initialize collision test on the shield collision mask.
  collision_mask:add_collision_test("sprite", shield_collision_test)
end

function item:set_grabing_abilities_enabled(enabled)
  for _, ability in pairs({"push", "grab", "pull"}) do
    game:set_ability(ability, enabled)
  end
end

-- Get shield collision mask entity, if any.
function item:get_collision_mask() return collision_mask end
-- Set collision mask visible/invisible.
function item:get_collision_mask_visible() return collision_mask_visible end
function item:set_collision_mask_visible(visible) 
  collision_mask_visible = visible
  if collision_mask then collision_mask:set_visible(visible) end
end

-- Detect if hero is using shield.
function hero_meta:is_using_shield()
  return self.using_shield or false
end
function hero_meta:set_using_shield(using_shield)
  self.using_shield = using_shield
end
function item:is_being_used()
  return self:get_map():get_hero().using_shield or false
end

-- True if there is a pixel collision between shield and enemy.
function hero_meta:is_shield_protecting_from_enemy(enemy, enemy_sprite)
  -- Check use of shield and shield collision.
  local hero = self  
  if not hero:is_using_shield() then return false end
  local shield_collision_mask = self:get_game():get_item("shield"):get_collision_mask()
  if not shield_collision_mask then return false end
  if enemy:overlaps(shield_collision_mask, "sprite") then
    return true -- The shield is protecting
  end
  return false -- The shield is not protecting the hero.
end

-- Properties for being pushed.
for _, entity_meta in ipairs({sprite_meta, enemy_meta}) do

  function entity_meta:get_can_be_pushed_by_shield()
    return self.can_be_pushed_by_shield
  end
  function entity_meta:set_can_be_pushed_by_shield(boolean)
    self.can_be_pushed_by_shield = boolean
  end
  function entity_meta:get_pushed_by_shield_properties()
    return self.pushed_by_shield_properties or {}
  end
  function entity_meta:set_pushed_by_shield_properties(properties)
    self.pushed_by_shield_properties = properties
  end
  function entity_meta:get_pushed_by_shield_property(property_name)
    return (self.pushed_by_shield_properties)[property_name]
  end
  function entity_meta:set_pushed_by_shield_property(property_name, value)
    local p = self.pushed_by_shield_properties
    p[property_name] = value
  end
  
  -- Properties for pushing.
  function entity_meta:get_can_push_hero_on_shield()
    return self.can_push_hero_on_shield
  end
  function entity_meta:set_can_push_hero_on_shield(boolean)
    self.can_push_hero_on_shield = boolean
  end
  function entity_meta:get_push_hero_on_shield_properties()
    return self.push_on_shield_properties or {}
  end
  function entity_meta:set_push_hero_on_shield_properties(properties)
    self.push_on_shield_properties = properties
  end
  function entity_meta:get_push_hero_on_shield_property(property_name)
    return (self.push_hero_on_shield_properties)[property_name]
  end
  function entity_meta:set_push_hero_on_shield_property(property_name, value)
    local p = self.push_hero_on_shield_properties
    p[property_name] = value
  end
  
  --[[ Behavior function: get properties for each behavior. Behaviors:
  "normal_shield_push", "enemy_weak_to_shield_push", "enemy_strong_to_shield_push", "block_push", nil.
  --]]
  function entity_meta:set_default_behavior_on_hero_shield(behavior)
    -- Define default properties.
    local p_enemy, p_hero
    local normal_push = {distance = 32, speed = 120, push_delay = 250, num_directions = "any"}
    local weak_push = {distance = 16, speed = 120, push_delay = 100, num_directions = "any"}
    local strong_push = {distance = 48, speed = 200, push_delay = 500, num_directions = "any"}
    local block_push = {distance = 1, speed = 80, push_delay = 30, num_directions = 4}
    self:set_can_push_hero_on_shield(true)
    self:set_can_be_pushed_by_shield(true)
    -- Select properties for each behavior.
    if behavior == nil then
      p_enemy, p_hero = {}, {}
      self:set_can_push_hero_on_shield(false)
      self:set_can_be_pushed_by_shield(false)
    elseif behavior == "normal_shield_push" then
      p_enemy, p_hero = normal_push, weak_push
      p_enemy.sound_id = normal_sound_id
    elseif behavior == "enemy_weak_to_shield_push" then
      p_enemy, p_hero = normal_push, {}
      self:set_can_push_hero_on_shield(false)
      p_enemy.sound_id = weak_sound_id
    elseif behavior == "enemy_strong_to_shield_push" then
      p_enemy, p_hero = {}, normal_push
      self:set_can_be_pushed_by_shield(false)
      p_hero.sound_id = strong_sound_id
    elseif behavior == "block_push" then
      p_enemy, p_hero = block_push, {}
      self:set_can_push_hero_on_shield(false)
      self:set_traversable(false)
      p_enemy.sound_id = block_sound_id
      -- Test condition for pushing like a block: "facing" overlap.
      function self:on_shield_collision_test(shield_collision_mask)
        local hero = self:get_map():get_hero()
        return self:overlaps(hero, "facing")
      end
    elseif behavior == "burn_push" then
      p_enemy, p_hero = {}, strong_push
      self:set_can_be_pushed_by_shield(false)
      p_hero.sound_id = "fire_ball"
      self:register_event("on_pushing_hero_on_shield", function(self, shield)
        -- Burn wooden shield!
        local item = self:get_game():get_item("shield")
        local variant = item:get_variant()
        if variant == 1 then item:burn_shield() end
      end)
    end
    -- Set properties to enemy.
    self:set_pushed_by_shield_properties(p_enemy)
    self:set_push_hero_on_shield_properties(p_hero)
  end

end

-- Burn and destroy shield.
function item:burn_shield()
  -- Hero stops using shield.
  self:set_variant(0)
  self:finish_using()
  game:start_dialog("_treasure.shield.burnt")
end