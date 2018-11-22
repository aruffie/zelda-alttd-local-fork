-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:is_hookable()
  
  return false
  
end

-- Event called when the custom entity is initialized.
function entity:on_created()

  local sprite = entity:get_sprite()
  local hero = map:get_hero()
  local direction_hero = hero:get_direction()
  local direction_hero_opposite = direction_hero + 2
  if direction_hero_opposite >= 4 then
    direction_hero_opposite = direction_hero_opposite - 4
  end

end
