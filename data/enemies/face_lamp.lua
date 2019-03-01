local enemy = ...

local behavior = require("enemies/lib/fire_breathing_statue")

local properties = {
  sprite = "enemies/" .. enemy:get_breed(),
  projectile_breed = "fireball_small_triple_red",
  projectile_sound = "enemies/face_lamp",
}

behavior:create(enemy, properties)