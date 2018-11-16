-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local fairy_manager = require("scripts/maps/fairy_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started()

  fairy_manager:init_map(map, "fairy")

end

-- NPC events
function fairy_fountain:on_activated()

  fairy_manager:launch_fairy_if_hero_not_max_life(map, "fairy")

end