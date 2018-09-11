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
  sol.menu.start(self, title_background, true)

  -- Register a callback for when the logo is finished.
  multi_events:enable(title_logo)
  title_logo:register_event("on_finished", function()
    sol.menu.start(self, file_selection, true)
  end)

  -- The title appears when the sound is played during the music.
  -- Unfortunately, they are mixed together...
  --self.timer = sol.timer.start(self, 6000, function()
    sol.menu.start(self, title_logo, true)
  --end)

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

    title_background:set_phase("end")
    --sol.menu.start(self, title_logo, true)

    handled = true
  end

  return handled
end

return title

