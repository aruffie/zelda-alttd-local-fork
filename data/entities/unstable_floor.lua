local entity = ...

local default_sprite_id = "entities/cave_hole"
local break_sound = "explosion"
local time_resistance = 1000 -- The time it resists with hero above. In milliseconds.

-- Event called when the custom entity is initialized.
function entity:on_created()

  local hero = self:get_map():get_hero()
  -- Add an unstable floor (do not save ground position!!!).
  self:set_modified_ground("traversable")
  self:set_property("unstable_floor", "true")
  --self:bring_to_back()
  -- Create sprite if necessary.
  if self:get_sprite() == nil then self:create_sprite(default_sprite_id) end
  -- Add collision test. Break if the hero stays above more time than time_resistance.
  local time_above = 0 -- Stores how much time the hero has been above.
  local layer = self:get_layer()
  local timer = nil
  local timer_delay = 50

  self:add_collision_test(function(this, other) -- Test: ground position inside bounding box.
    if timer then return end
    if other:get_type() ~= "hero" then return false end
    if hero:is_jumping() or hero:get_state() == "jumping" then return false end
    local hx, hy, hl = hero:get_ground_position()
    if hl ~= layer then return false end
    return this:overlaps(hx, hy)
  end, function() -- Callback: play sound and remove entity.
    timer = sol.timer.start(entity , timer_delay, function()
      local hx, hy, hl = hero:get_ground_position()
      if hl == layer and entity:overlaps(hx, hy)
            and (not hero:is_jumping()) and hero:get_state() ~= "jumping" then
        time_above = time_above + timer_delay
        if time_above >= time_resistance then
          sol.audio.play_sound(break_sound)
          local prefix = entity:get_name()
          for entity_map in self:get_map():get_entities(prefix .. "_") do
            entity_map:remove()
          end
          entity:remove()
        end
        return true
      else
        timer:stop()
        time_above = 0
        timer = nil
      end
    end)

  end)
end
