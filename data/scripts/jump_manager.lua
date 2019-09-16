--[[
Jump manager

When you use jumping items in top-view maps, this script applies an offset to the given entity's sprites over time, so it moves in a parabolic way. It also updates the entity's state collision and interaction rules so it allows them to persist beyond the end of the jump or through chained jumps.

To use :
1. in your custon jumping state, require this script
2. (optional) to gat a premade state call jump_manager:init("your_wanted_state_name")
3. Finally, in your state lauching function, call jumping_manager:start(entity_to_ammply_the_sprite_shifting_on)

--]]

local jm={}

local gravity = 0.12
local max_yvel = 2
local y_factor = 1.0

local debug_start_x, debug_start_y
local debug_max_height = 0

local audio_manager=require("scripts/audio_manager")

function jm.reset_collision_rules(state)
  if state and (state:get_description() == "jumping_sword" or state:get_description() == "running") then
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
    --state:get_entity():get_sprite("ground"):set_animation(state.ground_animation())

  end
end

function jm.setup_collision_rules(state)
-- TODO find a way to get rid of hardcoded state filter for more flexibility

  if state and (state:get_description() == "jumping" or state:get_description() =="jumping_sword" or state:get_description() == "running") then 
    state:set_affected_by_ground("hole", false)
    state:set_affected_by_ground("lava", false)
    state:set_affected_by_ground("deep_water", false)
    state:set_affected_by_ground("grass", false)
    state:set_affected_by_ground("shallow_water", false)
    state:set_affected_by_ground("prickles", false)
    state:set_can_use_stairs(false)
    state:set_can_use_teletransporter(false)
    state:set_can_use_switch(false)
    state:set_can_use_stream(false)
    state:set_can_be_hurt(false)
    state:set_can_grab(false)
    state:set_gravity_enabled(false)
--    local sprite=state:get_entity():get_sprite("ground")
--    if sprite then
--      state.ground_animation=sprite:get_animation()
--      sprite:stop_animation()
--    end
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

function jm.update_jump(entity, callback)
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
      local final_x, final_y=entity:get_position()
      --print("Distance reached during jump: X="..final_x-debug_start_x..", Y="..final_y-debug_start_y..", height="..debug_max_height)
      entity.jumping = false
      if callback then 
        --print "CALLBACK"
        callback()
      end

      if entity:get_state()=="custom" and entity:get_state_object():get_description()=="running" or sol.main.get_game():is_command_pressed("attack") then
        jm.reset_collision_rules(entity:get_state_object())
      end
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

function jm.start(entity, v_speed, callback)
  if not entity or entity:get_type() ~= "hero" then
    return
  end
--  print "Starting custom jump"
  if not entity:is_jumping() then
    audio_manager:play_sound("hero/jump")
    debug_start_x, debug_start_y=entity:get_position() --Temporary, remove me once everything has been finalized
    entity:set_jumping(true)
    jm.setup_collision_rules(entity:get_state_object())
    entity.y_vel = v_speed and -math.abs(v_speed) or -max_yvel

    --TEMPORARY FIX TRY: force a jump to ignore ground speed inflence.
--    local movement=entity:get_movement() 
--    if movement and movement.get_speed then
--      local speed = movement:get_speed()  --PROBLEM: Always returns zero, but the debug screen one has the crrect values. So why is there a difference ?0

--      local state=entity:get_state_object() --
--      function state:on_movement_changed(movement) --DEBUG: remove me when the speed bug is fixed
--        local new_speed=movement:get_speed()
--        if new_speed ~=speed then
--          print ("Movement has changed, new speed =".. new_speed)
--        end
--      end

--      if check_control(entity) and (entity:get_state()~= "custom" or state:get_description()~="running") then
--        print (state:is_affected_by_ground("hole"))
--        print ("changing speed from ".. speed .." to 88") 
--        movement:set_speed(88)
--      end
--      speed = movement:get_speed()
--      print ("Current movement speed: "..speed)

--    end

    local t=sol.timer.start(entity, 10, function()
        return jm.update_jump(entity, callback)
      end)
    t:set_suspended_with_map(false)
  end
end

function jm.init(name)
  local state = sol.state.create(name)
  state:set_can_use_item(false)
  state:set_can_use_item("sword", true)
  state:set_can_use_item("shield", true)
  state:set_can_use_item("bow", true)
  state:set_can_use_item("boomerang", true)
  state:set_can_use_item("bombs_counter", true)
  state:set_can_use_item("magic_powders_counter", true)
  state:set_can_use_item("fire_rod", true)
  state:set_can_cut(false) --TODO refine me
  state:set_can_control_movement(true)
  state:set_can_control_direction(false)
  state:set_can_traverse("stairs", false)

  return state
end

return jm