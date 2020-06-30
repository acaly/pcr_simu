package.path = "./../src/?.lua;" .. package.path
local pcr =
{
	core = require("pcrcore"),
	common = require("pcrcommon"),
	utils = require("pcrutils"),
}

function pcr.utils.maketeam(names)
	local function characterstate(name)
		if pcr.common.emptycharacters[name] == nil then
			print("unknown character name ".. name)
		end
		return pcr.core.internal.characterstate(pcr.common.emptycharacters[name], 10000, 0, 0, 0, nil, {}, {})
	end
	
	local t = {}
	for x in string.gmatch(names, "[^,]+") do
		table.insert(t, characterstate(x))
	end
	return t
end

function pcr.utils.makebattle(team1, team2)
	return pcr.core.simulation.firstframe(pcr.core.internal.battlestate(0, pcr.utils.maketeam(team1), pcr.utils.maketeam(team2)))
end

return pcr
