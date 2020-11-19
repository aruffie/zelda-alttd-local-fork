----------------------------------
--
-- Boo buddy.
--
-- Slowly moves to the hero and respawn symmetrically about the center of the room when attacked.
-- Has to be set_weak() manually from outside this script to be vulnerable.
--
-- Methods : enemy:is_weak()
--           enemy:set_weak(weak)
--           enemy:start_walking()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_weak = false

-- Configuration variables
local flying_speed = 60
local flying_weak_speed = 20
local flying_height = 8
local blinking_duration = 1000

-- Start the enemy go away movement.
local function go_away()

  local angle = hero:get_angle(enemy)
  local movement = enemy:start_straight_walking(angle, flying_weak_speed)
  movement:set_ignore_obstacles(true)
  sprite:set_animation("weak_walking")

  -- Die if fully out of the screen while moving away.
  function movement:on_position_changed()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      enemy:start_death()
    end
  end
end

-- Make the enemy respawn at the other side of the room.
local function on_inoffensive_attack()

  enemy:stop_movement()
  enemy:set_can_attack(false)
  enemy:set_damage(0)
  enemy:set_invincible()
  sprite:set_animation("respawning")
  sol.timer.start(enemy, blinking_duration, function()
    if not is_weak then
      local x, y, width, height = camera:get_bounding_box()
      enemy:set_position(enemy:get_central_symmetry_position(x + width / 2.0, y + height / 2.0))
      enemy:restart()
    end
  end)
end

-- Return the enemy weak state.
function enemy:is_weak()
  return is_weak
end

-- Set the enemy weak.
function enemy:set_weak(weak)

  is_weak = weak
  enemy:restart()
end

-- Start the enemy normal movement.
function enemy:start_walking()

  local movement = enemy:start_target_walking(hero, flying_speed)
  movement:set_ignore_obstacles(true)
  function movement:on_position_changed()
    local angle = enemy:get_angle(hero)
    sprite:set_direction(angle > quarter and angle < 3.0 * quarter and 2 or 0)
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = is_weak and 4 or 1,
  	boomerang = "protected",
  	explosion = "ignored",
  	sword = is_weak and 4 or on_inoffensive_attack,
  	thrown_item = "protected",
  	fire = 4,
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = "protected",
  	magic_powder = "ignored",
  	shield = is_weak and "protected" or "ignored",
  	thrust = is_weak and 4 or on_inoffensive_attack
  })

  sprite:set_xy(0, -flying_height)
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:set_layer_independent_collisions(true)

  if not is_weak then
    enemy:start_walking()
  else
    go_away()
  end
end)
