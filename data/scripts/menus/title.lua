-- Title screen.
-- Author: Olivier Cléro (oclero@hotmail.com)

local title = {}

local title_background = require("scripts/menus/title_background")
local title_logo = require("scripts/menus/title_logo")
local file_selection = require("scripts/menus/file_selection")

local multi_events = require("scripts/multi_events")

function title:on_started()
  -- Play music.
  sol.audio.play_music("scripts/menus/title_screen")

  self.finished = false

  -- Start the background.
  -- The background does not eat keys or buttons.
  sol.menu.start(self, title_background, true)

  -- Register a callback for when the logo is finished.
  -- The logo will end when the user press Space (or any key).
  multi_events:enable(title_logo)
  multi_events:enable(file_selection)
  multi_events:enable(title_background)
  title_logo:register_event("on_finished", function()
    -- Start the file selection menu.
    sol.menu.start(self, file_selection, true)
  end)
  file_selection:register_event("on_finished", function()
    -- Fade the background to black.
    title_background:set_phase(title_background.PHASE_6)
  end)
  title_background:register_event("on_finished", function()
    -- Launch the savegame.
    if file_selection.choosen_savegame ~= nil then
      sol.main:start_savegame(file_selection.choosen_savegame)
    end
  end)
  sol.menu.start(self, title_logo, true)

end

function title:on_key_pressed(key)

  local handled = false

  if key == "escape" then
    -- Stop the program.
    sol.main.exit()
    
  elseif (key == "space" or key == "return") and not self.finished then
    self.finished = true

    -- Go directly to the phase 4.
    if title_background.phase < title_background.PHASE_4 then
      title_background:set_phase(title_background.PHASE_4)
    end

    handled = true
  end

  return handled
end

return title

