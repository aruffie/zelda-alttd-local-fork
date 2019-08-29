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
    state:set_can_use_stairs(true)
    state:set_can_use_teletransporter(true)
    state:set_can_use_switch(true)
    state:set_can_use_stream(true)
    state:set_can_be_hurt(true)
  end
end

function jm.setup_collision_rules(state)
-- TODO find a way to get rid of hardcoded state filter for more flexibility

  if state and (state:get_description() == "jumping" or state:get_description() =="jumping_sword" or state:get_description() == "running") then
    state:set_affected_by_ground("hole", false)
    state:set_affected_by_ground("lava", false)
    state:set_affected_by_ground("deep_water", false)
    state:set_affected_by_ground("prickles", false)
    state:set_can_use_stairs(false)
    state:set_can_use_teletransporter(false)
    state:set_can_use_switch(false)
    state:set_can_use_stream(false)
    state:set_can_be_hurt(false)
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

function jm.update_jump(entity)

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

  if entity.y_offset >=0 then --reset sprites offset and stop jumping
    for name, sprite in entity:get_sprites() do
      sprite:set_xy(0, 0)
    end
    local final_x, final_y=entity:get_position()
    print("Distance reached during jump: X="..final_x-debug_start_x..", Y="..final_y-debug_start_y..", height="..debug_max_height)
    entity.jumping = false
    if entity:get_state()~="custom" or entity:get_state_object():get_description()~="running" and not sol.main.get_game():is_command_pressed("attack") then
      entity:unfreeze()
    else
      jm.reset_collision_rules(entity:get_state_object())
    end
    return false
  end
  return true
end

function jm.start(entity)

  if not entity:is_jumping() then
    audio_manager:play_sound("hero/jump")
    debug_start_x, debug_start_y=entity:get_position()
    entity:set_jumping(true)
    jm.setup_collision_rules(entity:get_state_object())
    entity.y_vel = -max_yvel
    
    local t=sol.timer.start(entity, 10, function()
      return jm.update_jump(entity)
    end)
    t:set_suspended_with_map(false)
  end
end

function jm.init(name)
  local state = sol.state.create(name)
  state:set_can_use_item(false)
  state:set_can_control_movement(true)
  state:set_can_control_direction(false)
  state:set_can_traverse("stairs", false)

  return state
end

return jm