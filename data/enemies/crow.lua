-- Variables
local enemy = ...

-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Initialize the properties of your enemy here,
  -- like the sprite, the life and the damage.
  local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(1)
  enemy:set_damage(1)
  enemy:set_obstacle_behavior("flying")

end

