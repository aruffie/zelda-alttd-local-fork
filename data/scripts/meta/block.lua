-- Initialize block behavior specific to this quest.

-- Variables
local block_meta = sol.main.get_metatable("block")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function block_meta:on_moving()
    
  audio_manager:play_sound("others/rock_push")
      
end

function block_meta:on_position_changed(x, y, layer)
    
  local map = self:get_map()
  local ground = map:get_ground(x, y, layer)
  if ground == "hole" then
    audio_manager:play_sound("enemies/enemy_fall")
  end
      
end