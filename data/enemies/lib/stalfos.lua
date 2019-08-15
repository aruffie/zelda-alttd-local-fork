----------------------------------
--
-- Add stalfos behavior to an ennemy.
--
-- Usage : 
-- local my_enemy = ...
-- local behavior = require("enemies/lib/stalfos")
-- behavior.apply(my_enemy)
--
----------------------------------

-- Global variables
local behavior = {}
local common_actions = require("enemies/lib/common_actions")

function behavior.apply(enemy)

  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

  -- Initialization.
  function enemy:on_created()

    common_actions.learn(enemy, sprite)
    enemy:set_life(3)
    enemy:add_shadow()
  end

  -- Restart settings.
  function enemy:on_restarted()

    -- Behavior for each items.
    enemy:set_attack_consequence("sword", 1)
    enemy:set_attack_consequence("thrown_item", 2)
    enemy:set_attack_consequence("arrow", 2)
    enemy:set_attack_consequence("hookshot", 2)
    enemy:set_attack_consequence("fire", 2)
    enemy:set_attack_consequence("boomerang", 2)
    enemy:set_attack_consequence("explosion", 2)
    enemy:set_hammer_reaction(2)
    enemy:set_fire_reaction("protected")

    -- States.
    enemy:set_can_attack(true)
    enemy:set_damage(1)
    enemy:start_walking()
  end
end

return behavior
