-- Lua script of item "melody 1".
-- This script is executed only once for the whole game.

-- Variables
local item = ...
local game = item:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()
  
  self:set_brandish_when_picked(false)
  self:set_savegame_variable("possession_melody_1")
  self:set_assignable(true)

end

-- Event called when the hero is using this item.
function item:on_using()

  local map = game:get_map()
  local hero = map:get_hero()
  local ocarina = game:get_item("ocarina")
  ocarina:playing_song("items/ocarina_ballad")
  item:set_finished()
  
end

function item:on_obtaining()
  
  local item_1 = game:get_item_assigned(1)
  local item_2 = game:get_item_assigned(2)
  local slot = nil
  if item_1:get_name() == 'ocarina' then
    slot = 1
  elseif item_2:get_name() == 'ocarina' then
    slot = 2
  end
  if slot then
    game:set_item_assigned(slot, item)
  end
  audio_manager:play_sound("items/fanfare_item_extended")
end

function item:brandish(callback)

  local map = self:get_map()
  local hero = map:get_entity("hero")
  local x_hero,y_hero, layer_hero = hero:get_position()
  hero:set_animation("brandish")
  audio_manager:play_sound("items/fanfare_item_extended")
  local entity = map:create_custom_entity({
    name = "brandish_sword",
    sprite = "entities/items",
    x = x_hero,
    y = y_hero - 24,
    width = 16,
    height = 16,
    layer = layer_hero + 1,
    direction = 0
  })
  entity:get_sprite():set_animation("ocarina")
  entity:get_sprite():set_direction(0)
  self:get_game():start_dialog("_treasure.melody_1.1", function()
    hero:set_animation("stopped")
    map:remove_entities("brandish")
    hero:unfreeze()
    if callback ~= nil then
      callback()
    end
  end)

end