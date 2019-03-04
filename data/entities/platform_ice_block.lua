local entity = ...
local map = entity:get_map()
local game = entity:get_game()
local hero = map:get_hero()
local audio_manager = require("scripts/audio_manager")

local frozen=false
function entity:on_created()
  entity:set_traversable_by(true)
  entity:set_traversable_by("hero", false)
  entity:set_traversable_by("enemy", false)
  self:get_sprite():set_animation("normal")
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

