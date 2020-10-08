
local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local CARDS =
{
   
}

for i, id, carddef in sorted_pairs( CARDS ) do
    carddef.series = "KASHIO_PLAYER"
    Content.AddNegotiationCard( id, carddef )
end


-- for i, id, def in sorted_pairs( MODIFIERS ) do
--     Content.AddNegotiationModifier( id, def )
-- end