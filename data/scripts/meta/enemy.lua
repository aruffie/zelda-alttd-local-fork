-- Initialize enemy behavior specific to this quest.

-- Include scripts
local enemy_meta = sol.main.get_metatable("enemy")
local enemy_manager = require("scripts/maps/enemy_manager")
local audio_manager = require("scripts/audio_manager")

function enemy_meta:on_hurt(attack)
  
  if self:get_hurt_style() == "boss" then
    audio_manager:play_sound("enemies/boss_hit")
  else
    audio_manager:play_sound("enemies/enemy_hit")
  end
   
end

function enemy_meta:on_dying()
  
  if self:get_hurt_style() == "boss" then
    audio_manager:play_sound("enemies/boss_die")
    sol.timer.start(self, 200, function()
      audio_manager:play_sound("items/bomb_explode")
    end)
  else
    audio_manager:play_sound("enemies/enemy_die")
  end
  
end

-- Redefine how to calculate the damage inflicted by the sword.
function enemy_meta:on_hurt_by_sword(hero, enemy_sprite)

  local game = self:get_game()
  local hero = game:get_hero()
  -- Calculate force. Check tunic, sword, spin attack and powerups.
  -- TODO: define powerup function "hero:get_force_powerup()".
  local base_life_points = self:get_attack_consequence("sword")
  local force_sword = hero:get_game():get_value("force_sword") or 1 
  local force_tunic = game:get_value("force_tunic") or 1
  local force_powerup = hero.get_force_powerup and hero:get_force_powerup() or 1
  local force = base_life_points * force_sword * force_tunic * force_powerup
  print(force)
  if hero:get_state() == "sword spin attack" then
    force = 2 * force -- Double force for spin attack.
  end
  -- Remove life.
  local life_lost = force
  self:remove_life(life_lost)
  
end

-- Helper function to inflict an explicit reaction from a scripted weapon.
-- TODO this should be in the Solarus API one day
function enemy_meta:receive_attack_consequence(attack, reaction)

  if type(reaction) == "number" then
    self:hurt(reaction)
  elseif reaction == "immobilized" then
    self:immobilize()
  elseif reaction == "scared" then
    sol.timer.stop_all(self)  -- Stop the towards_hero behavior.
      local hero = self:get_map():get_hero()
      local angle = hero:get_angle(self)
      local movement = sol.movement.create("straight")
      movement:set_speed(128)
      movement:set_angle(angle)
      movement:start(self)
      sol.timer.start(self, 400, function()
        self:restart()
      end)
  elseif reaction == "protected" then
    audio_manager:play_sound("sword_tapping")
  elseif reaction == "custom" then
    if self.on_custom_attack_received ~= nil then
      self:on_custom_attack_received(attack)
    end
  end

end

function enemy_meta:launch_small_boss_dead()

  local game = self:get_game()
  local map = game:get_map()
  local dungeon = game:get_dungeon_index()
  local dungeon_info = game:get_dungeon()
  local savegame = "dungeon_" .. dungeon .. "_small_boss"
  local door_prefix = "door_group_small_boss"
  local music = dungeon_info.music
  audio_manager:play_music(music)
  game:set_value(savegame, true)
  map:open_doors(door_prefix)
  enemy_manager:create_teletransporter_if_small_boss_dead(map, true)
  local x,y,layer = self:get_position()
  map:create_pickable({
    x = x,
    y = y,
    layer = layer, 
    treasure_name = "fairy",
    treasure_variant = 1
  })
  for tile in map:get_entities("tiles_small_boss_") do
   local layer = tile:get_property('end_layer')
   tile:set_layer(layer)
  end

end

function enemy_meta:launch_boss_dead()

  local game = self:get_game()
  local map = game:get_map()
  local dungeon = game:get_dungeon_index()
  local savegame = "dungeon_" .. dungeon .. "_boss"
  local door_prefix = "door_group_boss"
  audio_manager:play_music("23_boss_defeated")
  game:set_value(savegame, true)
  map:open_doors(door_prefix)
  local heart_container = map:get_entity("heart_container")
  heart_container:set_enabled(true)

end

-- Attach a custom damage to the sprites of the enemy.
function enemy_meta:get_sprite_damage(sprite)
return (sprite and sprite.custom_damage) or self:get_damage()
end

function enemy_meta:set_sprite_damage(sprite, damage)
  sprite.custom_damage = damage
end

-- Warning: do not override these functions if you use the "custom shield" script.
function enemy_meta:on_attacking_hero(hero, enemy_sprite)
  local enemy = self
  -- Do nothing if enemy sprite cannot hurt hero.
  if enemy:get_sprite_damage(enemy_sprite) == 0 then return end
  local collision_mode = enemy:get_attacking_collision_mode()
  if not hero:overlaps(enemy, collision_mode) then return end
  -- Do nothing when shield is protecting.
  if hero.is_shield_protecting_from_enemy
      and hero:is_shield_protecting_from_enemy(enemy, enemy_sprite) then
    return
  end
-- Otherwise, hero is not protected. Use built-in behavior.
  local damage = enemy:get_damage()
  if enemy_sprite then
    hero:start_hurt(enemy, enemy_sprite, damage)
  else
    hero:start_hurt(enemy, damage)
  end
  
end

function enemy_meta:on_position_changed(x, y, layer)
    
  local enemy = self
  local ground = enemy:get_map():get_ground(x, y, layer)
  local sprite = enemy:get_sprite()
  if ground == "hole" and enemy:get_sprite() ~= nil and sprite:has_animation("falling") and sprite:get_animation() ~= "falling" then
    enemy:get_sprite():set_animation("falling")
    audio_manager:play_sound("enemies/enemy_fall")
  end
      
end

-- Create an exclamation symbol near enemy
function enemy_meta:create_symbol_exclamation()
  
  local map = self:get_map()
  local x, y, layer = self:get_position()
  audio_manager:play_sound("menus/menu_select")
  local symbol = map:create_custom_entity({
    sprite = "entities/symbols/exclamation",
    x = x - 16,
    y = y - 16,
    width = 16,
    height = 16,
    layer = layer + 1,
    direction = 0
  })

  return symbol
  
end

-- Create an interrogation symbol near enemy
function enemy_meta:create_symbol_interrogation()
  
  local map = self:get_map()
  local x, y, layer = self:get_position()
  audio_manager:play_sound("menus/menu_select")
  local symbol = map:create_custom_entity({
    sprite = "entities/symbols/interrogation",
    x = x,
    y = y,
    width = 16,
    height = 16,
    layer = layer + 1,
    direction = 0
  })

  return symbol
  
end

-- Create a collapse symbol near enemy
function enemy_meta:create_symbol_collapse()
  
  local map = self:get_map()
  local width, height = self:get_sprite():get_size()
  local x, y, layer = self:get_position()
  local symbol = map:create_custom_entity({
    sprite = "entities/symbols/collapse",
    x = x,
    y = y - height / 2,
    width = 16,
    height = 16,
    layer = layer + 1,
    direction = 0
  })

  return symbol
  
end

return true
