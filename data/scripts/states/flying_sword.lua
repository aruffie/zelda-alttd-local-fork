local state = sol.state.create("jump")

local jm=require("scripts/jump_manager")

local state = jm.init("flying_sword")

local hero_meta= sol.main.get_metatable("hero")
local sword_sprite
local tunic_sprite

function hero_meta.start_flying_attack(hero)
  print "attack on air !"
  if hero:get_state()~="custom" or hero:get_state_object():get_description()~="flying_sword" then
    hero:start_state(state)
  end
  jm.start(hero)
end

function state:on_started(old_state_name, old_state_object)
  print "flying attaaaaack"
  local entity=state:get_entity()
  local game = state:get_game()
  local ability = game:get_ability("sword")

  tunic_sprite = entity:get_sprite("tunic")
  sword_sprite = entity:get_sprite("sword")
  sword_sprite:set_direction(tunic_sprite:get_direction())

  if old_state_name == "sword swinging" or old_state_name == "custom" and old_state_object:get_description() =="jump" then
    tunic_sprite:set_animation("sword", function()
        print "tunic attack finished"
        tunic_sprite:set_animation("sword_loading_stopped")
        sword_sprite:set_animation("sword_loading_stopped")
      end)
    sword_sprite:set_animation("sword")
--      , function()
--        print "sword attack finished"
--        sword_sprite:set_animation("sword_loading_stopped")
--      end)
  elseif old_state_name == "sword loading" then
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
      tunic_sprite:set_animation("stopped")

      entity:unfreeze()
    end
    return true
  end
end

function state:on_finished()
  sword_sprite:stop_animation()
  sword_sprite = nil
end