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

entity:register_event("on_created", function(entity)
    initially_raised=entity:get_property("initially_raised")=="true"
    raised=initially_raised
    sprite=entity:get_sprite()
    if initially_raised then
      sprite:set_animation("blue_raised")
    else
      sprite:set_animation("orange_lowered")
    end
  end)


function entity:is_raised()
  return raised
end

function entity:change_position()
  raised=not raised
end