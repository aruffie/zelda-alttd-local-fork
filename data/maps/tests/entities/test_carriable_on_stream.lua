-- Checking that throwing a carriable over a stream does not trigger the stream.

local map = ...
local game = map:get_game()

function map:on_started()

  game:get_item("bombs_bag"):set_variant(1)
  local bombs_counter = game:get_item("bombs_counter")
  bombs_counter:set_amount(10)
  game:set_item_assigned(1, bombs_counter)
end

function map:do_after_transition()

  sol.timer.start(map, 100, function()
    game:simulate_command_pressed("item_1")
    sol.timer.start(map, 100, function()
      local carriable = hero:get_facing_entity()
      assert(carriable ~= nil)
      assert(carriable:get_model() == "bomb")
      local initial_x, initial_y = carriable:get_position()
      game:simulate_command_pressed("action")
      assert(hero:get_state() == "frozen")
      sol.timer.start(map, 1000, function()
        assert(hero:get_state() == "custom")  -- Custom carrying state.
        game:simulate_command_pressed("action")
        assert(hero:get_state() == "free")
        sol.timer.start(map, 2000, function()
          local x, y = carriable:get_position()
          local stream_x, stream_y = stream:get_position()
          assert(y > stream_y + 16)  -- It should have passed the stream.
          assert(x == initial_x)     -- x should not have changed.
          sol.main.exit()
        end)
      end)
    end)
  end)
end
