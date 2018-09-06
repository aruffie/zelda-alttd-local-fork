-- Lua script of custom light light.
-- This script is executed every time a custom light with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local light = ...
local game = light:get_game()
local map = light:get_map()
local light_mgr = require('scripts/lights/light_manager.lua')

local radius = tonumber(light:get_property('radius')) or 120
local size = radius*2
local color_str = light:get_property('color') or '255,255,255'
local color = {color_str:match('(%d+),(%d+),(%d+)')}
for i,k in ipairs(color) do
  color[i] = k/256.0
end

light:set_can_traverse(true)

--set light properties
light.radius = radius
light.color = color
light.excluded_occs = {}

local x,y = light:get_position()

local fire_dist = sol.shader.create('fire_dist')
local fire_sprite = light:get_sprite()
light:remove_sprite(fire_sprite)
fire_sprite:set_shader(fire_dist)

-- Event called when the custom light is initialized.
function light:on_created()
  -- Initialize the properties of your custom light here,
  -- like the sprite, the size, and whether it can traverse other
  -- entities and be traversed by them.
  light_mgr:add_light(self,light:get_name())
end

function light:draw_visual(dst,drawable,x,y)
  local cx,cy = map:get_camera():get_position()
  drawable:draw(dst,x-cx,y-cy)
end

function light:get_topleft()
  local lx,ly,ll = self:get_position()
  return lx-radius,ly-radius,ll
end

function light:draw_light(dst)
  -- get the shadow_map for this light
  local shad_map = light_mgr:compute_light_shadow_map(light)

  --draw 1D shadow as additive shadows
  self:draw_visual(dst,shad_map, self:get_topleft())
end

function light:draw_disturb(dst)
  self:draw_visual(dst,fire_sprite,self:get_position())
end
