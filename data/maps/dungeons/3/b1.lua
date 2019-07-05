-- Variables
local map = ...
local game = map:get_game()
local is_boss_active = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local owl_manager = require("scripts/maps/owl_manager")
local separator_manager = require("scripts/maps/separator_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
require("scripts/multi_events")

-- Map events
function map:on_started()

  -- Doors
  door_manager:open_when_enemies_dead(map,  "enemy_group_4_",  "door_group_1_")
  door_manager:open_if_boss_dead(map)
  -- Heart
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Music
  game:play_dungeon_music()
  -- Owls
  owl_manager:init(map)
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_2")
  treasure_manager:disappear_pickable(map, "pickable_small_key_7")
  treasure_manager:disappear_pickable(map, "heart_container")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_2_", "pickable_small_key_2")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_5_", "pickable_small_key_7")
  -- Separators
  separator_manager:init(map)

end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_3_big_treasure" then
    treasure_manager:get_instrument(map)
  end

end

-- Sensors events
sensor_1:register_event("on_activated", function()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)
  end

end)