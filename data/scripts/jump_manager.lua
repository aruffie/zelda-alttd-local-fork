local jm={}

local y_accel = 0.3
local max_yvel = 5

function jm.update_jump(entity)
  entity.y_offset=entity.y_offset or 0
  for name, sprite in entity:get_sprites() do
    if name~="shadow" then
      sprite:set_xy(0, math.min(entity.y_offset, 0))
    end
  end
  entity.y_offset= entity.y_offset+entity.y_vel
  entity.y_vel = entity.y_vel + y_accel
  if entity.y_offset >=0 then
    for name, sprite in entity:get_sprites() do
      sprite:set_xy(0, 0)
    end    
    entity.jumping = false
    if not sol.main.get_game():is_command_pressed("attack") then
      entity:unfreeze()
      end
    return false
  end
  return true
end

function jm.start(entity)
  if not entity:is_jumping() then
    --   print "TOPVIEW JUMP"
    entity:set_jumping(true)
--    print "JUMP"
    entity.y_vel = -max_yvel
    sol.timer.start(entity, 10, function()
        local r=jm.update_jump(entity)
        if not r then
          return false
        end
        return true
      end)
  end
end
return jm