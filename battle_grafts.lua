local battle_defs = require "battle/battle_defs"

local CARD_FLAGS = battle_defs.CARD_FLAGS
local BATTLE_EVENT = battle_defs.BATTLE_EVENT

--------------------------------------------------------------------

local BATTLE_GRAFTS =
{
    
}


---------------------------------------------------------------------------------------------

for i, id, graft in sorted_pairs( BATTLE_GRAFTS ) do
    graft.card_defs = battle_defs
    graft.type = GRAFT_TYPE.COMBAT
    graft.series = graft.series or "KASHIO_PLAYER"
    Content.AddGraft( id, graft )
end
