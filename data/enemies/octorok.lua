-- Lua script of enemy "octorok".
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...

local children = {}
local can_shoot = true
local position_x, position_y = enemy:get_position()
local distance_max = 100
local previous_on_removed = enemy.on_removed

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function enemy:on_created()

  enemy:set_life(1)
  enemy:set_damage(1)
  enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_can_be_pushed_by_shield(true)

end

local function go_hero()

  local sprite = enemy:get_sprite()
  sprite:set_animation("walking")
  local movement = sol.movement.create("random")
  movement:set_speed(64)
  movement:start(enemy)
  
end

local function shoot()

  local map = enemy:get_map()
  local hero = map:get_hero()
  if not enemy:is_in_same_region(hero) then
    return true  -- Repeat the timer.
  end

  local sprite = enemy:get_sprite()
  local x, y, layer = enemy:get_position()
  local direction = sprite:get_direction()

  -- Where to create the projectile.
  local dxy = {
    {  8,  -4 },
    {  0, -13 },
    { -8,  -4 },
    {  0,   0 },
  }

  sprite:set_animation("shooting")
  enemy:stop_movement()
  sol.timer.start(enemy, 300, function()
    audio_manager:play_sound("others/rock_shatter")
    local stone = enemy:create_enemy({
      breed = "octorok_stone",
      x = dxy[direction + 1][1],
      y = dxy[direction + 1][2],
    })
    children[#children + 1] = stone
    stone:go(direction)

    sol.timer.start(enemy, 500, go_hero)
  end)

end

function enemy:on_restarted()

  local map = enemy:get_map()
  local hero = map:get_hero()
  go_hero()
  can_shoot = true
  sol.timer.start(enemy, 100, function()

    local hero_x, hero_y = hero:get_position()
    local x, y = enemy:get_center_position()

    if can_shoot then
      local aligned = (math.abs(hero_x - x) < 16 or math.abs(hero_y - y) < 16)
      if aligned and enemy:get_distance(hero) < 200 then
        shoot()
        can_shoot = false
        sol.timer.start(enemy, 1500, function()
          can_shoot = true
        end)
      end
    end
    return true  -- Repeat the timer.
  end)
end

function enemy:on_movement_changed(movement)

  local direction4 = movement:get_direction4()
  local sprite = enemy:get_sprite()
  sprite:set_direction(direction4)
end

function enemy:on_position_changed(movement)

  local position_current_x, position_current_y = enemy:get_position()
  if math.abs(position_x - position_current_x) > distance_max or math.abs(position_y - position_current_y) > distance_max  then
    local movement = sol.movement.create("target")
    movement:set_target(position_x, position_y)
    movement:set_speed(64)
    movement:start(enemy)
  end
  
end

function enemy:on_removed()

  if previous_on_removed then
    previous_on_removed(enemy)
  end

  for _, child in ipairs(children) do
    child:remove()
  end
  
end