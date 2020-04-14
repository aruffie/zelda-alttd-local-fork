
--Options
local __enabled=true
local __show_hitbox=false
local __print=false
local __show_respawn_point=true

function debug_print(s, ...)
  if __enabled and __print then
    local prefix="["..sol.main.get_elapsed_time().."] "  
    print(prefix, s, ...)
  end
end

function show_hitbox(entity)
  if __enabled and __show_hitbox then --DEBUG : draw hitbox information
    entity.show_hitbox = true --Flag me as processed
    local w,h=entity:get_size()
    local hitbox_surface=sol.surface.create(w,h)
    local origin_x, origin_y=entity:get_origin()
    local border_color={255,0,0}
    local origin_color={0,255,0}
    --draw the hitbox
    hitbox_surface:fill_color(border_color, 0, 0, w,1)
    hitbox_surface:fill_color(border_color, 0, h-1, w,1)
    hitbox_surface:fill_color(border_color, 0, 0, 1,h)
    hitbox_surface:fill_color(border_color, w-1, 0, 1, h)
    --draw the origin (representing the actual position)
    hitbox_surface:fill_color(origin_color, 0, origin_y, w, 1)
    hitbox_surface:fill_color(origin_color, origin_x, 0 ,1,h)
    entity.debug_hitbox=hitbox_surface
    function entity:on_post_draw(camera)
      local cx,cy=camera:get_position()
      local x,y=entity:get_bounding_box()
      entity.debug_hitbox:draw(camera:get_surface(), x-cx, y-cy)
    end
  end
end
local rpoint_surface=sol.surface.create(16,16)
rpoint_surface:fill_color({0,255,0,64})
function show_respawn_ppint(entity)
  if __show_respawn_point then
    local map=entity:get_map()
    local x,y=entity:get_position()
    local origin_x, origin_y=entity:get_origin()
    map:draw_visual(rpoint_surface,x-origin_x, y-origin_y)
  end
end