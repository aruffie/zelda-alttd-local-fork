----------------------------------
--
-- Vire.
--
-- Flying enemy that starts by taking off and go to the east, then follow the camera border clockwise.
-- Throw two magmaballs two times while moving, then charge to the hero direction and continue charging until not being visible if not stopped.
-- Finally respawn randomly just beyond the camera border, then slowly fly to the hero.
--
-- Split into two bats if dying because of a weak attack, that wait then charge the hero for the last time.
--
-- Methods : enemy:throw_magma_balls()
--           enemy:start_charging([offensive])
--           enemy:start_attacking()
--           enemy:start_moving([angle])
--           enemy:start_taking_off([angle])
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
local attacking_timer = nil
local attack_count = 0
local is_charging = false
local is_executed = false

-- Configuration variables
local take_off_duration = 1000
local fall_down_duration = 150
local fall_down_bounce_duration = 300
local fall_down_bounce_height = 8
local flying_height = 32
local flying_speed = 24
local charging_speed = 175
local runaway_triggering_distance = 32
local fired_duration = 500
local before_attacks_delay = 3000
local between_attacks_delay = 2000
local before_respawn_delay = 1000

-- Return a random position on the border of the screen.
local function get_random_position_on_screen_border()

  local x, y = camera:get_position()
  local width, height = camera:get_size()
  local mid_point = width + height
  local random_point = math.random(mid_point * 2)

  return x + (random_point > mid_point + width and 0 or math.min(width, random_point % mid_point)), 
          y + math.min(height, math.max(0, random_point - width) % mid_point)
end

-- Replace the enemy position on the sprite and remove the sprite offset.
local function replace_on_sprite()

  local x, y = enemy:get_position()
  local x_offset, y_offset = sprite:get_xy()
  enemy:set_position(x + x_offset, y + y_offset)
  sprite:set_xy(0, 0)
end

-- Clip the enemy sprite in the given rectangle by moving the whole enemy.
local function clip_sprite_into(sprite, x, y, width, height)

  local enemy_x, enemy_y, _ = enemy:get_position()
  local sprite_x, sprite_y = sprite:get_xy()
  local sprite_width, sprite_height = sprite:get_size()
  local origin_x, origin_y = sprite:get_origin()
  local sprite_absolute_x = sprite_x - origin_x + enemy_x
  local sprite_absolute_y = sprite_y - origin_y + enemy_y

  local clipped_sprite_x = math.max(x, math.min(x + width - sprite_width, sprite_absolute_x))
  local clipped_sprite_y = math.max(y, math.min(y + height - sprite_height, sprite_absolute_y))

  enemy:set_position(clipped_sprite_x - sprite_x + origin_x, clipped_sprite_y - sprite_y + origin_y)
end

-- Create a projectile.
local function create_projectile(projectile, direction)

  local x, y = sprite:get_xy()
  local projectile = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_" .. projectile,
    breed = "projectiles/" .. projectile,
    x = x,
    y = y
  })
  projectile:go(direction)

  return projectile
end

-- Throw two magmaballs.
function enemy:throw_magma_balls()

  sprite:set_animation("firing", function()
    sprite:set_animation("fired")
    create_projectile("magmaball")
    local magmaball = create_projectile("magmaball")
    local magmaball_movement = magmaball:get_movement()
    magmaball_movement:set_angle(magmaball_movement:get_angle() - 0.4)
    sol.timer.start(enemy, fired_duration, function()
      if not is_charging then
        sprite:set_animation("walking")
      end
    end)
  end)
end

-- Start charging to or away to the hero.
function enemy:start_charging(offensive)

  is_charging = true
  local hero_x, hero_y, _ = hero:get_position()
  local enemy_x, enemy_y, _ = enemy:get_position()
  local x_offset, y_offset = sprite:get_xy()
  local angle = math.atan2(hero_y - enemy_y - y_offset, enemy_x - hero_x - x_offset) + (offensive and math.pi or 0)
  local movement = enemy:start_straight_walking(angle, charging_speed)
  movement:set_ignore_obstacles(true)
  sprite:set_animation("charging")

  -- Respawn just beyond camera borders and start another slow fly if completely out of the screen while charging.
  function movement:on_position_changed()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      movement:stop()
      enemy:set_visible(false)
      sol.timer.start(enemy, before_respawn_delay, function()
        if is_charging then
          sprite:set_xy(0, 0)
          enemy:set_position(get_random_position_on_screen_border())
          enemy:start_taking_off()
        end
      end)
    end
  end
end

-- Throw two magma balls two times then charge.
function enemy:start_attacking()
  
  attack_count = 0
  sol.timer.start(enemy, before_attacks_delay, function()
    attacking_timer = sol.timer.start(enemy, between_attacks_delay, function()
      if not is_charging then
        attack_count = attack_count + 1
        if attack_count < 3 then
          enemy:throw_magma_balls()
          return true
        end
        attacking_timer = nil
        enemy:start_charging(true)
      end
    end)
  end)
end

-- Start enemy flying behavior.
function enemy:start_moving(angle)

  is_charging = false
  local movement

  -- Start a straight movement if angle is given.
  if angle then
    movement = enemy:start_straight_walking(angle, flying_speed)

    -- Clip and change the angle if the enemy has a part out screen.
    movement:register_event("on_position_changed", function(movement)
      if not is_charging and not enemy:is_watched(sprite, true) then
        clip_sprite_into(sprite, camera:get_bounding_box())
        enemy:start_moving(movement:get_direction4() * quarter - quarter)
        return false
      end
    end)

  -- Start a target walking to the hero else.
  else
    movement = enemy:start_target_walking(hero, flying_speed)
  end
  movement:set_ignore_obstacles(true)

  -- Run away if the hero is too close.
  movement:register_event("on_position_changed", function(movement)
    if enemy:is_near(hero, runaway_triggering_distance, sprite) then
      enemy:start_charging(false)
    end
  end)
end

-- Start enemy movement.
function enemy:start_taking_off(angle)

  if attacking_timer then
    attacking_timer:stop()
  end
  replace_on_sprite()
  enemy:set_visible()
  enemy:start_moving(angle)
  enemy:start_flying(take_off_duration, flying_height)
  enemy:start_attacking()
end

-- On hit by boomerang, fire or magic powder, make the enemy fall down and die without splitting into bats.
enemy:register_event("on_custom_attack_received", function(enemy, attack)

  if attack == "boomerang" or attack == "fire" or attack == "magic_powder" then

    is_executed = true
    enemy:stop_flying(fall_down_duration, function()
      enemy:start_jumping(fall_down_bounce_duration, fall_down_bounce_height, nil, nil, function()
        enemy:set_pushed_back_when_hurt(false)
        enemy:hurt(3)
      end)
    end)
  end
end)

-- Replace on sprite position and create two bats projectiles on dying.
enemy:register_event("on_dying", function(enemy)

  replace_on_sprite()
  if not is_executed then
    local bat1 = create_projectile("bat", 0)
    local bat2 = create_projectile("bat", 2)
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(3)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {
    thrust = 2,
    hookshot = 2,
    boomerang = "custom",
    magic_powder = "custom",
    fire = "custom",
    jump_on = "ignored"})

  -- States.
  sprite:set_xy(0, 0)
  sprite:set_animation("walking")
  enemy:set_obstacle_behavior("flying")
  enemy:set_layer_independent_collisions(true)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_taking_off(0)
end)