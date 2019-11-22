--[[
Jump manager

When you use jumping items in top-view maps, this script applies an offset to the given entity's sprites over time, so it moves in a parabolic way. It also updates the entity's state collision and interaction rules so it allows them to persist beyond the end of the jump or through chained jumps.

To use :
1. in your custon jumping state, require this script
2. (optional) to gat a premade state call jump_manager:init("your_wanted_state_name")
3. Finally, in your state lauching function, call jumping_manager:start(entity_to_ammply_the_sprite_shifting_on)

--]]

local jump_manager={}
require("scripts/states/jumping")(jump_manager)
require("scripts/states/running")(jump_manager)
local gravity = 0.12
local max_yvel = 2
local y_factor = 1.0

local debug_start_x, debug_start_y
local debug_max_height = 0

local audio_manager=require("scripts/audio_manager")

--TODO remove this and only use per-state collision rules ?

function jump_manager.reset_collision_rules(state)
  if state and sol.main.get_type(state)=="state" then 
    state:set_affected_by_ground("hole", true)
    state:set_affected_by_ground("lava", true)
    state:set_affected_by_ground("deep_water", true)
    state:set_affected_by_ground("prickles", true)
    state:set_affected_by_ground("grass", false)
    state:set_affected_by_ground("shallow_water", false)
    state:set_can_use_stairs(true)
    state:set_can_use_teletransporter(true)
    state:set_can_use_switch(true)
    state:set_can_use_stream(true)
    state:set_can_be_hurt(true)
    state:set_gravity_enabled(true)
    state:set_can_traverse("crystal_block", nil)
  end
end

function jump_manager.setup_collision_rules(state)

  if state and sol.main.get_type(state)=="state" then 
    state:set_affected_by_ground("hole", false)
    state:set_affected_by_ground("lava", false)
    state:set_affected_by_ground("deep_water", false)
    state:set_affected_by_ground("grass", false)
    state:set_affected_by_ground("shallow_water", false)
    state:set_affected_by_ground("prickles", false)
    state:set_can_traverse("crystal_block", function(entity, crystal) --Will be obsolete as soon as custom crystal blocks are operational
        local anim=crystal:get_sprite():get_animation()
        return entity.is_on_crystal_block or anim=="blue_lowered" or anim=="orange_lowered"
      end)
    state:set_can_use_stairs(false)
    state:set_can_use_teletransporter(false)
    state:set_can_use_switch(false)
    state:set_can_use_stream(false)
    state:set_can_be_hurt(false)
    state:set_can_grab(false)
    state:set_gravity_enabled(false)
  end
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
        entity.y_vel = 0 - math.abs(entity.y_vel)
      end
    end
  end
end

function jump_manager.trigger_event(entity, event)
  local state=entity:get_state()
  local state_object=entity:get_state_object()
  debug_print ("state "..state.."("..(state_object and state_object.get_description and state_object:get_description() or "<built-in>")..") triggered the following Event: "..event)
  local desc=state_object and state_object.get_description and state_object:get_description() or ""
  sol.timer.start(entity, 10, function()
      if event=="jump complete" then
        entity:play_ground_effect()
        if desc=="jumping" then
          entity:unfreeze()
        end
      else --default case
        debug_print ("unknown event: "..event)
        entity:unfreeze()
      end
    end)
end

function jump_manager.update_jump(entity, callback)
  if not entity:get_game():is_paused() then
    entity.y_offset=entity.y_offset or 0

    for name, sprite in entity:get_sprites() do
      if name~="shadow" and name~="shadow_override" then
        sprite:set_xy(0, math.min(entity.y_offset, 0)*y_factor)
      end
    end

    entity.y_offset= entity.y_offset+entity.y_vel
    debug_max_height=math.min(debug_max_height, entity.y_offset)

    entity.y_vel = entity.y_vel + gravity

    -- Bounce on a possible enemy that can be hurt with jump.
    if entity.y_vel > 0 and entity.y_offset > -8 then
      on_bounce_possible(entity)
    end

    if entity.y_offset >=0 then --reset sprites offset and stop jumping, and trigger the callback if any
      for name, sprite in entity:get_sprites() do
        sprite:set_xy(0, 0)
      end
      --local final_x, final_y=entity:get_position()
      --print("Distance reached during jump: X="..final_x-debug_start_x..", Y="..final_y-debug_start_y..", height="..debug_max_height)
      jump_manager.reset_collision_rules(entity:get_state_object())
      entity.ignore_crystal_block=nil
      entity:set_jumping(false)
      if callback then 
        --print "CALLBACK"
        callback()
      end
      jump_manager.trigger_event(entity, "jump complete")
      return false
    end
  end
  return true
end

local function check_control(entity)
  local game=entity:get_game()
  local _left=game:is_command_pressed("left")
  local _right=game:is_command_pressed("right") 
  local _up=game:is_command_pressed("up")
  local _down=game:is_command_pressed("down")
  local result=_left and not _right or _right and not _left or _up and not _down or _down and not _up
  return result
end


--[[Starts the actual parabole
  Parameters
    entity: the entity to start the jump on
    v_speed: the vertical speed. Defaults to 2 px/tick.
    Note : the inputted vspeed to automatically converted to an updraft movement, so yu can either input -3.14 or 3.14 as a desired speed.
--]]
function jump_manager.start_parabola(entity, v_speed, callback)
  if not entity or entity:get_type() ~= "hero" then
    return
  end
  entity:set_jumping(true)

  jump_manager.setup_collision_rules(entity:get_state_object())
  entity.y_vel = v_speed and -math.abs(v_speed) or -max_yvel


  local t=sol.timer.start(entity, 10, function()
      return jump_manager.update_jump(entity, callback)
    end)
  t:set_suspended_with_map(false)
end

function jump_manager.start(entity, v_speed, success_callback, failure_callback)

  if not entity or entity:get_type() ~= "hero" then
    return
  end

  if entity:is_jumping() then
    if failure_callback then
      failure_callback()
    end
    return
  end

  local state, state_object=entity:get_state() --launch approprate custom state
  local state_description = state=="custom" and state_object:get_description() or ""
--  if state=="free" then
  entity:jump()
--  elseif state=="sword swinging" or state_description=="sword" then
--    entity:swing_sword()
--  elseif state=="sword loading" or state_description=="jumping_sword_loading" then
--    entity:sword_loading()
--  else
--    debug_print ("Warning: incompatible state: "..state)
--  end
  jump_manager.setup_collision_rules(state_object)

  --  debug_print "Starting custom jump"
  debug_start_x, debug_start_y=entity:get_position() --Temporary, remove me once everything has been finalized

  audio_manager:play_sound("hero/jump")
  entity:set_jumping(true)
  local x,y, w,h=entity:get_bounding_box()
  for e in entity:get_map():get_entities_in_rectangle(x,y,w,h) do
    if e:get_type()=="custom_entity" and e:get_model()=="crystal_block" then
      local anim=e:get_sprite():get_animation()
      debug_print(anim)
      entity.ignore_crystal_block = anim=="orange_raised" or anim=="blue_raised"
    end
  end

  local function callback()

  end


  entity.y_vel = v_speed and -math.abs(v_speed) or -max_yvel

  local t=sol.timer.start(entity, 10, function()
      return jump_manager.update_jump(entity, callback)
    end)
  t:set_suspended_with_map(false)

end



return jump_manager