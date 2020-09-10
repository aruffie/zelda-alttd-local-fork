-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local claw_manager = require("scripts/maps/claw_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()

  final_stream:set_visible(false)
  local x, y, layer = final_stream:get_position()
  local hero_blocker = map:create_custom_entity({
    direction = 0,
    x = x,
    y = y,
    layer = layer,
    width = 16,
    height = 16
  })
  hero_blocker:set_modified_ground("traversable")
  hero_blocker:set_traversable_by("hero", false)
  hero_blocker:set_traversable_by("pickable", true)  -- Allow the pickable to reach the hero at the end.

end)

-- Initialize the music of the map
function map:init_music()

  if game:is_step_last("shield_obtained") then
    audio_manager:play_music("07_koholint_island")
  else
    audio_manager:play_music("15_trendy_game")
  end

end

-- NPCs events
function merchant:on_interaction()

  -- Don't make the hero pay again if the mini-game is already started.
  if merchant.playing then
    return
  end

  game:start_dialog("maps.houses.mabe_village.shop_1.merchant_1", function(answer)
    if answer == 1 then
      local money = game:get_money()
      if money >= 10 then
        game:start_dialog("maps.houses.mabe_village.shop_1.merchant_3", function()
          game:remove_money(10)
          merchant.playing = true
        end)
      else
        game:start_dialog("maps.houses.mabe_village.shop_1.merchant_2")
      end
    end
  end)

end

function console:on_interaction()

  if not merchant.playing then
    return
  end

  hero:freeze()
  local claw_menu = claw_manager:create_minigame(map)
  sol.menu.start(map, claw_menu)
  function claw_menu:on_finished()
    if merchant ~= nil then
      merchant.playing = false
      hero:unfreeze()
    end
  end

end
