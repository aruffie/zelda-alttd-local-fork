----------------------------------
--
-- Add some basic weapon abilities to an enemy.
-- There is no passive behavior without an explicit method call when learning this to an enemy.
--
-- Methods : enemy:hold_sword([reference_sprite, [sprite_name, [x_offset, [y_offset]]]])
--           enemy:throw_projectile(projectile_name, [throwing_duration, [aligned, [x_offset, [y_offset, [on_throwed_callback]]]])
--
-- Usage : 
-- local my_enemy = ...
-- local weapons = require("enemies/lib/weapons")
-- weapons.learn(my_enemy)
--
----------------------------------

local weapons = {}

function weapons.learn(enemy)

  require("enemies/lib/common_actions").learn(enemy)

  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local quarter = math.pi * 0.5

  -- Make the enemy hold a sword.
  function enemy:hold_sword(reference_sprite, sword_sprite_name, x_offset, y_offset)

    local enemy_x, enemy_y, enemy_layer = enemy:get_position()
    reference_sprite = reference_sprite or enemy:get_sprite()
    sword = map:create_custom_entity({
      direction = enemy:get_sprite():get_direction(),
      x = enemy_x,
      y = enemy_y,
      layer = enemy_layer,
      width = 16,
      height = 16,
      sprite = sprite_name or "enemies/" .. enemy:get_breed() .. "/sword"
    })
    
    -- Synchronize sprites.
    local sword_sprite = sword:get_sprite()
    sword_sprite:set_xy(x_offset or 0, y_offset or 0)
    sword_sprite:synchronize(reference_sprite)
    reference_sprite:register_event("on_direction_changed", function(reference_sprite)
      sword_sprite:set_direction(reference_sprite:get_direction())
    end)
    reference_sprite:register_event("on_animation_changed", function(reference_sprite, name)
      if sword_sprite:has_animation(name) then
        sword_sprite:set_animation(name)
      end
    end)

    -- Hurt hero on collision with any sprite but the hero sword, else slightly move the hero back.
    local is_pushed_back = false
    sword:add_collision_test("sprite", function(sword, entity, sword_sprite, entity_sprite)
      if entity == hero  and not enemy:is_immobilized() then
        if entity_sprite ~= hero:get_sprite("sword") then
          if not hero:is_blinking() then
            hero:start_hurt(enemy, enemy:get_damage())
          end
        else
          if not is_pushed_back then
            is_pushed_back = true
            local x, y, _ = enemy:get_position()
            local hero_x, hero_y, _ = hero:get_position()
            enemy:set_invincible()
            enemy:start_pushing_back(hero, 100, 150)
            enemy:start_pushed_back(hero, 100, 150, function()
              enemy:restart()
            end)
            enemy:start_brief_effect("entities/effects/impact_projectile", "default", (hero_x - x) / 2, (hero_y - y) / 2)
          end
        end
      end
    end)

    -- Propagate enemy main events.
    enemy:register_event("on_update", function(enemy)
      sword:set_position(enemy:get_position())
    end)
    enemy:register_event("on_restarted", function(enemy)
      is_pushed_back = false
    end)
    enemy:register_event("on_removed", function(enemy)
      sword:remove()
    end)
    enemy:register_event("on_enabled", function(enemy)
      sword:set_enabled()
    end)
    enemy:register_event("on_disabled", function(enemy)
      sword:set_enabled(false)
    end)
    enemy:register_event("on_dying", function(enemy)
      sol.timer.start(sword, 300, function() -- Workaround: No event when the enemy became invisible, hardcode a timer.
        sword:set_enabled(false)
      end)
    end)

    return sword
  end

  -- Throw a projectile when throwing animation finished or duration reached.
  function enemy:throw_projectile(projectile_name, throwing_duration, aligned, x_offset, y_offset, on_throwed_callback)

    local sprite = enemy:get_sprite()

    local is_throwed = false
    local function throw()
      if not is_throwed then
        is_throwed = true
        local direction = sprite:get_direction()
        local x, y, layer = enemy:get_position()
        local projectile = map:create_enemy({
          breed = "projectiles/" .. projectile_name,
          x = x,
          y = y,
          layer = layer,
          direction = direction
        })
        projectile:get_sprite():set_xy(x_offset, y_offset) 
        if aligned then
          projectile:go(direction * quarter)
        end
        if on_throwed_callback then
          on_throwed_callback()
        end
      end
    end
    for _, sprite in enemy:get_sprites() do
      if sprite:has_animation("throwing") then
        sprite:set_animation("throwing")
      end
    end

    if throwing_duration then
      sol.timer.start(enemy, throwing_duration, function()
        throw()
      end)
    end
  end
end

return weapons