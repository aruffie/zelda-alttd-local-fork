local state = sol.state.create("running")
local hero_meta=sol.main.get_metatable("hero")
local jump_manager=require("scripts/jump_manager")
local map_tools=require("scripts/maps/map_tools")
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
  local current_state=hero:get_state()
  if current_state~="custom" or hero:get_state_object():get_description()~="running" then
    hero:start_state(state)
  end
end

function state:on_started()
--  print "Run, Forrest, ruuun !"
  local entity=state:get_entity()
  local game = state:get_game()
  local sprite=entity:get_sprite("tunic")
  sprite:set_animation("walking")
  entity.running_timer=sol.timer.start(entity, 500, function() --start movement and pull out sword if any
      entity.running_timer=nil
      entity.running=true
      if game:get_ability("sword")>0 and game:has_item("sword") then
        sprite:set_animation("sword_loading_walking")
        local sword_sprite = entity:get_sprite("sword")
        sword_sprite:set_animation("sword_loading_walking")
        sword_sprite:set_direction(sprite:get_direction())
      end

      local m=sol.movement.create("straight")
      m:set_speed(196)
      local direction =entity:get_sprite("tunic"):get_direction()
      local angle = direction*math.pi/2
--      print (angle)
      m:set_angle(angle)
      m:start(entity)
      function m:on_obstacle_reached()
        entity.bonking=true
--        print ("BONK")
local map=entity:get_map()
        for e in map:get_entities_in_rectangle(entity:get_bounding_box()) do
          if entity:overlaps(e, "facing") then
            if e.on_boots_crash ~= nil then
              e:on_boots_crash()
            end
          end
        end
        local camera=map:get_camera()
        camera:shake({count = 8, amplitude = 4, speed = 90})
--        map_tools.start_earthquake({count = 8, amplitude = 4, speed = 90}) 
        local collapse_sprite=entity:get_sprite("tunic"):set_animation("collapse")
        entity:get_sprite("sword"):stop_animation()        
        local parabola=sol.movement.create("jump")
        parabola:set_distance(32)
        parabola:set_direction8(2*((direction+2)%4))
        parabola:start(entity, function()
            --      entity:remove_sprite(collapse_sprite)
            entity:unfreeze()
            entity.bonking=false
          end)
      end
    end)
end

function state:on_command_pressed(command)
  local entity=state:get_entity()
  local game=entity:get_game()
  local s=entity:get_sprite()
  if entity.bonking~=true then
    for _,c in pairs(directions) do
      if c.key == command and c.direction~=s:get_direction() then
        entity:unfreeze()
        return true
      end
    end
  end
end
function state:on_command_released(command)
  if command == "action" then
    local entity=state:get_entity()
    if entity.running_timer~=nil then
      entity:unfreeze()
    end
  end
end
function state:on_finished()
  local entity=state:get_entity()
  if entity.running_timer~=nil then
    entity.running_timer:stop()
    entity.running_timer=nil
  end
  entity.running=nil
  entity:stop_movement()
end

