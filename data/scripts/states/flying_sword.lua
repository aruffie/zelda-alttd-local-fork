local state = sol.state.create("jump")

local jm=require("scripts/jump_manager")

state:set_can_use_item(false)
state:set_can_control_movement(true)
state:set_can_control_direction(false)

state:set_affected_by_ground("hole", false)
state:set_affected_by_ground("lava", false)
state:set_affected_by_ground("deep_water", false)

local previous_sprites = {}

local hero_meta= sol.main.get_metatable("hero")
local sword_sprite
local tunic_sprite
function hero_meta.start_flying_attack(hero)
  jm.start(hero)
  print "attack on air !"
  hero:start_state(state)
end

function state:on_started(old_state_name, old_state_object)
  print "flying attaaaaack"
  local entity=state:get_entity()
  local game = state:get_game()
  local ability = game:get_ability("sword")

  tunic_sprite = entity:get_sprite("tunic")
  sword_sprite = entity:get_sprite("sword")
  sword_sprite:set_direction(tunic_sprite:get_direction())

  if old_state_name == "sword swinging" or old_state_name == "custom" and old_state_object:get_description() == "jump" then
    tunic_sprite:set_animation("sword", "sword_loading_stopped") 
    sword_sprite:set_animation("sword", "sword_loading_stopped")
  else
    tunic_sprite:set_animation("sword_loading_stopped")
    sword_sprite:set_animation("sword_loading_stopped")
  end
end

function state:on_command_released(command)
  local entity=state:get_entity()
  if command =="attack" then
    if entity:is_jumping() then
      entity:start_jumping()
    else
      tunic_sprite = entity:get_sprite("tunic")
      sword_sprite = entity:get_sprite("sword")
      sword_sprite:set_direction(tunic_sprite:get_direction())

      tunic_sprite:set_animation("stopped")

      entity:unfreeze()
    end
    return true
  end
end

function state:on_finished()
  sword_sprite = nil
end