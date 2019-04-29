-- Lua script of enemy maskass.
-- This script is executed every time an enemy with this model is created.

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

-- The enemy appears: set its properties.
function enemy:on_created()

  -- Initialize the properties of your enemy here,
  -- like the sprite, the life and the damage.
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  self:set_life(1)
  self:set_damage(1)
  enemy:set_attack_consequence("arrow", "custom")
  enemy:set_attack_consequence("boomerang", "custom")
  --enemy:set_attack_consequence("sword", "custom")
  enemy:set_attack_consequence("thrown_item", "custom")
  enemy:set_fire_reaction("custom")
  enemy:set_hammer_reaction("custom")
  enemy:set_hookshot_reaction("custom")

end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()
  
  local sprite = enemy:get_sprite()
  sprite:set_animation("walking")
  sprite:set_paused(true)
  movement = sol.movement.create("target")
  local x_hero, y_hero = hero:get_position()
  sol.timer.start(enemy, 50, function()
    -- Sprite direction
    local direction = hero:get_direction()
    direction = (direction+2)%4
    sprite:set_direction(direction)
    -- Enemy movement
    local x_new_hero, y_new_hero = hero:get_position()
    local x_enemy, y_enemy = enemy:get_position()
    local diff_x = x_new_hero - x_hero
    local diff_y = y_new_hero - y_hero
    if diff_x ~= 0 or diff_y  ~= 0 then
      sprite:set_paused(false)
    else
      sprite:set_paused(true)
    end
    x_enemy = x_enemy - diff_x
    y_enemy = y_enemy - diff_y
    movement:set_target(x_enemy, y_enemy)
    movement:set_speed(200)
    movement:start(enemy)
    x_hero = x_new_hero
    y_hero  = y_new_hero
    return true
  end)

end