-- Sets up all non built-in gameplay features specific to this quest.

-- Usage: require("scripts/features")

-- Features can be enabled to disabled independently by commenting
-- or uncommenting lines below.

require("scripts/debug")
require("scripts/equipment")
require("scripts/dungeons")
require("scripts/sleep")
require("scripts/maps/sideview_manager")
require("scripts/maps/main_quest_manager")
require("scripts/menus/dialog_box")
require("scripts/menus/pause/pause")
require("scripts/menus/game_over")
require("scripts/hud/hud")
require("scripts/meta/dynamic_tile")
require("scripts/meta/block")
require("scripts/meta/camera")
require("scripts/meta/door")
require("scripts/meta/enemy")
require("scripts/meta/hero")
require("scripts/meta/custom_state")
require("scripts/meta/game")
require("scripts/meta/item")
require("scripts/meta/pickable")
require("scripts/meta/map")
require("scripts/meta/npc")
require("scripts/meta/destructible")
require("scripts/meta/teletransporter")
require("scripts/meta/carried_object")
require("scripts/meta/sensor")
require("scripts/meta/switch")
require("scripts/maps/light_manager")
require("scripts/maps/unstable_floor_manager")
require("scripts/maps/companion_manager")
require("scripts/maps/teletransporter_manager")
require("scripts/maps/cinematic_manager")
require("scripts/coroutine_helper")
require("scripts/lib/iter.lua")() --adds iterlua to _G

require("scripts/tools/debug_utils")

return true
