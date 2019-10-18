-- Initialize block behavior specific to this quest.

-- Variables
local block_meta = sol.main.get_metatable("block")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function block_meta:on_removed()
  
  local game = self:get_game();
  local map = game:get_map()
  if self:get_ground_below()== 'hole' then
    local x, y, layer = self:get_position()
    local block_entity = map:create_custom_entity({
      name = "block",
      sprite = self:get_sprite():get_animation_set(),
      x = x,
      y = y,
      width = 16,
      height = 16,
      layer = layer,
      direction = 0
    })
    block_entity:set_can_traverse_ground("hole", true) 
    local sprite = block_entity:get_sprite()
    sprite:set_animation("falling")
    function sprite:on_animation_finished(animation)
      block_entity:remove()
    end
  end
  
end  

function block_meta:on_moving()
    
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