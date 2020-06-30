package.path = "./../src/?.lua;" .. package.path
pcr =
{
	core = require("pcrcore"),
	common = require("pcrcommon"),
	utils = require("pcrutils"),
}

local function simulate(team1names, team2names)
	if team2names == nil then team2names = team1names end

	local function characterstate(name)
		if pcr.common.emptycharacters[name] == nil then
			print("unknown character name ".. name)
		end
		return pcr.core.internal.characterstate(pcr.common.emptycharacters[name], 10000, 0, 0, 0, nil, {}, {})
	end
	local function maketeamname(team)
		local ret = ""
		for index, nn in next, team do
			if index ~= 1 then ret = ret .. " " end
			ret = ret .. nn
		end
		return ret
	end

	print("simulate start");
	print("team1: " .. maketeamname(team1names))
	print("team2: " .. maketeamname(team2names))

	local team1 = {}
	for _, nn in next, team1names do
		table.insert(team1, characterstate(nn))
	end
	local team2 = {}
	for _, nn in next, team2names do
		table.insert(team2, characterstate(nn))
	end
	local f0 = pcr.core.simulation.firstframe(pcr.core.internal.battlestate(0, team1, team2))
	local f1000 = pcr.core.simulation.run(f0, nil, 1000)
	pcr.utils.printinfo(f1000)
	return f1000
end

local t1 = {}
local t2 = {}

for x in string.gmatch(arg[1], "[^,]+") do
	table.insert(t1, x)
end
for x in string.gmatch(arg[2], "[^,]+") do
	table.insert(t2, x)
end
simulate(t1, t2)
