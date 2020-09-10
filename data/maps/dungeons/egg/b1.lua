-- Variables
local map = ...
local game = map:get_game()
local hero=map:get_hero()
local boss_path_index
local boss_path_step=1

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local separator_manager = require("scripts/maps/separator_manager")
local maze_paths = require("scripts/maps/lib/windfish_maze_config")

-- Map events
map:register_event("on_started", function()
    
  -- Music
  map:init_music()
  -- Separators
  separator_manager:init(map)
  -- Path
  boss_path_index=game:get_value("windfish_maze_boss_path_index") or math.random(#maze_paths)
  -- path generation should already been done unless we loaded an existing save created before this has been implemented
  
end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("74_wind_fish_egg")

end

local function check_boss_path_advancement(entity, direction)
  
  debug_print ("Testing path entry. Path ID="..boss_path_index..", path step="..boss_path_step)
  local expected=maze_paths[boss_path_index][boss_path_step]
  debug_print ("Expected direction : "..expected..", got "..direction)
  if expected==direction then
    debug_print "step OK"
    boss_path_step=boss_path_step+1
  else
    debug_print "Wrong path !"
    boss_path_step=1
  end

  if boss_path_step==8 then
    debug_print "To boss room"
    hero:teleport(map:get_id(), "boss_room_antichamber_"..direction, "immediate")
    --TODO teleport to pre-boss room
  else
    debug_print "To nowhere"
    hero:teleport(map:get_id(), "path_"..direction, "immediate")
  end
end
--TODO make actual maze progress processing 'as well as put the right names on entities

for i = 0, 2 do
  for  entity in map:get_entities("maze_path_"..i) do
    entity.direction = i
    function entity:on_activated()
      game:set_value("tp_ground", "traversable")
      check_boss_path_advancement(entity, entity.direction)
    end
  end
end

function maze_victory:on_activated()
  
  audio_manager:play_sound("misc/secret")
  boss_path_step = 1
  
end

function reset_path:on_activated()
  
  boss_path_step = 1
  
end