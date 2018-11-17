-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local separator_manager = require("scripts/maps/separator_manager")
local audio_manager = require("scripts/audio_manager")

function map:on_started(destination)

  -- Music
  map:init_music()
  
 sol.timer.start(map, 2000, function()
  game:set_hud_enabled(true)
  game:set_pause_allowed(true)
 end)
 hero:set_enabled(true)
 local white_surface =  sol.surface.create(320, 256)
  local opacity = 255
  white_surface:fill_color({255, 255, 255})
  function map:on_draw(dst_surface)
    white_surface:set_opacity(opacity)
    white_surface:draw(dst_surface)
    opacity = opacity -1
    if opacity < 0 then
      opacity = 1
    end
  end

end

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("37_dream_shrine")

end

separator_manager:manage_map(map)