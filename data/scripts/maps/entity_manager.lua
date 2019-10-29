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

function entity_manager:create_falling_entity(base_entity, sprite_name)
  --print "DOWN WE GOOOOOOooooooo........ !"
  local x, y, layer = base_entity:get_position()

  if not sprite_name then
    if base_entity:get_type()=="enemy" then
      sprite_name="enemies/"..base_entity:get_breed()
    else
      sprite_name=base_entity:get_sprite():get_animation_set()
    end
  end
  local falling_entity = base_entity:get_map():create_custom_entity({
      name="falling_entity_actor",
      sprite = sprite_name,
      x = x,
      y = y,
      width = 16,
      height = 16,
      layer = layer,
      direction = 0,
    })
  if falling_entity then --will be nil if the map is in finishing state
    falling_entity:set_can_traverse_ground("hole", true)
    entity_manager:fall(falling_entity)

  end
end

return entity_manager