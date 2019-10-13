-- Copyright (C) 2018 Christopho, Solarus - http://www.solarus-games.org
--
-- Solarus Quest Editor is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Solarus Quest Editor is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program. If not, see <http://www.gnu.org/licenses/>.

-- Main Lua script of the quest.

require("scripts/features")
local shader_manager = require("scripts/shader_manager")
local initial_menus_config = require("scripts/menus/initial_menus_config")
local initial_menus = {}

-- This function is called when Solarus starts.
function sol.main:on_started()

  sol.main.load_settings()
  math.randomseed(os.time())

  -- Show the initial menus.
  if #initial_menus_config == 0 then
    return
  end

  for _, menu_script in ipairs(initial_menus_config) do
    initial_menus[#initial_menus + 1] = require(menu_script)
  end

  local on_top = false  -- To keep the debug menu on top.
  sol.menu.start(sol.main, initial_menus[1], on_top)
  for i, menu in ipairs(initial_menus) do
    function menu:on_finished()
      if sol.main.game ~= nil then
        -- A game is already running (probably quick start with a debug key).
        return
      end
      local next_menu = initial_menus[i + 1]
      if next_menu ~= nil then
        sol.menu.start(sol.main, next_menu)
      end
    end
  end

end

-- Event called when the program stops.
function sol.main:on_finished()

  sol.main.save_settings()

end

local eff_m = require('scripts/maps/effect_manager')
local fsa = require('scripts/maps/fsa_effect')
local gb = require('scripts/maps/gb_effect')
local audio_manager = require('scripts/audio_manager')
-- Event called when the player pressed a keyboard key.
function sol.main:on_key_pressed(key, modifiers)

  local handled = false
  local game = sol.main.game
  if key == "f5" then
    -- F5: change the video mode.
    shader_manager:switch_shader()
  elseif key == 'f9' then
    eff_m:set_effect(sol.main.get_game(),gb)
    game:set_value("mode", "gb")
    audio_manager:refresh_music()
  elseif key == 'f7' then
    eff_m:set_effect(sol.main.get_game(),fsa)
    game:set_value("mode", "snes")
    audio_manager:refresh_music()
  elseif key == 'f8' then
    game:set_value("mode", "snes")
    eff_m:set_effect(sol.main.get_game())
    audio_manager:refresh_music()
  elseif key == "f11" or
  (key == "return" and (modifiers.alt or modifiers.control)) then
    -- F11 or Ctrl + return or Alt + Return: switch fullscreen.
    sol.video.set_fullscreen(not sol.video.is_fullscreen())
    handled = true
  elseif key == "f4" and modifiers.alt then
    -- Alt + F4: stop the program.
    sol.main.exit()
    handled = true
  elseif key == "escape" and sol.main.game == nil then
    -- Escape in title screens: stop the program.
    sol.main.exit()
    handled = true
  end

  return handled
end

-- Starts a game.
function sol.main:start_savegame(game)

  -- Skip initial menus if any.
  for _, menu in ipairs(initial_menus) do
    sol.menu.stop(menu)
  end

  local ceiling_drop_manager = require("scripts/maps/ceiling_drop_manager")
  for _, entity_type in pairs({"hero", "pickable"}) do
    ceiling_drop_manager:create(entity_type)
  end
  sol.main.game = game
  game:set_transition_style("immediate")

  game:start()
end
