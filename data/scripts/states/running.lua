--[[
  Updated running custom state state.
  This script aims to reproduce the natural bahavior of the running shoes of Zelda : Link's Akakening
  It enables running into special obstacles to make things fall (or at least it tries to), and lets the hero jump without changing state.
  To use, require this file in your speed-ability item script, then
  call hero:run()
--]]
local state = sol.state.create("running")
local hero_meta=sol.main.get_metatable("hero")
local jump_manager=require("scripts/jump_manager")
local audio_manager=require("scripts/audio_manager")
local map_tools=require("scripts/maps/map_tools")
state:set_can_control_direction(false)
state:set_can_control_movement(false)
state:set_can_use_item(false)
state:set_can_use_item("feather", true)
state:set_can_traverse("crystal_block", true)
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
function hero_meta.run(hero)
  local current_state=hero:get_state()
  if current_state~="custom" or hero:get_state_object():get_description()~="running" then
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

  local animation_set = entity:get_sprite("sword"):get_animation_set()
  local sprite = entity:create_sprite(animation_set, "running_sword")
  sprite:set_animation("sword_loading_walking")
  sprite:set_direction(direction)

  return sprite
end

function state:on_started()
--  print "Run, Forrest, ruuun !"
  local entity=state:get_entity()
  local game = state:get_game()
  local map = entity:get_map()
  local hero = map:get_hero()
  local sprite=entity:get_sprite("tunic")
  entity:get_sprite("trail"):set_animation("running") 
  sprite:set_animation("walking")

  --Start playing the running sound
  entity.run_sound_timer = sol.timer.start(state, 200, function()
      if not entity.is_jumping or entity:is_jumping()==false then
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

  --Prepare for running...
  entity.running_timer=sol.timer.start(state, 500, function() --start movement and pull out sword if any
      entity.running_timer=nil --TODO check if this isn't useless 
      entity.running=true
      local sword_sprite
      state:set_can_be_hurt(false)
      if game:get_ability("sword")>0 and game:has_item("sword") then
        sprite:set_animation("sword_loading_walking")
        sword_sprite = create_running_sword(hero, sprite:get_direction())
      end

      local m=sol.movement.create("straight")
      m:set_speed(196)
      m:set_angle(sprite:get_direction()*math.pi/2)

      -- Check if there is a collision with an enemy, then hurt it.
      function m:on_position_changed()
        for enemy in map:get_entities_by_type("enemy") do
          if hero:overlaps(enemy, "sprite") and enemy:get_life() > 0 and not enemy:is_immobilized() then
            local reaction = enemy:get_thrust_reaction()
            if reaction ~= "ignored" then
              enemy:receive_attack_consequence("thrust", reaction)
            end
          end
        end
      end

      function m:on_obstacle_reached()
        if not entity.bonking then
          --Bonk !
          entity:get_sprite("trail"):stop_animation()
          stop_sound_loop(entity)
          entity.bonking=true
          audio_manager:play_sound("hero/rebound")
          local map=entity:get_map()

          --Crash into entities (imported from the original custom script, don't know if it even works) 
          for e in map:get_entities_in_rectangle(entity:get_bounding_box()) do
            if entity:overlaps(e, "facing") then
              if e.on_boots_crash ~= nil then
                e:on_boots_crash()
              end
            end
          end

          --Shake the camera 
          --Note, the current implementation of the shake function was intended to be used on static screens, so until it's reworked, there will be some visual mishaps at the end of the effect (the camera will abruptly go back to the the hero)
          local camera=map:get_camera()
          camera:dynamic_shake({count = 50, amplitude = 2, speed = 90, entity=entity})
--        map_tools.start_earthquake({count = 8, amplitude = 4, speed = 90}) 

          --Play funny animation
          local collapse_sprite=entity:get_sprite("tunic"):set_animation("collapse")
          if sword_sprite then
            entity:remove_sprite(sword_sprite)
          end

          jump_manager.start_parabola(entity, 2, function()
              entity.bonking=nil
              audio_manager:play_sound("hero/land")
              entity:unfreeze()
              sol.timer.start(entity, 10, function()
                  entity:get_sprite():set_animation("collapse")
                end)
            end)
          entity:get_sprite():set_animation("collapse_pegasus")
        else
          --audio_manager:play_sound("hero/land")
          m:set_speed(88)
          m:set_angle(m:get_angle()+math.pi)
        end
      end

      --Run !
      m:start(entity)
    end)
end

--Stops the run when the player changes the diection
function state:on_command_pressed(command)
  local entity=state:get_entity()
  local game=entity:get_game()
  local s=entity:get_sprite()
  if not entity.bonking then
    for _,c in pairs(directions) do
      if c.key == command and c.direction~=s:get_direction() then
        entity:unfreeze()
        return true
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

  entity.running=nil
  entity:stop_movement()
end

