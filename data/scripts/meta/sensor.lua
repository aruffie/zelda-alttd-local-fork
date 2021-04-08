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

-- Initialize sensor behavior specific to this quest.
local audio_manager = require("scripts/audio_manager")
local sensor_meta = sol.main.get_metatable("sensor")
require("scripts/multi_events")

sensor_meta:register_event("on_activated", function(sensor)

  local hero = sensor:get_map():get_hero()
  local game = sensor:get_game()
  local map = sensor:get_map()
  local name = sensor:get_name() or ""
  -- Sensors named "to_layer_X_sensor" move the hero on that layer.
  -- TODO use a custom entity or a wall to block enemies and thrown items?
  if sensor:get_property("layer_up") or name:match("^layer_up_sensor") then
    local x, y, layer = hero:get_position()
    if layer < map:get_max_layer() then
      hero:set_position(x, y, layer + 1)
    end
    return
  elseif sensor:get_property("layer_down") or name:match("^layer_down_sensor") then
    local x, y, layer = hero:get_position()
    if layer > map:get_min_layer() then
      hero:set_position(x, y, layer - 1)
    end
    return
  end

  -- Sensors prefixed by "save_solid_ground_sensor" are where the hero come back
  -- when falling into a hole or other bad ground.
  if sensor:get_property("save_solid_ground") or name:match("^save_solid_ground_sensor") then
    if not hero.respawn_point_saved then
      hero:save_solid_ground()
      hero.respawn_point_saved=true
    end
    return --TODO remove me to allow properties cumulation !
  end

  -- Sensors prefixed by "reset_solid_ground_sensor" clear any place for the hero
  -- to come back when falling into a hole or other bad ground.
  if sensor:get_property("reset_solid_ground") or name:match("^reset_solid_ground_sensor") then
    hero:reset_solid_ground()
    hero.respawn_point_saved=nil
    if hero.initialize_unstable_floor_manager then
      hero:initialize_unstable_floor_manager()
    end
    return
  end

  -- Sensors prefixed by "dungeon_room_N" save the exploration state of the
  -- room "N" of the current dungeon floor.
  local room = name:match("^dungeon_room_(%d+)")
  if room ~= nil then
    game:set_explored_dungeon_room(nil, nil, tonumber(room))
    sensor:remove()
    return
  end

  -- Sensors named "open_quiet_X_sensor" silently open doors prefixed with "X".
  local door_prefix = name:match("^open_quiet_([a-zA-X0-9_]+)_sensor")
  if door_prefix ~= nil then
    map:set_doors_open(door_prefix, true)
    return
  end

  -- Sensors named "close_quiet_X_sensor" silently close doors prefixed with "X".
  door_prefix = name:match("^close_quiet_([a-zA-X0-9_]+)_sensor")
  if door_prefix ~= nil then
    map:set_doors_open(door_prefix, false)
    return
  end

  -- Sensors named "open_loud_X_sensor" open doors prefixed with "X".
  door_prefix = name:match("^open_loud_([a-zA-X0-9_]+)_sensor")
  if door_prefix ~= nil then
    map:open_doors(door_prefix)
    return
  end

  -- Sensors named "close_loud_X_sensor" close doors prefixed with "X".
  door_prefix = name:match("^close_loud_([a-zA-X0-9_]+)_sensor")
  if door_prefix ~= nil then
    map:close_doors(door_prefix)
    return
  end

  -- Sensors named "weak_floor_X_sensor" detect explosions on a weak floor dynamic tile called "weak_floor_x".
  local tile_name = name:match("^weak_floor_([a-zA-X0-9_]+)_sensor")
  if tile_name ~= nil then
    local tile map:get_entity(tile_name)
    if tile ~= nil then
      tile:remove()
    end
    return
  end

  -- Sensors named "music_sensor" change the music.
  local music_prefix = name:match("^music_sensor")
  if music_prefix ~= nil then
    local music = sensor:get_property("music")
    audio_manager:play_music_fade(map, music)
  end
end)

function sensor_meta:on_activated_repeat()

  local hero = self:get_map():get_hero()
  local game = self:get_game()
  local map = self:get_map()
  local name = self:get_name() or ""

  -- Sensors called open_house_xxx_sensor automatically open an outside house door tile.
  local door_name = name:match("^open_house_([a-zA-X0-9_]+)_sensor")
  if door_name ~= nil then
    local door = map:get_entity(door_name)
    if door ~= nil then
      if hero:get_direction() == 1
	         and door:is_enabled() then
        door:set_enabled(false)
        audio_manager:play_sound("misc/dungeon_door_open")
      end
    end
  end
end

return true
