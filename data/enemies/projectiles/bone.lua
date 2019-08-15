local enemy = ...
local main_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local audio_manager = require("scripts/audio_manager")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

-- Initialization.
function enemy:on_created()

  enemy:set_life(1)
end

-- Start going to the hero
function enemy:go()

  local movement = sol.movement.create("straight")
  movement:set_speed(192)
  movement:set_angle(enemy:get_angle(hero))
  movement:set_smooth(false)

  function movement:on_obstacle_reached()
    enemy:remove()
  end

  movement:start(enemy)
end

-- Restart settings.
function enemy:on_restarted()

  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_hurt_hero_running(true)
  enemy:set_minimum_shield_needed(1)
  enemy:go()
  main_sprite:set_animation("default")
end

-- Destroy the enemy when the hero is touched.
function enemy:on_attacking_hero(hero, enemy_sprite)
  enemy:remove()
end
