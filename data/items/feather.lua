--[[

  Lua script of item feather.

  This newer version uses plainly the new global command overrides as it depends on not triggering the "item" state.
  Because of that, it must **NEVER** be triggered using the built-in method or else it will never finish and sftlock your game.
  The reason is that it would end any custon jumping state, with bad consequences, such as falling into a pit while mid-air
  
--]]
local hero_meta = sol.main.get_metatable("hero")
local item = ...
local game = item:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/states/jumping")
require("scripts/states/jumping_sword")
local jm=require("scripts/jump_manager")
require("scripts/multi_events")

-- Event called when the game is initialized.
function item:on_started()
  item:set_savegame_variable("possession_feather")
  item:set_sound_when_brandished(nil)
  item:set_assignable(true)
end

local game_meta = sol.main.get_metatable("game")

-- This function is called when the item command is triggered. It is similar to item:on_using, without state changing.
function item:start_using()

  local map = game:get_map()
  local hero = map:get_hero()
  
  if not hero:is_jumping() then
    if not map:is_sideview() then

      -- Handle possible jump types differently in top view maps.
      local state = hero:get_state()
      if state ~= "falling" then

        if state == "sword swinging" or state == "sword loading" or state == "custom" and hero:get_state_object():get_description() == "jumping_sword" then 
          hero:start_flying_attack() -- Offensive jump
        elseif state == "custom" and hero:get_state_object():get_description() == "running" then 
          --print" run'n'jump"
          jm.start(hero) -- Running jump
        else
          hero:jump() -- Normal jump
        end
      end
    else
      -- Simply apply a vertical impulsion to the hero in sideview maps.
      local vspeed = hero.vspeed or 0
      if vspeed == 0 or map:get_ground(hero:get_position()) == "deep_water" then
        audio_manager:play_sound("hero/jump")
        sol.timer.start(10, function()
            hero.on_ladder = false
            hero.vspeed = -4
          end)
      end
    end
  end
end

-- Play fanfare sound on obtaining.
function item:on_obtaining()
  audio_manager:play_sound("items/fanfare_item_extended")
end

-- Initialize the metatable of appropriate entities to be able to set a reaction on jumped on.
local function initialize_meta()

  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.get_jump_on_reaction then
    return
  end

  enemy_meta.jump_on_reaction = "ignored"  -- Nothing happens by default.
  enemy_meta.jump_on_reaction_sprite = {}

  function enemy_meta:get_jump_on_reaction(sprite)
    if sprite and self.jump_on_reaction_sprite[sprite] then
      return self.jump_on_reaction_sprite[sprite]
    end
    return self.jump_on_reaction
  end

  function enemy_meta:set_jump_on_reaction(reaction, sprite)
    self.jump_on_reaction = reaction
  end

  function enemy_meta:set_jump_on_reaction_sprite(sprite, reaction)
    self.jump_on_reaction_sprite[sprite] = reaction
  end

  -- Change the default enemy:set_invincible() to also
  -- take into account the feather.
  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    previous_set_invincible(self)
    self:set_jump_on_reaction("ignored")
  end
  local previous_set_invincible_sprite = enemy_meta.set_invincible_sprite
  function enemy_meta:set_invincible_sprite(sprite)
    previous_set_invincible_sprite(self, sprite)
    self:set_jump_on_reaction_sprite(sprite, "ignored")
  end
end
initialize_meta()
