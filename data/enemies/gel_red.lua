-- Variables
local enemy = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local behavior = require("enemies/lib/towards_hero")

-- Event called when the enemy is initialized.
function enemy:on_created()

  local properties = {
    sprite = "enemies/" .. enemy:get_breed(),
    life = 1,
    damage = 1,
    normal_speed = 16,
    faster_speed = 16,
  }
  behavior:create(enemy, properties)

end