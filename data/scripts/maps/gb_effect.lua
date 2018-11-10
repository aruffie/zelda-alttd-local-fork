local gbeff = {}

local gbshader = sol.shader.create('gb')
local fac = gbshader:get_scaling_factor()

local qw,qh = sol.video.get_quest_size()
local previous = sol.surface.create(qw*fac,qh*fac)

gbshader:set_uniform('previous',previous)
gbshader:set_uniform('persistence',0.9)

local big_dst = sol.surface.create(previous:get_size())
local enabled

local main_surface
local function on_main_draw(_,dst)
  main_surface = dst
  if enabled then
    dst:set_shader(gbshader)
    dst:set_scale(fac,fac)
    dst:draw(big_dst)
    big_dst:set_scale(1,1)
    big_dst:draw(previous)
  end
end

function sol.video:on_draw(dst)
  if enabled then
    local bw,bh = big_dst:get_size()
    local dw,dh = dst:get_size()
    
    big_dst:set_scale(dw/bw,dh/bh)
    big_dst:draw(dst)
  end
end

local inited
local function init()
  if inited then
    return
  end
  sol.main:register_event('on_draw',on_main_draw)
end

local previous_shader
function gbeff:on_map_changed(map)
  init()
  enabled = true
end

function gbeff:on_map_draw(map,dst)
end

function gbeff:clean(map)
  enabled = false
  --sol.video.set_shader(previous_shader)
end

return gbeff