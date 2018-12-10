-- Initialize crystal block behavior specific to this quest.

-- Variables
local crystal_block_meta = sol.main.get_metatable("crystal_block")

-- Include scripts

function crystal_block_meta:on_created()
    
  self:remove_sprite()
  self:create_sprite("entities/objects/crystal_block")

end