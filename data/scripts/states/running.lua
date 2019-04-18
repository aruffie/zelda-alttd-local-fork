local state = sol.state.create("running")
local hero_meta=sol.main.get_metatable("hero")
local jm=require("scripts/jump_manager")

state:set_can_control_direction(false)
state:set_can_control_movement(false)
state:set_can_use_item("feather", true)
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

function hero_meta.run(hero)
  if not hero.running then
    hero:start_state(state)
  end
end

function state:on_started()
--  print "Run, Forrest, ruuun !"
  local entity=state:get_entity()
  local game = state:get_game()
  local sprite=entity:get_sprite("tunic")
  sprite:set_animation("walking")
  sol.timer.start(entity, 500, function() --start movement and pull out sword if any
      if game:get_ability("sword")>0 and game:has_item("sword") then
        sprite:set_animation("sword_loading_walking")
        local sword_sprite = entity:get_sprite("sword")
        sword_sprite:set_animation("sword_loading_walking")
        sword_sprite:set_direction(sprite:get_direction())
      end

      local m=sol.movement.create("straight")
      m:set_speed(100)
      local direction =entity:get_sprite("tunic"):get_direction()
      local angle = direction*math.pi/2
--      print (angle)
      m:set_angle(angle)
      m:start(entity)
      function m:on_obstacle_reached()
--        print ("BONK")
        local parabola=sol.movement.create("jump")
        parabola:set_distance(32)
        parabola:set_direction8(2*((direction+2)%4))
        parabola:start(entity, function()
            entity:unfreeze()
          end)
      end
    end)
end

function state:on_command_pressed(command)
  print "command ? "
  local entity=state:get_entity()
  local game=entity:get_game()
  local s=entity:get_sprite()
  for _,c in pairs(directions) do
    if c.key == command and c.direction~=s:get_direction() then
      entity:unfreeze()
      return true
    end
  end
end

function state:on_finished()
  local entity=state:get_entity()
  entity:stop_movement()
end

