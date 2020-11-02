----------------------------------
--
-- Like Like.
--
-- Moves randomly over horizontal and vertical axis.
-- Eat the hero and steal the equiped shield if any, then wait for eight actions before free the hero.
--
-- Methods : enemy:start_walking()
--           enemy:steal_item(item_name, [variant, [only_if_assigned, [drop_when_dead]]])
--           enemy:free_hero()
--           enemy:eat_hero()
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local hero_sprite = hero:get_sprite()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_eating = false
local is_exhausted = true
local command_pressed_count = 0

-- Configuration variables.
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local walking_pause_duration = 1500

-- Set opacity on the given sprite if existing.
local function set_sprite_opacity(sprite, opacity)

  if sprite then
    sprite:set_opacity(opacity)
  end
end

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end


-- Steal an item and drop it when died, possibly conditionned on the variant and the assignation to a slot.
function enemy:steal_item(item_name, variant, only_if_assigned, drop_when_dead)

  if game:has_item(item_name) then
    local item = game:get_item(item_name)
    local is_stealable = not only_if_assigned or (game:get_item_assigned(1) == item and 1) or (game:get_item_assigned(2) == item and 2)

    if (not variant or item:get_variant() == variant) and is_stealable then 
      if drop_when_dead then
        enemy:set_treasure(item_name, item:get_variant()) -- TODO savegame variable
      end
      item:set_variant(0)
      if item_slot then
        game:set_item_assigned(item_slot, nil)
      end
    end
  end
end

-- Free the hero.
function enemy:free_hero()

  is_eating = false
  is_exhausted = true

  -- Reset hero opacity.
  set_sprite_opacity(hero_sprite, 255)
  set_sprite_opacity(hero:get_sprite("shadow"), 255)
  set_sprite_opacity(hero:get_sprite("shadow_override"), 255)

  enemy:restart()
end

-- Make the enemy eat the hero.
function enemy:eat_hero()

  is_eating = true
  command_pressed_count = 0
  enemy:stop_movement()
  enemy:set_invincible()

  -- Make the hero invisible, but still able to interact.
  set_sprite_opacity(hero_sprite, 0)
  set_sprite_opacity(hero:get_sprite("shadow"), 0)
  set_sprite_opacity(hero:get_sprite("shadow_override"), 0)

  -- Eat the shield if it is the first variant and assigned to a slot.
  enemy:steal_item("shield", 1, true, true)
end

-- Store the number of command pressed while eaten, and free the hero once 8 item commands are pressed.
map:register_event("on_command_pressed", function(map, command)

  if not enemy:exists() or not enemy:is_enabled() then
    return
  end

  if is_eating and (command == "attack" or command == "item_1" or command == "item_2") then
    command_pressed_count = command_pressed_count + 1
    if command_pressed_count == 8 then
      enemy:free_hero()
    end
  end
end)

-- Eat the hero on attacking him.
enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)

  if not is_eating and not is_exhausted and hero_sprite:get_opacity() ~= 0 then
    enemy:eat_hero()
  end
  return true
end)

-- Free hero on dying.
enemy:register_event("on_dying", function(enemy)

  if is_eating then
    enemy:free_hero()
  end
end)

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  if not enemy:is_enabled() then
    return
  end

  -- Make sure the hero is stuck while eaten even if something move him or the enemy.
  if is_eating then
    hero:set_position(enemy:get_position())
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Schedule the damage rules setup once not in collision with the hero.
  sol.timer.start(enemy, 50, function()
    if enemy:overlaps(hero, "sprite") then
      return true
    end
    is_exhausted = false
    enemy:set_damage(1)
    enemy:set_can_attack(true)

    -- Behavior for each items.
    enemy:set_hero_weapons_reactions(2, {
      sword = 1,
      jump_on = "ignored"
    })
  end)

  -- States.
  enemy:set_invincible()
  enemy:set_damage(0)
  enemy:set_can_attack(false)
  command_pressed_count = 0
  enemy:start_walking()
end)
