-- Initialize NPC behavior specific to this quest.

local npc_meta = sol.main.get_metatable("npc")

function npc_meta:on_created()

  local name = self:get_name()
  if name == nil then
    return
  end

  if name:match("^walking_npc") then
    self:random_walk()
  end
  
  local model = self:get_property("model")
  if model ~= nil then
    require("scripts/npc/" .. model)(self)
  end
  
end

-- Make signs hooks for the hookshot.
function npc_meta:is_hookable()

  local sprite = self:get_sprite()
  if sprite == nil then
    return false
  end

  return sprite:get_animation_set() == "entities/sign"
  
end

-- Makes the NPC randomly walk with the given optional speed.
function npc_meta:random_walk(speed)

  local movement = sol.movement.create("random_path")

  if speed ~= nil then
    movement:set_speed(speed)
  end

  movement:start(self)
  
end

-- Create an exclamation symbol near npc
function npc_meta:create_symbol_exclamation(x, y, layer)
  
  local map = self:get_map()
  local x, y, layer = self:get_position()
  audio_manager:play_sound("menus/menu_select")
  local symbol = map:create_custom_entity({
    sprite = "entities/symbol_exclamation",
    x = x - 16,
    y = y - 16,
    width = 16,
    height = 16,
    layer = layer + 1,
    direction = 0
  })

  return symbol
  
end

-- Create an interrogation symbol near npc
function npc_meta:create_symbol_interrogation()
  
  local map = self:get_map()
  local x, y, layer = self:get_position()
  audio_manager:play_sound("menus/menu_select")
  local symbol = map:create_custom_entity({
    sprite = "entities/symbol_interrogation",
    x = x - 16,
    y = y - 16,
    width = 16,
    height = 16,
    layer = layer + 1,
    direction = 0
  })

  return symbol
  
end

-- Create a collapse symbol near npc
function npc_meta:create_symbol_collapse()
  
  local map = self:get_map()
  local x, y, layer = self:get_position()
  local symbol = map:create_custom_entity({
    sprite = "entities/symbol_collapse",
    x = x - 16,
    y = y - 16,
    width = 16,
    height = 16,
    layer = layer + 1,
    direction = 0
  })

  return symbol
  
end

return true
