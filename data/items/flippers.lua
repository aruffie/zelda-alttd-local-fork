-- Lua script of item "flippers".
-- This script is executed only once for the whole game.

-- Variables
local item = ...
local game = item:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_flippers")
  item.is_hero_diving = false
  item:set_sound_when_brandished(nil) 

end

function item:on_variant_changed(variant)

  -- the possession state of the flippers determines the built-in ability "swim"
  self:get_game():set_ability("swim", variant)

end

function item:on_obtaining()
  
  audio_manager:play_sound("items/fanfare_item_extended")
        
end

game:register_event("on_command_pressed", function(game, command)
    
  if command == "attack" and game:get_hero():get_state() == "swimming" and item.is_hero_diving == false then
     item:start_diving()
  end
  
end)

-- Start diving hero
function item:start_diving()

  item.is_hero_diving = true
  local hero = game:get_hero()
  hero:register_event("on_state_changed", function(hero, state)
    if item.is_hero_diving and hero:get_state() == "free" then
      item:stop_diving()
    end
  end)
  audio_manager:play_sound("splash")
  hero:freeze()
  hero:set_animation("diving",function()
    hero:unfreeze()
    hero:set_tunic_sprite_id("hero/diving")
    hero:set_invincible(true)
    sol.timer.start(item, 2000, function()
      item:stop_diving()
    end)
  end)

end

-- Stop diving hero
function item:stop_diving()

  if item.is_hero_diving then
    local hero = game:get_hero()
    hero:set_tunic_sprite_id("hero/tunic"..game:get_ability("tunic"))
    hero:set_invincible(false)
    item.is_hero_diving = false
  end

end