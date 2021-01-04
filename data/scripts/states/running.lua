--[[
  Updated running custom state state.
  This script aims to reproduce the natural bahavior of the running shoes of Zelda : Link's Akakening
  It enables running into special obstacles to make things fall (or at least it tries to), and lets the hero jump without changing state.
  To use, require this file in your speed-ability item script, then
  call hero:run()
--]]
local state = sol.state.create("running")
local hero_meta=sol.main.get_metatable("hero")
local jump_manager
local audio_manager=require("scripts/audio_manager")
local map_tools=require("scripts/maps/map_tools")

state:set_can_use_item(false)
state:set_can_use_item("feather", true)
state:set_can_traverse("crystal_block", false)
state:set_can_use_jumper(true)
state:set_jumper_delay(0)
local directions = {
  {
    key="right",
    direction=0,
  },
  {
    key="up",
    direction=1,
  },
  {
    key="left",
    direction=2,
  },
  {
    key="down",
    direction=3,
  },
}

--This is the function to call to start the whole running process
function hero_meta.run(hero, came_from_map_scrolling_transition)
  local current_state, state_object=hero:get_state()
  if came_from_map_scrolling_transition==true and state =="free" then --At this point we are supposed to be in "free" state
    hero:start_state(state)
  end
  if current_state~="custom" or state_object:get_description()~="running" then
    if not hero:get_map():is_sideview() or hero:get_direction()==0 or hero:get_direction()==2 then
      --In sideviews, only allow to run sideways
      hero:start_state(state)
    end
  end
end

--Stops and detaches the timer that enables the running sound to play frm the entity
local function stop_sound_loop(entity)
  if entity.run_sound_timer~= nil then
    entity.run_sound_timer:stop()
    entity.run_sound_timer = nil
  end
end

-- Create a new sword sprite to not trigger the "sword" attack on collision with enemies.
local function create_running_sword(entity, direction)

  local animation_set = entity:get_sprite("sword_override"):get_animation_set()
  local sprite=entity:get_sprite("running_sword") or entity:create_sprite(animation_set, "running_sword")
  sprite:set_animation("sword_loading_walking")
  sprite:set_direction(direction)

  return sprite
end

local function begin_run()
  local entity=state:get_entity()
  local game=entity:get_game()
  local map=entity:get_map()
  local hero=map:get_hero()
  local sprite=entity:get_sprite()
  --start movement and pull out sword if any
  entity.running_timer=nil --TODO check if this isn't useless 
  entity.running=true -- Set to true when the entity is actually running, so after the run preparation.
  local sword_sprite
  state:set_can_be_hurt(false)
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  if game:get_sword_ability() then
    sprite:set_animation("sword_loading_walking")
    sword_sprite = create_running_sword(entity, sprite:get_direction())
  end

  local running_movement=sol.movement.create("straight")
  running_movement:set_speed(196)
  running_movement:set_angle(sprite:get_direction()*math.pi/2)

  -- Trigger the thrust attack when collision between any sprite of the hero and an enemy.
  function running_movement:on_position_changed()
    for enemy in map:get_entities_by_type("enemy") do
      if enemy:overlaps(entity, "sprite") and enemy:get_life() > 0 and not enemy:is_immobilized() then

        local reaction = enemy:get_thrust_reaction()
        if reaction ~= "ignored" then -- Do nothing if the enemy ignore thrust attack.
          local enemy_sprite = enemy:get_sprite()

          -- Propagate the attack consequence if the enemy is not protected against thrust attack and is not currently hurt.
          if reaction ~= "protected" and enemy_sprite:get_animation() ~= "hurt" and enemy_sprite:get_shader() ~= "hurt" then
            enemy:receive_attack_consequence("thrust", reaction)
          else
            -- Else hurt the hero if the enemy can attack and the enemy touches the hero tunic sprite.
            if enemy:get_can_attack() and enemy:overlaps(entity, "sprite", nil, entity:get_sprite("tunic")) then 
              hero:start_hurt(enemy, enemy:get_damage())
            else
              -- TODO Else repulse
            end
          end
        end
      end
    end
  end

  function running_movement:on_obstacle_reached()
    require ("scripts/states/bonking")(jump_manager)
    stop_sound_loop(entity)
    entity:bonk()
  end
  --Run !
  running_movement:start(entity)

end


function state:on_started()
--  debug_print "Run, Forrest, ruuun !"
  local entity=state:get_entity()
  local game = state:get_game()
  local map = entity:get_map()
  local sprite=entity:get_sprite("tunic")
  entity:get_sprite("trail"):set_animation("running") 
  sprite:set_animation("walking")

  -- Initialize state abilities that may have changed.
  state:set_can_be_hurt(true)
  state:set_can_control_direction(true)
  state:set_can_control_movement(true)

  --Start playing the running sound
  entity.run_sound_timer = sol.timer.start(state, 200, function()
      if not entity.is_jumping or not entity:is_jumping() then
        if entity:get_ground_below() == "shallow_water" then
          audio_manager:play_sound("hero/wade1")
        elseif entity:get_ground_below()=="grass" then
          audio_manager:play_sound("hero/walk on grass")
        else
          audio_manager:play_sound("hero/run")
        end
        return true
      end
    end)
  if game.needs_running_restoration==true then--will be the case if we came from an intra-world map transition
    game.needs_running_restoration=nil
    begin_run()
  end
  --Prepare for running...
  entity.running_timer=sol.timer.start(state, 500, begin_run)
end

--Stops the run when the player changes the diection
function state:on_command_pressed(command)

  local entity=state:get_entity()
  if entity.running then
    local game=entity:get_game()
    local sprite=entity:get_sprite()

    --Stop running on direction change, unless we just bonked into an obstacle
    if not entity.bonking then
      for _,candidate in pairs(directions) do
        if candidate.key == command and candidate.direction~=sprite:get_direction() then
          entity:unfreeze()
          entity.running = false
          return true
        end
      end
    end
  end
end

--Stops the running preparation if the ACTION command is released
function state:on_command_released(command)
  if command == "action" then
    local entity=state:get_entity()
    if entity.running_timer~=nil then
      entity:unfreeze()
      return true
    end
  end
  local game = state:get_game()
  for i=1, 2 do
    local item =game:get_item_assigned(""..i)
    if command == "item_"..i and item and item:get_name()=="pegasus_shoes" then
      local entity=state:get_entity()
      if entity.running_timer~=nil then
        entity:unfreeze()
        return true
      end
    end
  end
end

function state:on_finished()
  local entity=state:get_entity()
  local sword_sprite = entity:get_sprite("running_sword")

  entity:get_sprite("trail"):stop_animation()
  if sword_sprite then
    entity:remove_sprite(sword_sprite)
  end
  entity.running=false
  entity:stop_movement()
end

return function(_jump_manager)
  jump_manager=_jump_manager
end

