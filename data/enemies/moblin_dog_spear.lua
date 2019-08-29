-- Lua script of enemy moblin dog spear.
-- This script is executed every time an enemy with this model is created.

local enemy = ...
require("enemies/lib/spear_moblin").apply(enemy)