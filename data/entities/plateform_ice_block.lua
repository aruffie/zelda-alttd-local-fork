local entity = ...
local map = entity:get_map()
local game = entity:get_game()
local hero = map:get_hero()
local audio_manager = require("scripts/audio_manager")
local platform
local frozen=false
function entity:on_created()
  entity:set_traversable_by(true)
  entity:set_traversable_by("hero", false)
  entity:set_traversable_by("enemy", false)
  self:get_sprite():set_animation("normal")
  --Create a platform on it's top
  local x,y,w,h=self:get_bounding_box()
  --[[
  platform = self:get_map():create_custom_entity({
    x=x+8,
    y=y+13,
    layer= self:get_layer(),
    direction = 0,
    width = w,
    height= 8,
    model = "platform_thwomp",
  })

  platform:set_size(w,1)
  platform:set_origin(8,13)
  platform:set_enabled(self:is_enabled())
  --]]
end

function entity:on_position_changed()
  if platform then
    x, y=self:get_bounding_box()
    platform:set_position(x, y)
  end
end

function entity:on_removed()
  if platform then
   platform:remove()
  end
end

function entity:on_disbled()
  if platform then
    platform:set_enabled(false)
  end    
end

function entity:on_enabled()
  if platform then
    platform:set_enabled(true)
  end    
end

function entity:on_update()
  local x,y,w,h=entity:get_bounding_box()
  local hx, hy, hw, hh=hero:get_bounding_box()
  if hx<x+w+1 and hx+hw>x-1 and hy<=y+h-1 and hy+hh>=y+1 then
    if not(map.frozen) then
      print("Iced")
      game:start_dialog("entities.ice_block.frozen", function()
        map.frozen=true
      end)
    end
  end
end
return behavior

