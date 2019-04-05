-- Variables
local map = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local owl_manager = require("scripts/maps/owl_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local separator_manager = require("scripts/maps/separator_manager")
require("scripts/multi_events")

-- Map events
function map:on_started()

  -- Heart
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Music
  game:play_dungeon_music()
  -- Owls
  owl_manager:init(map)
  -- Separators
  separator_manager:init(map)

end

function map:on_opening_transition_finished(destination)

  if destination == dungeon_8_1_B then
    game:start_dialog("maps.dungeons.8.welcome")
  end

end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_8_big_treasure" then
    treasure_manager:get_instrument(map)
  end

end