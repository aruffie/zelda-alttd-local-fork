--[[
Custom crystal block.

unlike the built-in crystal block, this model allows to :
  - jump between two of them when they are raised,
  - Pass through in debug mode (!)

--]]
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
require("scripts/multi_events")

local initially_raised
local raised
local sprite

function entity:setup_sprite()
  local suffix=raised and "raised" or "lowered"
  local prefix=initially_raised and "blue" or "orange"
  sprite:set_animation (prefix.."_"..suffix)
end

entity:register_event("on_created", function(entity)
    initially_raised=entity:get_property("initially_raised")=="true"
    raised=initially_raised ~= map:get_crystal_state()
    sprite=entity:get_sprite()
    print ('initially raised?', initially_raised)
    entity:setup_sprite()
    sprite:set_frame(sprite:get_num_frames()-1)
  end)

entity:set_traversable_by(function(other) 
    if not raised then --easy case, always let anything going through when lowered
      return true
    end
    local x,y,layer=other:get_position()
    local bx, by, bw, bh=other:get_bounding_box()
    local ex, ey, ew, eh=entity:get_bounding_box()

    local e_type=other:get_type()
    if e_type=="custom_entity" then
      local model=other:get_model()
      if model=="arrow" or model=="bomb_arrow" then
        return true
      end
    elseif e_type=="bomb" or e_type=="camera" then
      return true
    end
    if e_type=="hero" then
      if not other.on_crystal_block then 
        if bx+bw<=ex or bx>=ex+eh or by+bh<=ey or by>=ey+eh then
          return false 
          --outside the block collision range, do not allow to pass through
        else 
          return true
        end
      else
        return true --we are already on a block
      end


    end
    return false -- by default, do not let the other entity pass through
  end)

function entity:is_raised()
  return raised
end

function entity:notity_other_left(other)
  --TODO allow to play a custom animation
end

function entity:switch()
  raised=not raised
  entity:setup_sprite()
  if raised then
    for other in map:get_entities_in_rectangle(entity:get_bounding_box()) do
      if other:get_type()~="camera" and other~=entity and other:get_layer()==self:get_layer() then
        print ("found a "..other:get_type())
        other.on_crystal_block=true
      end
    end
  end
end

function entity:notify_crystal_state_changed()
  self:switch()   
end