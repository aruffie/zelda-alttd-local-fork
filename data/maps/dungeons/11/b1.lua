-- Lua script of map dungeons/11/b1.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
local hero=map:get_hero()
local maze_paths=require("scripts/maps/lib/windfish_maze_config")
local audio_manager=require("scripts/audio_manager")
local boss_path_index
local boss_path_step=1

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  boss_path_index=1 --todo retrieve actual index from savegame
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end

local function check_boss_path_advancement(entity, direction)
  print ("Testing path entry. Path ID="..boss_path_index..", path step="..boss_path_step)
  local expected=maze_paths[boss_path_index][boss_path_step]
  print ("Expected direction : "..expected..", got "..direction)
  if expected==direction then
    print "step OK"
    boss_path_step=boss_path_step+1
  else
    print "Wrong path !"
    boss_path_step=1
  end

  if boss_path_step==8 then
    print "To boss room"
    hero:teleport(map:get_id(), "boss_room_antichamber_"..direction, "immediate")
    --TODO teleport to pre-boss room
  else
    print "To nowhere"
    hero:teleport(map:get_id(), "path_"..direction, "immediate")
  end
end
--TODO make actual maze progress processing 'as well as put the right names on entities

for i = 0, 2 do
  for  entity in map:get_entities("maze_path_"..i) do
    entity.direction=i
    function entity:on_activated()
      check_boss_path_advancement(entity, entity.direction)
    end
  end
end

function maze_victory:on_activated()
  audio_manager:play_sound("misc/secret")
  boss_path_step=1
end

function reset_path:on_activated()
  boss_path_step=1
end