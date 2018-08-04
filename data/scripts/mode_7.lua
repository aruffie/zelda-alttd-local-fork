-- Experimental mode 7 testing code.

local mode_7_manager = {}

local world_width, world_height = 3840, 3072
local map_texture

-- Determines the coordinates of a destination entity on am outside map that is not loaded.
local function get_dst_xy(dst_map_id, dst_name)
  -- TODO parse the map file to get the location of the map and the coordinates of the entity.
  -- Store that in a cache.
  -- Put it in another script.

  -- temporary
  if dst_map_id == "out/b3_prairie" then
    return 960 + 368, 1536 + 360
  elseif dst_map_id == "out/a1_west_mt_tamaranch" then
    return 0 + 432, 0 + 112
  elseif dst_map_id == "out/d1_east_mt_tamaranch" then
    return 2880 + 192, 0 + 536
  elseif dst_map_id == "out/d4_yarna_desert" then
    return 2880 + 192, 2304 + 592
  end
end

-- Start a mode 7 travel sequence.
-- - game: The current game.
-- - src_entity: An entity where to start from in the current map.
-- - dst_map_id: Id of the destination map.
-- - dst_name: Name of the destination entity where to go in the destination map.
function mode_7_manager:teleport(game, src_entity, destination_map_id, destination_name)

  local mode_7 = {}

  assert(game ~= nil)
  assert(sol.main.get_type(game) == "game")
  assert(destination_map_id ~= nil)

  local quest_width, quest_height = sol.video.get_quest_size()
  local hero = game:get_hero()
  local hero_sprite = sol.sprite.create(hero:get_tunic_sprite_id())
  local owl_sprite = sol.sprite.create("npc/owl")
  if map_texture == nil then
    map_texture = sol.surface.create("work/world_map_scale_1.png")
  end
  assert(map_texture ~= nil)
  local overlay_texture = sol.surface.create(320, 240)
  local previous_shader = sol.video.get_shader()
  local shader = sol.shader.create("mode_7")
  shader:set_uniform("mode_7_texture", map_texture)
  shader:set_uniform("repeat_texture", false)
  shader:set_uniform("horizon", 1.25)
  local position_on_texture = { 0.5, 1.0, 0.08 }
  mode_7.xy = {}
  local xy = mode_7.xy
  local initial_distance
  local distance_remaining
  local angle = 0.0

  local function update_shader()
    local z  -- 0 to 1 and then to 0 again.
    local half_distance = initial_distance / 2.0
    if distance_remaining > half_distance then
      z = 1.0 - (distance_remaining - half_distance) / half_distance
    else
      z = distance_remaining / half_distance
    end
    position_on_texture[1] = xy.x / world_width
    position_on_texture[2] = xy.y / world_height
    position_on_texture[3] = 0.05 + 0.1 * z
    shader:set_uniform("character_position", position_on_texture)
    shader:set_uniform("angle", angle)
    shader:set_uniform("horizon", 1.25)
    --shader:set_uniform("horizon", 2.75 - 1.5 * z)
  end

  local function update_overlay()
    overlay_texture:clear()
    local x, y = quest_width / 2, quest_height - 67
    owl_sprite:draw(overlay_texture, x, y)
    hero_sprite:draw(overlay_texture, x, y + 16)
    shader:set_uniform("overlay_texture", overlay_texture)
  end

  function mode_7:on_started()

    local map = game:get_map()
    local map_x, map_y = map:get_location()
    local src_x_in_map, src_y_in_map = src_entity:get_position()
    xy.x, xy.y = map_x + src_x_in_map, map_y + src_y_in_map

    hero_sprite:set_direction(3)
    hero_sprite:set_animation("flying")
    function hero_sprite:on_frame_changed()
      update_overlay()
    end
    owl_sprite:set_direction(1)
    owl_sprite:set_animation("walking")
    function owl_sprite:on_frame_changed()
      update_overlay()
    end

    local dst_x, dst_y = get_dst_xy(destination_map_id, dst_name)
    local xy_movement = sol.movement.create("target")
    initial_distance = sol.main.get_distance(xy.x, xy.y, dst_x, dst_y)
    distance_remaining = initial_distance
    xy_movement:set_target(dst_x, dst_y)
    xy_movement:set_speed(200)
    xy_movement:start(xy, function()
      sol.menu.stop(mode_7)
    end)
    function xy_movement:on_position_changed()
      angle = -xy_movement:get_angle() + (math.pi / 2.0)
      distance_remaining = sol.main.get_distance(xy.x, xy.y, dst_x, dst_y)
      update_shader()
    end
    xy_movement:on_position_changed()

    sol.timer.start(mode_7, 10, function()
      update_shader()
      return true
    end)

    game:set_suspended(true)  -- Because the map continues to run normally.
    game:set_pause_allowed(false)
    sol.audio.play_music("scripts/menus/title_screen_no_intro")
    update_overlay()
    update_shader()
    sol.video.set_shader(shader)
  end

  function mode_7:on_finished()
    sol.video.set_shader(previous_shader)
    hero:set_enabled(true)
    game:set_suspended(false)
    game:set_pause_allowed(true)
    hero:teleport(destination_map_id, destination_name, "immediate")
  end

  sol.menu.start(game, mode_7)
end

return mode_7_manager
