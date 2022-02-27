-- Script that creates a game ready to be played.

-- Usage:
-- local game_manager = require("scripts/game_manager")
-- local game = game_manager:create("savegame_file_name")
-- game:start()

local initial_game = require("scripts/initial_game")

local game_manager = {}

-- Creates a game ready to be played.
function game_manager:create(file)

  -- Create the game (but do not start it).
  local exists = sol.game.exists(file)
  local game = sol.game.load(file)
  if not exists then
    -- This is a new savegame file.
    initial_game:initialize_new_savegame(game)
  end

  return game

end

local game_meta = sol.main.get_metatable("game")

function game_meta:get_player_name()

  local game = self
  local name = game:get_value("player_name")
  local hero_is_thief = game:get_value("hero_is_thief")
  if hero_is_thief then
    name = sol.language.get_string("game.thief")
  end
  return name
end

function game_meta:set_player_name(player_name)
  local game = self
  game:set_value("player_name", player_name)
end

-- Returns whether the current map is in the inside world.
function game_meta:is_in_inside_world()
  local game = self
  return game:get_map():get_world() == "inside_world"
end

-- Returns whether the current map is in the outside world.
function game_meta:is_in_outside_world()
  local game = self
  return game:get_map():get_world() == "outside_world"
end

-- Returns whether the current map is in a dungeon.
function game_meta:is_in_dungeon()
  local game = self
  return game:get_dungeon() ~= nil
end

-- Returns whether something is consuming magic continuously.
function game_meta:is_magic_decreasing()
  local game = self
  return game.magic_decreasing or false
end

-- Sets whether something is consuming magic continuously.
function game_meta:set_magic_decreasing(magic_decreasing)
  local game = self
  game.magic_decreasing = magic_decreasing
end


return game_manager
