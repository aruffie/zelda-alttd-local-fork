----------------------------------
--
-- Beetle.
--
-- Moves randomly over horizontal and vertical axis.
-- May exists in several color skins.
--
-- Methods : enemy:start_walking()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local quarter = math.pi * 0.5
local skins = {
  blue = "enemies/" .. enemy:get_breed(),
  red = "enemies/" .. enemy:get_breed() .. "/red",
  green = "enemies/" .. enemy:get_breed() .. "/green"
}

-- Configuration variables
local color = enemy:get_property("color")
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 48
local walking_minimum_distance = 16
local walking_maximum_distance = 96

-- Get a random color skin for the enemy.
local function get_random_color()

  local index = math.random(1, 3)
  local i = 1
  for skin, _ in pairs(skins) do
    if i == index then
      return skin
    end
    i = i + 1
  end
end

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  -- Set the requested color skin to the enemy or a random one.
  local skin = skins[color or get_random_color()]
  sprite = enemy:create_sprite(skin)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:start_walking()
end)
