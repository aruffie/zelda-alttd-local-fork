-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()

  item:set_sound_when_brandished(nil)

end

function item:on_obtaining(variant, savegame_variable)

  -- Sound
  audio_manager:play_sound("items/fanfare_item")
  -- Save the possession of the map in the current dungeon.
  local game = self:get_game()
  local dungeon = game:get_dungeon_index()
  if dungeon == nil then
    error("This map is not in a dungeon")
  end
  game:set_value("dungeon_" .. dungeon .. "_boss_key", true)
  
end

