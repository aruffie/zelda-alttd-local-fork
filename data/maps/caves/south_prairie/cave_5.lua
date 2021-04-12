-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Start a sprite animation and direction.
local function start_sprite_animation(sprite, animation, direction, on_finished_callback)

  sprite:set_animation(animation, function()
    if on_finished_callback then
      on_finished_callback()
    end
  end)
  sprite:set_direction(direction)
end

-- Start the Wart song cinematic.
local function start_wart_song(on_finished_callback)

  local sprite = wart:get_sprite()
  local brother_1_sprite = wart_brother_1:get_sprite()
  local brother_2_sprite = wart_brother_2:get_sprite()

  hero:freeze()
  hero:set_direction(hero:get_direction4_to(wart))
  audio_manager:stop_music()

  map:start_coroutine(function()
    map:set_cinematic_mode(true)
    game:set_suspended(false) -- Workaround: Don't use the game suspension of the cinematic mode.

    -- Intro
    wait(1500)
    audio_manager:play_music("56_frogs_song_of_soul")
    start_sprite_animation(sprite, "singing_stopped", 0)
    wait(1000)
    start_sprite_animation(brother_1_sprite, "singing", 0)
    wait(1000)
    start_sprite_animation(brother_2_sprite, "singing", 0)
    wait(1850)

    -- Verse.
    for i = 0, 1, 1 do
      start_sprite_animation(sprite, "singing", 0)
      start_sprite_animation(brother_1_sprite, "waiting", 0)
      start_sprite_animation(brother_2_sprite, "waiting", 0)
      wait(900)
      start_sprite_animation(brother_1_sprite, "singing", 0)
      wait(500)
      start_sprite_animation(brother_1_sprite, "waiting", 0)
      wait(430)
      for i = 0, 6, 1 do
        start_sprite_animation(brother_1_sprite, "singing", (i + 1) % 2 * 2)
        start_sprite_animation(brother_2_sprite, "singing", i % 2 * 2)
        wait(500)
        if i == 6 then
          sol.timer.start(wart, 200, function()
            sprite:set_paused() -- Pause the Wart sprite before the Chorus.
          end)
        end
        start_sprite_animation(brother_1_sprite, "waiting", 0)
        start_sprite_animation(brother_2_sprite, "waiting", 0)
        wait(430)
      end

      -- Chorus.
      start_sprite_animation(sprite, "singing_final", 0)
      start_sprite_animation(brother_1_sprite, "singing", 0)
      start_sprite_animation(brother_2_sprite, "singing", 2)
      wait(500)
      start_sprite_animation(brother_2_sprite, "waiting", 0)
      wait(430)
      start_sprite_animation(brother_2_sprite, "singing", 0)
      wait(1950)
    end

    -- Song finished.
    wait(500)
    start_sprite_animation(sprite, "waiting", 0)
    start_sprite_animation(brother_1_sprite, "waiting", 0)
    start_sprite_animation(brother_2_sprite, "waiting", 0)
    map:set_cinematic_mode(false)
    audio_manager:play_music("18_cave")
    on_finished_callback()
  end)
end

-- Start Wart dialog.
local function start_wart_dialog()

  if game:has_item("ocarina") then
    game:start_dialog("maps.caves.south_prairie.caves_5.wart_ocarina", function(answer)
      local money = game:get_money()
      if answer == 1 and money >= 300 then
        start_wart_song(function()
          game:start_dialog("maps.caves.south_prairie.caves_5.wart_ocarina_played", function()
            hero:start_treasure("melody_3", nil, nil, function()
              hero:set_direction(hero:get_direction4_to(wart))
              game:start_dialog("maps.caves.south_prairie.caves_5.wart_done", function()
                game:remove_money(300)
              end)
            end)
          end)
        end)
      else
        game:start_dialog("maps.caves.south_prairie.caves_5.wart_refused") -- Both no money or refuse the song.
      end
    end)
  else
    game:start_dialog("maps.caves.south_prairie.caves_5.wart_no_ocarina")
  end
end

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("18_cave")
end

-- Start Wart interaction on approaching.
function wart_sensor:on_activated()

  -- Don't interact if the song is already possessed.
  if game:has_item("melody_3") then
    return
  end

  start_wart_dialog()
end

-- Start Wart dialog on manual interaction.
function wart:on_interaction()

  if game:has_item("melody_3") then
    game:start_dialog("maps.caves.south_prairie.caves_5.wart_done")
    return
  end

  start_wart_dialog()
end