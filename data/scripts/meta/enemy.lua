-- Initialize enemy behavior specific to this quest.

-- Include scripts
local enemy_meta = sol.main.get_metatable("enemy")
local enemy_manager = require("scripts/maps/enemy_manager")
local audio_manager = require("scripts/audio_manager")
local entity_manager= require("scripts/maps/entity_manager") 

-- Get reaction to all weapons.
function enemy_meta:get_hero_weapons_reactions()

  local reactions = {}
  reactions.arrow = self:get_arrow_reaction("arrow")
  reactions.boomerang = self:get_attack_consequence("boomerang")
  reactions.explosion = self:get_attack_consequence("explosion")
  reactions.sword = self:get_attack_consequence("sword")
  reactions.thrown_item = self:get_attack_consequence("thrown_item")
  reactions.fire = self:get_fire_reaction()
  reactions.jump_on = self:get_jump_on_reaction()
  reactions.hammer = self:get_hammer_reaction()
  reactions.hookshot = self:get_hookshot_reaction()
  reactions.magic_powder = self:get_magic_powder_reaction()
  reactions.thrust = self:get_thrust_reaction()

  return reactions
end

-- Set a reaction to all weapons, default_reaction applied for each specific one not set.
function enemy_meta:set_hero_weapons_reactions(default_reaction, reactions)

  reactions = reactions or {}
  self:set_arrow_reaction(reactions.arrow or default_reaction)
  self:set_attack_consequence("boomerang", reactions.boomerang or default_reaction)
  self:set_attack_consequence("explosion", reactions.explosion or default_reaction)
  self:set_attack_consequence("sword", reactions.sword or default_reaction)
  self:set_attack_consequence("thrown_item", reactions.thrown_item or default_reaction)
  self:set_fire_reaction(reactions.fire or default_reaction)
  self:set_jump_on_reaction(reactions.jump_on or default_reaction)
  self:set_hammer_reaction(reactions.hammer or default_reaction)
  self:set_hookshot_reaction(reactions.hookshot or default_reaction)
  self:set_magic_powder_reaction(reactions.magic_powder or default_reaction)
  self:set_thrust_reaction(reactions.thrust or default_reaction)
end

-- Notify the map through a map:on_enemy_created() event on enemy created.
function enemy_meta:on_created()
  local map = self:get_map()
  if map.on_enemy_created then
    map:on_enemy_created(self)
  end
end

function enemy_meta:on_hurt(attack)

  if self:get_hurt_style() == "boss" then
    audio_manager:play_sound("enemies/boss_hit")
  else
    audio_manager:play_sound("enemies/enemy_hit")
  end

end

function enemy_meta:on_dying()

  local game = self:get_game()
  if self:get_hurt_style() == "boss" then
    audio_manager:play_sound("enemies/boss_die")
    sol.timer.start(self, 200, function()
        audio_manager:play_sound("items/bomb_explode")
      end)
  else
    audio_manager:play_sound("enemies/enemy_die")
  end
  local death_count = game:get_value("stats_enemy_death_count") or 0
  game:set_value("stats_enemy_death_count", death_count + 1)
  if not game.charm_treasure_is_loading then
    game.acorn_count = game.acorn_count or 0
    game.acorn_count = game.acorn_count + 1
    game.power_fragment_count = game.power_fragment_count or 0
    game.power_fragment_count = game.power_fragment_count + 1
  end
  game.shop_drug_count = game.shop_drug_count or 0
  game.shop_drug_count = game.shop_drug_count + 1
  game.charm_treasure_is_loading = true

end

-- Redefine how to calculate the damage inflicted by the sword.
function enemy_meta:on_hurt_by_sword(hero, enemy_sprite)

  local game = self:get_game()
  local hero = game:get_hero()
  -- Calculate force. Check tunic, sword, spin attack and powerups.
  local base_life_points = self:get_attack_consequence("sword")
  local force_sword = hero:get_game():get_value("force_sword") or 1 
  local force_tunic = game:get_value("force_tunic") or 1
  local force_powerup = hero.get_force_powerup and hero:get_force_powerup() or 1
  local force = base_life_points * force_sword * force_tunic * force_powerup
  if hero:get_state() == "sword spin attack" then
    force = 2 * force -- Double force for spin attack.
  end
  -- Remove life.
  self:remove_life(force)

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
  elseif type(reaction) == "function" then
    reaction()
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

--[[enemy_meta:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)
    -- Do nothing if enemy sprite cannot hurt hero.
    local collision_mode = enemy:get_attacking_collision_mode()
    if not enemy:overlaps(hero, collision_mode) then return end
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

  end)--]]

enemy_meta:register_event("on_removed", function(enemy)

    local game = enemy:get_game();
    local map = game:get_map()
    if enemy:get_ground_below()== "hole" and enemy:get_obstacle_behavior()=="normal" then
      entity_manager:create_falling_entity(enemy)
    end
  end)

-- Create an exclamation symbol near enemy
function enemy_meta:create_symbol_exclamation(sound)

  local map = self:get_map()
  local x, y, layer = self:get_position()
  if sound then
    audio_manager:play_sound("menus/menu_select")
  end
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
function enemy_meta:create_symbol_interrogation(sound)

  local map = self:get_map()
  local x, y, layer = self:get_position()
  if sound then
    audio_manager:play_sound("menus/menu_select")
  end
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
function enemy_meta:create_symbol_collapse(sound)

  local map = self:get_map()
  local width, height = self:get_sprite():get_size()
  local x, y, layer = self:get_position()
  if sound then
    -- Todo create a custom sound
  end
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
