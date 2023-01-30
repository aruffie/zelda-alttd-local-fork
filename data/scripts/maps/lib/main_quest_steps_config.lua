local steps={
  "game_started",
  "hero_awakened",
  "shield_obtained",
  "sword_obtained",
  "tarin_saved",
  "dungeon_1_key_obtained",
  "dungeon_1_opened",
  "dungeon_1_completed",
  "bowwow_dognapped",
  "bowwow_joined",
  "dungeon_2_completed",
  "bowwow_returned",
  "castle_bridge_built",
  "golden_leaved_returned",
  "dungeon_3_key_obtained",
  "dungeon_3_opened",
  "dungeon_3_completed",
  "tarin_bee_event_over",
  "started_looking_for_marin",
  "marin_joined",
  "walrus_awakened",
  "sandworm_killed",
  "dungeon_4_key_obtained",
  "dungeon_4_opened",
  "dungeon_4_completed",
  "ghost_joined",
  "ghost_saw_his_house",
  "ghost_house_visited",
  "ghost_returned_to_tomb"
}

local index={}
for k,v in ipairs(steps) do
  index[v]=k
end
return index