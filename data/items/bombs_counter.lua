-- Lua script of item "bombs counter".
-- This script is executed only once for the whole game.

-- Variables
local item = ...
local game = item:get_game()
local hero = game:get_hero()

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  self:set_savegame_variable("possession_bombs_counter")
  self:set_amount_savegame_variable("amount_bombs_counter")
  self:set_assignable(true)


end

function item:on_obtaining(variant, savegame_variable)

  self:set_max_amount(20)
  self:set_amount(20)

end

function item:start_combo(other)
  if other:get_name()=="bow" and other.start_combo then
    print "Combined items bomb"
    --Delegate to the bow since it already has the combo implemented
    --TODO Maybe delegate to a manager instead?
    other:start_combo(item)
  end
end


-- Called when the player uses the bombs of his inventory by pressing the corresponding item key.
function item:start_using()
  print "Single item bomb"
  if item:get_amount() == 0 then
    if sound_timer == nil then
      audio_manager:play_sound("misc/error")
      sound_timer = sol.timer.start(game, 500, function()
          sound_timer = nil
        end)
    end
  else

    item:remove_amount(1)
    local bomb = item:create_bomb()
    audio_manager:play_sound("items/bomb_drop")

  end
  item:set_finished()

end

function item:create_bomb()

  local map = item:get_map()
  local hero = map:get_entity("hero")
  local x, y, layer = hero:get_position()
  local direction = hero:get_direction()
  if direction == 0 then
    x = x + 16
  elseif direction == 1 then
    y = y - 16
  elseif direction == 2 then
    x = x - 16
  elseif direction == 3 then
    y = y + 16
  end
  local bomb = map:create_bomb{
    x = x,
    y = y,
    layer = layer
  }
  local sprite = bomb:get_sprite()
  function sprite:on_animation_changed(animation)
    if animation == "stopped_explosion_soon" then
      sol.timer.start(item, 1500, function()
          audio_manager:play_sound("items/bomb_explode")
        end)
    end
  end
  map.current_bombs = map.current_bombs or {}
  map.current_bombs[bomb] = true
  return bomb
end

function item:remove_bombs_on_map()

  local map = item:get_map()
  if map.current_bombs == nil then
    return
  end
  for bomb in pairs(map.current_bombs) do
    bomb:remove()
  end
  map.current_bombs = {}

end


