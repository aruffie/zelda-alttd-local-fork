-- Initialize block behavior specific to this quest.

-- Variables
local block_meta = sol.main.get_metatable("block")
require("scripts/multi_events")
-- Include scripts
local audio_manager = require("scripts/audio_manager")
local entity_manager = require("scripts/maps/entity_manager")

function block_meta:on_removed()

  local game = self:get_game();
  local map = game:get_map()
  if self:get_ground_below()== 'hole' then
    entity_manager:create_falling_entity(self)
  end
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

  local ground = self:get_map():get_ground(x, y, layer)
  if ground == "hole" then
    audio_manager:play_sound("enemies/enemy_fall")
  end

end