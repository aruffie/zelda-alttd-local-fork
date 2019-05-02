----------------------------------
--
-- A pull handle that can be pulled and come back to its inital place.
--
-- Events :  pull_handle:on_pulling(movement_count)
--           pull_handle:on_dropped()
--
----------------------------------

local pull_handle = ...
local game = pull_handle:get_game()
local map = pull_handle:get_map()

-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
pull_handle:register_event("on_created", function()

  local movement_count = 0
  local initial_x, initial_y, initial_layer = pull_handle:get_position()

  -- Create the chain.
  local handle_chain = map:create_custom_entity({
    name = "handle_chain",
    x = initial_x,
    y = initial_y,
    layer = initial_layer,
    direction = 0,
    sprite = "entities/handle_chain",
    width = 8,
    height = 8
  })
  handle_chain:set_tiled(true)
  handle_chain:set_traversable_by("hero", false)
  handle_chain:set_drawn_in_y_order(true)

  -- Create the block to pull that will replace the custom entity.
  local handle_block = map:create_block({
    name = "handle_block",
    layer = initial_layer,
    x = initial_x,
    y = initial_y,
    direction = 3,
    sprite = pull_handle:get_sprite(""):get_animation_set(),
    pushable = false,
    pullable = true,
    max_moves = 4, -- TODO
    enabled_at_start = true})
  handle_block:set_drawn_in_y_order(true)

  -- Return the distance in pixel between the block y position and its initial place.
  local function get_y_gap()
    local _, block_y = handle_block:get_position()
    return  block_y - initial_y
  end

  -- Setup the return movement when the hero drop the handle.
  local hero = map:get_hero()
  hero:register_event("on_state_changing", function(hero, state_name, next_state_name)
    local is_letting_go = (state_name == "pulling" or state_name == "grabbing" or state_name == "pushing") and next_state_name == "free"
    if is_letting_go and get_y_gap() ~= 0 then
      local movement = sol.movement.create("straight")
      movement:set_angle(math.pi / 2)
      movement:set_speed(10)
      movement:set_max_distance(get_y_gap())
      movement:set_smooth(false)
      movement:start(handle_block)
      -- Resize the chain while going back to initial place.
      function movement:on_position_changed()
        local y_gap = get_y_gap()
        if y_gap > 0 then
          handle_chain:set_size(8, y_gap)
        end
      end
      -- Reset move count when back to initial place.
      function movement:on_finished()
        handle_block:reset() 
        movement_count = 0
      end
      -- Call the dropped event.
      if pull_handle.on_dropped then
        pull_handle:on_dropped()
      end
    end
  end)

  -- Behavior at the beginning of each pull.
  function handle_block:on_moving()
    movement_count = movement_count + 1

    -- Call the pulling event.
    if pull_handle.on_pulling then
      pull_handle:on_pulling(movement_count)
    end

    -- Resize the chain.
    handle_chain:set_size(8, get_y_gap() + 16)
  end

  -- Hide the initial custom_entity and resize it to not conflict with the block grab.
  pull_handle:remove_sprite(pull_handle:get_sprite(""))
  pull_handle:set_size(8, 8)
end)