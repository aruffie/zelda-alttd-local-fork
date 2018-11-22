-- Variables
local item = ...
local game = item:get_game()

function item:on_started()

  self:set_brandish_when_picked(false)
  self:set_savegame_variable("possession_melody_1")
  self:set_assignable(true)

end

function item:on_using()

  local map = game:get_map()
  local hero = map:get_hero()
  local ocarina = game:get_item("ocarina")
  hero:freeze()
  game:set_pause_allowed(false)
  ocarina:playing_song("items/ocarina_1", function()
    hero:unfreeze()
    game:set_pause_allowed(true)
  end)

  item:set_finished()
  
end

function item:brandish(callback)

  local map = self:get_map()
  local hero = map:get_entity("hero")
  local nb = self:get_game():get_item("golden_leaves_counter"):get_amount()
  local x_hero,y_hero, layer_hero = hero:get_position()
  hero:set_animation("brandish")
  audio_manager:play_sound("treasure_2")
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