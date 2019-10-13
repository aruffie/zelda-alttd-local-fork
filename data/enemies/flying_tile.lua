-- Lua script of enemy flying tile.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local shadow_sprite = nil
local initial_y = nil
local state = nil  -- "raising", "attacking" or "destroying".

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- The enemy appears: set its properties.
function enemy:on_created()

  self:set_life(1)
  self:set_damage(2)
  self:set_enabled(false)
  self:set_obstacle_behavior("flying")
  self.state = state

  local sprite = self:create_sprite("enemies/" .. enemy:get_breed())
  function sprite:on_animation_finished(animation)
    if enemy.state == "destroying" then
      enemy:remove()
    end
  end

  self:set_size(16, 16)
  self:set_origin(8, 13)
  self:set_invincible()
  self:set_attack_consequence("sword", "custom")
  shadow_sprite = sol.sprite.create("entities/shadows/shadow")
  shadow_sprite:set_animation("big")
  
end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  local x, y = self:get_position()
  initial_y = y

  local m = sol.movement.create("path")
  m:set_path{2,2}
  m:set_speed(16)
  m:start(self)
  sol.timer.start(self, 2000, function() self:go_hero() end)
  enemy.state = "raising"
  
end

function enemy:go_hero()

  local angle = self:get_angle(self:get_map():get_entity("hero"))
  local m = sol.movement.create("straight")
  m:set_speed(192)
  m:set_angle(angle)
  m:set_smooth(false)
  m:start(self)
  enemy.state = "attacking"
  
end

function enemy:on_obstacle_reached()
  
  self:disappear()
  
end

function enemy:on_custom_attack_received(attack, sprite)

  if enemy.state == "attacking" then
    self:disappear()
  end
  
end

function enemy:disappear()

  if enemy.state ~= "destroying" then
    enemy.state = "destroying"
    local sprite = self:get_sprite()
    self:set_attack_consequence("sword", "ignored")
    self:set_can_attack(false)
    self:stop_movement()
    sprite:set_animation("destroy")
    audio_manager:play_entity_sound(enemy, "stone")
    sol.timer.stop_all(self)
    if enemy.on_flying_tile_dead ~= nil then
      enemy:on_flying_tile_dead()
    end
  end
  
end

function enemy:on_pre_draw()

  -- Show the shadow.
  if enemy.state ~= "destroying" then
    local x, y = self:get_position()
    if enemy.state == "attacking" then
      y = y + 16
    else
      y = initial_y or y
    end
    self:get_map():draw_visual(shadow_sprite, x, y)
  end
  
end

