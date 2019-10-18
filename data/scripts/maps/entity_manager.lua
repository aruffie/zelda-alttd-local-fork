local entity_manager={}
local audio_manager=require("scripts/audio_manager")
function entity_manager:fall(entity)
  local sprite = entity:get_sprite()
  if sprite:has_animation("falling") then
    audio_manager:play_sound("enemies/falling")
    sprite:set_animation("falling", function()
        entity:remove()
      end)
  else
    --print "Warning : \"falling\" animation not found"
    entity:remove()
  end
end

function entity_manager:create_falling_entity(base_entity)
  local x, y, layer = base_entity:get_position()
  local sprite
  
  if base_entity:get_type()=="enemy" then
    sprite="enemies/"..base_entity:get_breed()
  else
    sprite=base_entity:get_sprite():get_animation_set()
  end
  
  local falling_entity = base_entity:get_map():create_custom_entity({
      name="falling_entity",
      sprite = sprite,
      x = x,
      y = y,
      width = 16,
      height = 16,
      layer = layer,
      direction = 0
    })

  falling_entity:set_can_traverse_ground("hole", true)
  if base_entity:get_type()=="block" then
    falling_entity:set_traversable_by("hero", false)
    local m=sol.movement.create("straight")
    if x~=base_entity.movement_start_x then
      m:set_max_distance(16-math.abs(x-base_entity.movement_start_x))
    elseif y~=base_entity.movement_start_y then
      m:set_max_distance(16-math.abs(y-base_entity.movement_start_y))
    end
    print ("distance to go: "..m:get_max_distance())
    m:set_angle(base_entity:get_angle(base_entity.movement_start_x, base_entity.movement_start_y)+math.pi)
    m:register_event("on_obstacle_reached", function()
        print "obstacle_reached"
        entity_manager:fall(falling_entity)       
      end)
    m:start(falling_entity, function()
        print "movement over"
        entity_manager:fall(falling_entity)
      end)
  else
    entity_manager:fall(falling_entity)
  end
end

return entity_manager