-- Lua script of enemy flying tile.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local shadow_sprite = nil
local initial_y = nil
local state = nil  -- "raising", "attacking" or "destroying".

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy.state = state
  enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_invincible()
  enemy:set_attack_consequence("sword", "custom")
  shadow_sprite = sol.sprite.create("entities/shadows/shadow")
  shadow_sprite:set_animation("big")
  
end)

-- The enemy was stopped for some reason and should restart.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_can_attack(false)
  enemy:set_invincible()
  enemy:set_visible(false)
end)

-- Make the enemy start attacking.
enemy:register_event("start_attacking", function(enemy)

  local x, y = enemy:get_position()
  initial_y = y

  local m = sol.movement.create("straight")
  m:set_max_distance(16)
  m:set_angle(math.pi * 0.5)
  m:set_speed(16)
  m:start(enemy:get_sprite()) -- Start the movement on the sprite instead of the enemy to be able to fly when the north of the enemy is against an obstacle.
  sol.timer.start(enemy, 2000, function() enemy:go_hero() end)
  enemy.state = "raising"

  enemy:set_visible()
  enemy:set_can_attack(true)
  enemy:set_hero_weapons_reactions({
    sword = 1,
    shield = function() enemy:disappear() end
  })
end)

function enemy:go_hero()

  local hero = enemy:get_map():get_entity("hero")
  local angle = enemy:get_angle(hero)
  local m = sol.movement.create("straight")
  m:set_speed(192)
  m:set_angle(angle)
  m:set_smooth(false)
  m:start(enemy)
  enemy.state = "attacking"

  -- Workaround : Manually use a sprite collision between the hero and the flying tile to be able to hurt when the south of the hero is against a obstacle.
  local sprite = enemy:get_sprite()
  local hero_sprite = hero:get_sprite("tunic")
  enemy:set_can_attack(false)
  function m:on_position_changed()
    if enemy:overlaps(hero, "sprite", sprite, hero_sprite) then
      enemy:on_attacking_hero(hero, sprite)
      enemy:disappear()
    end
  end
end

enemy:register_event("on_obstacle_reached", function(enemy)
  
  enemy:disappear()
  
end)

enemy:register_event("on_custom_attack_received", function(enemy, attack, sprite)

  if enemy.state == "attacking" then
    enemy:disappear()
  end
  
end)

function enemy:disappear()

  if enemy.state ~= "destroying" then
    enemy.state = "destroying"
    local sprite = enemy:get_sprite()
    enemy:set_attack_consequence("sword", "ignored")
    enemy:set_can_attack(false)
    enemy:stop_movement()
    enemy:set_invincible()
    sprite:set_animation("destroy", function()
      enemy:start_death()
    end)
    audio_manager:play_entity_sound(enemy, "stone")
    sol.timer.stop_all(enemy)
    if enemy.on_flying_tile_dead ~= nil then
      enemy:on_flying_tile_dead()
    end
  end
  
end

enemy:register_event("on_pre_draw", function(enemy)

  -- Show the shadow.
  if enemy.state ~= "destroying" then
    local x, y = enemy:get_position()
    enemy:get_map():draw_visual(shadow_sprite, x, y)
  end
  
end)

