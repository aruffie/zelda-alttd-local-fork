-- Title screen.

local title = {}

local title_background = require("scripts/menus/title_background")
local title_logo = require("scripts/menus/title_logo")
local file_selection = require("scripts/menus/file_selection")

local multi_events = require("scripts/multi_events")

function title:on_started()
  -- Play music.
  sol.audio.play_music("scripts/menus/title_screen")

  -- Start the background.
  -- The background does not eat keys or buttons.
  sol.menu.start(self, title_background, true)

  -- Register a callback for when the logo is finished.
  -- The logo will end when the user press Space (or any key).
  multi_events:enable(title_logo)
  multi_events:enable(file_selection)
  title_logo:register_event("on_finished", function()
    -- Start the file selection menu.
    sol.menu.start(self, file_selection, true)
  end)
  file_selection:register_event("on_finished", function()
    -- Fade to black.
    print("fade everything")
  end)
  sol.menu.start(self, title_logo, true)

  -- Surface used for fading to black, at the end.
  --self.fade_surface = sol.surface.create(self.surface_w, self.surface_h)
  --self.fade_surface:fill_color({0, 0, 0})

end

function title:on_key_pressed(key)

  local handled = false

  print(key)

  if key == "escape" then
    -- stop the program
    sol.main.exit()

  elseif key == "space" or key == "return" then
    print("title space")

    if self.timer ~= nil then
      self.timer:stop()
    end

    --if title_background.phase 
    title_background:set_phase(title_background.PHASE_4)
    --sol.menu.start(self, title_logo, true)

    handled = true
  end

  return handled
end

return title

