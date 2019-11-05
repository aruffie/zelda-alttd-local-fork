local __debug=true
local __show_hitbox=false

function debug_print(s, ...)
  if __debug then
    local prefix="["..sol.main.get_elapsed_time().."] "  
    print(prefix, s, ...)
  end
end

function show_hitbox(entity)
  if __debug and __show_hitbox then --DEBUG : draw hitbox information
    entity.show_hitbox = true --Flag me s processed
    local w,h=entity:get_size()
    local s=sol.surface.create(w,h)
    local ox, oy=entity:get_origin()
    local b={255,0,0}
    local c={0,255,0}
    --draw the hitbox
    s:fill_color(b, 0, 0, w,1)
    s:fill_color(b, 0, h-1, w,1)
    s:fill_color(b, 0, 0, 1,h)
    s:fill_color(b, w-1, 0, 1, h)
    --draw the origin (representing the actual position)
    s:fill_color(c, 0, oy, w, 1)
    s:fill_color(c, ox, 0 ,1,h)
    entity.debug_hitbox=s
    function entity:on_post_draw(camera)
      local cx,cy=camera:get_position()
      local x,y=entity:get_bounding_box()
      entity.debug_hitbox:draw(camera:get_surface(), x-cx, y-cy)
    end
  end
end