----------------------------------
--
-- Lanmola's Shadow.
--
-- Caterpillar enemy that targets the hero.
-- Can be defeated with a single shot of any weapon but the sword.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprites = {}
local last_positions, frame_count
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local is_pushing_back = false

-- Configuration variables
local walking_speed = 88
local walking_angle_variation = 0.015
local tied_sprites_frame_lags = {15, 28, 40, 52}

local highest_frame_lag = tied_sprites_frame_lags[#tied_sprites_frame_lags] + 1

-- Only hurt a sword attack received if the attack is a spin one.
local function on_sword_attack_received()

  if hero:get_sprite():get_animation() == "spin_attack" then
    enemy:start_death()
  end
  if not is_pushing_back then
    is_pushing_back = true
    enemy:start_pushing_back(hero, 200, 100, sprite, nil, function()
      is_pushing_back = false
    end)
  end
end

-- Update tied sprites offset.
local function update_sprites()

  -- Save current position
  local x, y, _ = enemy:get_position()
  last_positions[frame_count] = {x = x, y = y}

  -- Replace part sprites on a previous position.
  local function replace_part_sprite(sprite, frame_lag)
    local previous_position = last_positions[(frame_count - frame_lag) % highest_frame_lag] or last_positions[0]
    sprite:set_xy(previous_position.x - x, previous_position.y - y)
  end
  for i = 1, #tied_sprites_frame_lags do
    replace_part_sprite(sprites[i + 1], tied_sprites_frame_lags[i])
  end

  frame_count = (frame_count + 1) % highest_frame_lag
end

-- Get the angle diffence between the movement angle and the entity, between -pi and pi
local function get_closest_angle(movement, entity)

  local angle = (movement:get_angle() - enemy:get_angle(entity)) % circle
  return angle < math.pi and angle or -circle + angle
end

-- Start the enemy movement.
function enemy:start_walking()

  local movement = sol.movement.create("straight")
  movement:set_speed(walking_speed)
  movement:set_angle(enemy:get_angle(hero))
  movement:set_smooth(false)
  movement:start(enemy)

  for i = 1, #sprites, 1 do
    sprites[i]:set_animation((i > 3 and "tail") or (i > 1 and "body") or "head")
  end

  -- Slowly turn to the hero every frame and update body positions.
  sol.timer.start(enemy, 10, function()
    movement:set_angle(movement:get_angle() - math.min(walking_angle_variation, math.max(-walking_angle_variation, get_closest_angle(movement, hero))))
    update_sprites()
    return true
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  -- Create sprites in right z-order.
  for i = #tied_sprites_frame_lags + 1, 1, -1 do
    sprites[i] = enemy:create_sprite("enemies/" .. enemy:get_breed(), (i == 1) and "main" or nil)
  end
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = function() enemy:start_death() end,
  	boomerang = function() enemy:start_death() end,
  	explosion = function() enemy:start_death() end,
  	sword = on_sword_attack_received,
  	thrown_item = function() enemy:start_death() end,
  	fire = function() enemy:start_death() end,
  	jump_on = "ignored",
  	hammer = function() enemy:start_death() end,
  	hookshot = function() enemy:start_death() end,
  	magic_powder = "ignored",
  	shield = "protected",
  	thrust = function() enemy:start_death() end
  })
  for i = 2, #sprites, 1 do
    enemy:set_invincible_sprite(sprites[i])
  end

  -- States.
  last_positions = {}
  frame_count = 0
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end)
