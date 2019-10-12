local map = ...
local game = map:get_game()
local hero=map:get_hero()
local maze_paths=require("scripts/maps/lib/windfish_maze_config")
local audio_manager=require("scripts/audio_manager")
local boss_path_index
local boss_path_step=1

function map:on_started()
  boss_path_index=game:get_value("windfish_maze_boss_path_index")
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
      game:set_value("tp_ground", "traversable")
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