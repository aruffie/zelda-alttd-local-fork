----------------------------------
--
-- Sea Urchin.
--
-- Immobile enemy that can be pushed with the shield.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local sprite = enemy:create_sprite("enemies/sea_urchin")
local game = enemy:get_game()
local map = game:get_map()
local hero = map:get_hero()
local pushing_frame_count = 0

-- Configuration variables
local pushing_frames_before_moved = 5

-- Push the enemy on shield collision.
local function on_shield_collision()

  pushing_frame_count = pushing_frame_count + 1
  if pushing_frame_count % pushing_frames_before_moved ~= pushing_frames_before_moved - 1 then
    return
  end

  local x, y, layer = enemy:get_position()
  local direction4 = hero:get_direction4_to(enemy)
  local move_x = (direction4 == 0 and 1) or (direction4 == 2 and -1) or 0
  local move_y = (direction4 == 1 and -1) or (direction4 == 3 and 1) or 0

  if not enemy:test_obstacles(move_x, move_y) then
    enemy:set_position(x + move_x, y + move_y, layer)
  end
end

-- Make the enemy traversable on dying.
enemy:register_event("on_dying", function(enemy)

  enemy:set_traversable()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_traversable(false)
  enemy:set_life(1)
  enemy:set_damage(2)
  enemy:set_hurt_style("normal")
  enemy:set_attacking_collision_mode("touching")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = 1,
  	boomerang = 1,
  	explosion = 1,
  	sword = 1,
  	thrown_item = 1,
  	fire = 1,
  	jump_on = "ignored",
  	hammer = 1,
  	hookshot = 1,
  	magic_powder = 1,
  	shield = on_shield_collision,
  	thrust = 1
  })
end)