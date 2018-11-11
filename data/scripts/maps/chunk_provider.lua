local cp = {}

local chunk_size = 256
local chunk_width = chunk_size
local chunk_height = chunk_size

function cp:chunk_id(chunk_x,chunk_y,layer)
  return chunk_x +
    chunk_y*chunk_width +
    (layer-self.map:get_min_layer())*chunk_width*chunk_height
end

function cp.create(map, predicate)
  return setmetatable({
      map=map,
      chunks = {},
      predicate=predicate
      },cp)
end

cp.__index = cp

function cp:get_chunk(chunk_x,chunk_y,layer)
  --don't recompute map_occluder for the same layer
  local cid = self:chunk_id(chunk_x,chunk_y,layer)
  local chunk = self.chunks[cid]
  if not chunk then
    --create chunk as it doesn't exist
    chunk = {surf=sol.surface.create(chunk_size,chunk_size),valid=false}
    self.chunks[cid] = chunk
  end
  if chunk.valid then
    -- chunk is still valid, return it as is
    return chunk.surf
  end
  --chunk is invalid, update it!
  --print(string.format("computing chunk at (%d,%d,%d)",chunk_x,chunk_y,layer))
  local map = self.map
  local cx,cy = chunk_x*chunk_size,chunk_y*chunk_size
  local l = layer
  local dx,dy = cx % 8, cy % 8
  local w,h = chunk_size, chunk_size
  chunk.surf:clear()
  for x=0,w,8 do
    for y=0,h,8 do
      local ground = map:get_ground(cx+x,cy+y,l)
      local should, color = self.predicate(ground,map)
      if should then
        chunk.surf:fill_color(color,x-dx,y-dy,8,8)
      end
    end
  end
  chunk.valid = true
  return chunk.surf
end

function cp:invalidate_chunks()
  for _,chunk in pairs(self.chunks) do
    chunk.valid = false
  end
end

function cp:fill_surf(dst,x,y,l)
  local w,h = dst:get_size()
  
  --compute overlapped chunks
  local cxmin = math.floor(x/chunk_size)
  local cymin = math.floor(y/chunk_size)

  local cxmax = math.floor((x+w)/chunk_size)
  local cymax = math.floor((y+h)/chunk_size)


--  dst:clear()

  --draw occlusion chunks on the light occlusion map
  for cx = cxmin,cxmax do
    for cy = cymin,cymax do
      local chunk = self:get_chunk(cx,cy,l)
      local cxx = cx*chunk_size
      local cyy = cy*chunk_size
      local rx,ry = cxx-x,cyy-y
      chunk:draw(dst,rx,ry)
    end
  end
end

return cp