-- Initialize block behavior specific to this quest.

-- Variables
local block_meta = sol.main.get_metatable("block")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function block_meta:on_moving()
    
  local x_start, y_start = self:get_position() 
  print(x_start .. " - " .. y_start)
  sol.timer.start(self, 50, function()
    local x_end, y_end = self:get_position()  
    if x_start ~= x_end or y_start ~= y_end then
      audio_manager:play_sound("others/rock_push")
    end
  end)
      
end

function block_meta:on_position_changed(x, y, layer)
    
  local ground = self:get_map():get_ground(x, y, layer)
  if ground == "hole" then
    audio_manager:play_sound("enemies/enemy_fall")
  end
      
end