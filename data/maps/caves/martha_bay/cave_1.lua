-- Variables
local map = ...
local game = map:get_game()

-- Includes scripts
local separator_manager = require("scripts/maps/separator_manager")

separator_manager:manage_map(map)