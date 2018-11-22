-- Lua script of item "mushroom".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_mushroom")
  item:set_sound_when_brandished(nil)
  item:set_assignable(true)

end

function item:on_obtaining()
  
  -- Sound
  audio_manager:play_sound("items/fanfare_item_extended")
        
end

-- Event called when the hero is using this item.
function item:on_using()

  local map = self:get_map()
  local hero = map:get_entity("hero")
  local x_hero,y_hero, layer_hero = hero:get_position()
  hero:set_animation("brandish")  
  local mushroom_entity = map:create_custom_entity({
    name = "brandish_mushroom",
    sprite = "entities/items",
    x = x_hero,
    y = y_hero - 24,
    width = 16,
    height = 16,
    layer = 1,
    direction = 0
  })
  mushroom_entity:get_sprite():set_animation("mushroom")
  mushroom_entity:get_sprite():set_direction(0)
  item:get_game():start_dialog("items.mushroom.1", function()
    hero:set_animation("stopped")
    map:remove_entities("brandish")
    hero:unfreeze()
  end)

end
