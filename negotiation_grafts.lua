local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT
local CARD_FLAGS = negotiation_defs.CARD_FLAGS

local GRAFTS =
{
   
}

---------------------------------------------------------------------------------------------

for i, id, graft in sorted_pairs( GRAFTS ) do
    graft.card_defs = negotiation_defs
    graft.type = GRAFT_TYPE.NEGOTIATION
    graft.series = graft.series or "KASHIO_PLAYER"
    Content.AddGraft( id, graft )
end

