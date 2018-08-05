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

require("scripts/multi_events")

local music_manager = {}

local music_fade_timer

function music_manager:play_music_fade(context, music)

  if music_fade_timer ~= nil then
    music_fade_timer:stop()
  end

  local initial_volume = sol.audio.get_music_volume()
  local volume = initial_volume
  local step = initial_volume / 10
  local changed = false

  context:register_event("on_finished", function()
    -- Just in case the map is changed or the game is closed
    -- during the fade.
    sol.audio.set_music_volume(initial_volume)
  end)

  music_fade_timer = sol.timer.start(context, 100, function()
    if not changed then
      volume = math.max(0, volume - step)
      sol.audio.set_music_volume(volume)
      if volume <= 0 then
        sol.audio.play_music(music)
        changed = true
      end
      return true
    end
    volume = math.min(initial_volume, volume + step)
    sol.audio.set_music_volume(volume)

    return volume < initial_volume
  end)

  music_fade_timer:set_suspended_with_map(false)
end

return music_manager
