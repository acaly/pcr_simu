package.path = "./../src/?.lua;" .. package.path
pcr =
{
	core = require("pcrcore"),
	common = require("pcrcommon"),
	utils = require("pcrutils"),
}

local options = {
	showresults = false,
}
for _, aa in next, arg do
	if options[aa] ~= nil then options[aa] = true end
end

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
	
	if options.showresults then
		pcr.utils.printinfo(f1000)
	end
	return f1000
end

local function findinteam(team, id)
	for _, ch in next, team do
		if ch.character.id == id then return ch end
	end
	return nil
end

local function mirrorrelativetime(frame)
	local time = {}
	for _, ch in next, frame.state.team1 do
		time[ch.character.id] = ch.readytime
	end
	for _, ch in next, frame.state.team2 do
		if time[ch.character.id] ~= nil and ch.readytime ~= nil then
			time[ch.character.id] = ch.readytime - time[ch.character.id]
		end
	end
	return time
end

local function teamtime(frame)
	local g = pcr.utils.getfirstreadytime(frame.state)
	local ret = { team1 = {}, team2 = {} }
	for _, ch in next, frame.state.team1 do
		if ch.readytime ~= nil then
			ret.team1[ch.character.id] = ch.readytime - g
		end
	end
	for _, ch in next, frame.state.team2 do
		if ch.readytime ~= nil then
			ret.team2[ch.character.id] = ch.readytime - g
		end
	end
	return ret
end

local function check(desc, r)
	if _G.failurecount == nil then _G.failurecount = 0 end
	if _G.successcount == nil then _G.successcount = 0 end
	if not r then
		print("FAIL:" .. desc)
		_G.failurecount = _G.failurecount + 1
	else
		_G.successcount = _G.successcount + 1
	end
end

print("test 1: compare rino teams")
print("==========")
do
	local f = simulate({ "lima", "yukari", "saren_summer", "rino", "yuki" }, nil)

	local mirror = mirrorrelativetime(f)
	check("yukari relative time", mirror.yukari == 0)
	check("saren relative time", mirror.saren_summer == -1)
	check("rino relative time", mirror.rino == 0)
	check("yuki relative time", mirror.yuki == 0)

	local team = teamtime(f)
	check("yukari vs saren", team.team1.saren_summer - team.team1.yukari == 1)
end
do
	local f = simulate({ "kokkoro_spring", "yukari", "saren_summer", "rino", "yuki" }, nil)
	local mirror = mirrorrelativetime(f)
	check("rino relative time", mirror.rino == -1)
	--relative time of others not confirmed
end
do
	local f = simulate({ "miyako", "yukari", "mitsuki", "rino", "yuki" }, nil)
	local mirror = mirrorrelativetime(f)
	check("rino relative time", mirror.miyako == 0)
	check("rino relative time", mirror.yukari == -1)
	check("rino relative time", mirror.mitsuki == 0)
	check("rino relative time", mirror.rino == 0)
	check("rino relative time", mirror.yuki == 0)
end
print()

print("test 1 additional: yukari + saren_summer vs karyl")
do
	local f = simulate({ "karyl" }, { "lima", "yukari", "saren_summer" })
	
	local team = teamtime(f)
	check("yukari vs saren", team.team2.saren_summer - team.team2.yukari == 2)
end

--TODO the new algorithm gives error in this test, because it effectively extends both distances by 12
--frame count differences between characters are consistent with experiment
--TODO add frame diff
print("test 2: rino vs kyouka")
print("==========")
do
	local f = simulate({ "lima", "yukari", "mitsuki", "rino", "yuki" },
		{ "nozomi", "makoto", "tamaki", "maho", "kyouka" })
	local distance = math.abs(findinteam(f.state.team1, "rino").pos - findinteam(f.state.team2, "kyouka").pos)
	check("rino attacking", distance > 1150 + 100 + 12)

	local team = teamtime(f)
	check("yukari time", team.team1.yukari == 0)
	check("mitsuki time", team.team1.mitsuki == 1)
	check("rino time", team.team1.rino == 4)
	check("yuki time", team.team1.yuki == 8)
	check("kyouka time", team.team2.kyouka == 31)
end
do
	local f = simulate({ "nozomi", "makoto", "tamaki", "maho", "kyouka" },
		{ "lima", "yukari", "mitsuki", "rino", "yuki" })
	local distance = math.abs(findinteam(f.state.team2, "rino").pos - findinteam(f.state.team1, "kyouka").pos)
	check("rino defending", distance < 1150 + 100 + 12)

	local team = teamtime(f)
	check("yukari time", team.team2.yukari == 0)
	check("mitsuki time", team.team2.mitsuki == 2)
	check("rino time", team.team2.rino == 5)
	check("yuki time", team.team2.yuki == 9)
	check("kyouka time", team.team1.kyouka == 33)
end
print()

print("test 3: kuuka + jun")
print("==========")
do
	local f = simulate({ "kuuka", "jun" }, { "nozomi" })
	check("vs nozomi", findinteam(f.state.team1, "kuuka").pos < findinteam(f.state.team1, "jun").pos)

	local team = teamtime(f)
	check("nozomi time", team.team2.nozomi == 0)
	check("kuuka time", team.team1.kuuka == 2)
	check("jun time", team.team1.jun == 19)
end
do
	local f = simulate({ "kuuka", "jun" }, { "miyako" })
	check("vs miyako", findinteam(f.state.team1, "kuuka").pos > findinteam(f.state.team1, "jun").pos)

	local team = teamtime(f)
	check("miyako time", team.team2.miyako == 0)
	check("kuuka time", team.team1.kuuka == 0)
	check("jun time", team.team1.jun == 15)
end
do
	local f = simulate({ "kuuka", "jun" }, { "lima_only" })
	check("vs miyako", findinteam(f.state.team1, "kuuka").pos > findinteam(f.state.team1, "jun").pos)

	local team = teamtime(f)
	check("lima time", team.team2.lima == 0)
	check("kuuka time", team.team1.kuuka == 0)
	check("jun time", team.team1.jun == 15)
end
print()

print("test 4: yukari + miyako_halloween")
print("==========")
do
	local f = simulate({ "yukari", "miyako_halloween" }, { "lima", "yukari", "miyako_halloween" })

	local mirror = mirrorrelativetime(f)
	check("yukari relative time", mirror.yukari == -1)
	check("saren relative time", mirror.miyako_halloween == 0)

	local team = teamtime(f)
	check("yukari vs miyako", team.team1.miyako_halloween - team.team1.yukari == 0)
end
print()

print("" .. (successcount or 0) .. " successes, " .. (failurecount or 0) .. " failures")
