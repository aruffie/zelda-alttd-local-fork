-- Lua script of item "fire rod".
-- This script is executed only once for the whole game.

local item = ...
local game = item:get_game()
local magic_needed = 0  -- Number of magic points required.
local audio_manager=require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_fire_rod")
  item:set_assignable(true)
  
end

-- Shoots some fire on the map.
function item:shoot()

  local map = item:get_map()
  local hero = map:get_hero()
  local direction = hero:get_direction()

  local x, y, layer = hero:get_center_position()
  local ox, oy=hero:get_sprite("tunic"):get_xy()
  local fire = map:create_custom_entity({
    model = "fire",
    x = x+ox,
    y = y+oy + 3,
    layer = layer,
    width = 8,
    height = 8,
    direction = direction,
  })

 -- local fire_sprite = entity:get_sprite("fire")
  --fire_sprite:set_animation("flying")

  local angle = direction * math.pi / 2
  local movement = sol.movement.create("straight")
  movement:set_speed(192)
  movement:set_angle(angle)
  movement:set_smooth(false)
  movement:start(fire)
  
end

-- Event called when the hero is using this item.
function item:start_using()

  local map = item:get_map()
  local hero = map:get_hero()
  local direction = hero:get_direction()
  audio_manager:play_sound("items/fire_rod")
  hero:set_animation("rod")
  local ox, oy=hero:get_sprite("tunic"):get_xy()
  -- Give the hero the animation of using the fire rod.
  local x, y, layer = hero:get_position()
  local fire_rod = map:create_custom_entity({
    x = x+ox,
    y = y+oy,
    layer = layer,
    width = 16,
    height = 16,
    direction = direction,
    sprite = "hero/fire_rod",
  })

  -- Shoot fire if there is enough magic.
  if game:get_magic() >= magic_needed then
    --audio_manager:play_sound("lamp")
    game:remove_magic(magic_needed)
    item:shoot()
  end

  -- Make sure that the fire rod stays on the hero.
  -- Even if he is using this item, he can move
  -- because of holes or ice.
  sol.timer.start(fire_rod, 10, function()
    fire_rod:set_position(hero:get_position())
    return true
  end)

  -- Remove the fire rod and restore control after a delay.
  sol.timer.start(hero, 300, function()
    fire_rod:remove()
    hero:unfreeze()
    item:set_finished()
  end)

end

-- Initialize the metatable of appropriate entities to work with the fire.
local function initialize_meta()

  -- Add Lua fire properties to enemies.
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.get_fire_reaction ~= nil then
    -- Already done.
    return
  end
  enemy_meta.fire_reaction = 3  -- 3 life points by default.
  enemy_meta.fire_reaction_sprite = {}
  function enemy_meta:get_fire_reaction(sprite)

    if sprite ~= nil and self.fire_reaction_sprite[sprite] ~= nil then
      return self.fire_reaction_sprite[sprite]
    end
    return self.fire_reaction
  end

  function enemy_meta:set_fire_reaction(reaction)

    self.fire_reaction = reaction
    
  end

  function enemy_meta:set_fire_reaction_sprite(sprite, reaction)

    self.fire_reaction_sprite[sprite] = reaction
    
  end

  -- Change the default enemy:set_invincible() to also
  -- take into account the fire.
  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    
    previous_set_invincible(self)
    self:set_fire_reaction("ignored")
    
  end
  local previous_set_invincible_sprite = enemy_meta.set_invincible_sprite
  function enemy_meta:set_invincible_sprite(sprite)
    
    previous_set_invincible_sprite(self, sprite)
    self:set_fire_reaction_sprite(sprite, "ignored")
    
  end

end

initialize_meta()
