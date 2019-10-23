-- Initialize block behavior specific to this quest.

-- Variables
local block_meta = sol.main.get_metatable("block")
require("scripts/multi_events")
-- Include scripts
local audio_manager = require("scripts/audio_manager")
local entity_manager = require("scripts/maps/entity_manager")
local math_utils = require("scripts/lib/math_utils")

function block_meta:on_created()
  self:set_drawn_in_y_order()
end

function block_meta:on_removed()

  local game = self:get_game();
  local map = game:get_map()
  if self:get_ground_below()== 'hole' then
    entity_manager:create_falling_entity(self)
  end
end
function block_meta:on_movement_started(movement)
  movement:set_ignore_obstacles()
  end

function block_meta:on_moving()
  self.movement_start_x, self.movement_start_y = self:get_position()
  local x_start, y_start = self:get_position() 
  sol.timer.start(self, 50, function()
      local x_end, y_end = self:get_position()  
      if x_start ~= x_end or y_start ~= y_end then
        audio_manager:play_sound("misc/rock_push")
      end
    end)

end



function block_meta:on_position_changed(x, y, layer)

  --local moving_direction=self:get_movement():get_direction4() --BROKEN, the block mvement returns wrong object
  --local moving_direction=math_utils.angle_to_direction4((self:get_angle(self.movement_start_x, self.movement_start_y)+math.pi))
  local moving_direction=self:get_direction4_to(self.movement_start_x, self.movement_start_y)
  local directions={{1,0},{0,-1},{-1,0},{0,1}}
  if true or self:get_movement():get_ignore_obstacles() then --BROKEN see above why
    local bx,by,bh,bw=self:get_bounding_box()
    local dx, dy=unpack(directions[moving_direction+1])
    for e in self:get_map():get_entities_in_rectangle(bx, by, bw, bh) do --push any enemy which gets overlapped by the block
      if e:get_type()=="enemy" then
        local ex,ey=e:get_position()
        e:set_position(ex+dx, ey+dy)

      end
    end
  end

end