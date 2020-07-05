local core = {}

core.internal = {}

--[[
	character table:
		name: string, for display only
		subname: string or nil, for display only
		id: string, used internally to identify different characters in a same team
			within one team id must be unique
		initskill: a list of skill index filled initially
		loopskill: a list of skill index after the initskill
		skills: a list of skill table
		order: equals attack range, except for using 0 for lima
			may be fractional (to give characters with equal attack ranges strict order)
		note that characters with different skills (different stars) should have different character table
	skill table:
		name: string, for display only
		idle: true for idle skill, false otherwise (the system treat idle as a separate skill)
		action: function(battlestate, characterstate), called each frame (the first time skilldata will be nil)
			note that this function should not modify the state but returning a list of events
			the simulation system is responsible to execute them
			currently testidleskill modifies the skilldata table (remaining time), but leaves other changes to events
				probably we can use this convention for all skills
	event table:
		action: function(battlestate, characterstate) that updates the state
		maybe other fields
	buff table:
		beforeupdate: function(battlestate, characterstate, bufftable), called before skill action
		name: string, for display only
		disableupdate: if existing and is true, disables the update of current skill action
		active: if non-existing or is false, will be removed by the simulation system before the end of the frame
		currently no afterupdate function
		should avoid using tables as value (which needs deep copy)
]]

core.internal.teams = {
	{ ally = "team1", enemy = "team2", direction = 1 },
	{ ally = "team2", enemy = "team1", direction = -1 },
}

function core.internal.cloneskillidlist(list)
	if list == nil then return nil end
	local ret = {}
	for index, val in next, list do
		ret[index] = val
	end
	return ret
end

function core.internal.cloneskilldata(data)
	--simply copy each field
	--we may need more complicated method later (deep copy)
	return core.internal.cloneskillidlist(data)
end

function core.internal.clonebufftable(data)
	return core.internal.cloneskillidlist(data)
end

function core.internal.clonebufflist(list)
	if list == nil then return {} end
	local ret = {}
	for _, val in next, list do
		table.insert(ret, core.internal.clonebufftable(val))
	end
	return ret
end

function core.internal.characterstate(character, hp, tp, pos, skillid, skilldata, skilllist, bufflist)
	return {
		character = character, --table

		hp = hp, --int
		tp = tp, --int
		pos = pos, --int
		skillid = skillid, --int, 0 is no skill (simulation system will initialize the next skill in next frame)
		skilldata = skilldata, --skill-defined value (usually a table)
		skilllist = skilllist, -- a list of skills (index) that would start after the current one
		bufflist = bufflist, --a list of buff tables

		--width is currently fixed at 100
		width = character.width or 100,

		--note that atk and def can be below zero (need to check after reading)
		level = character.level or 100,
		physicalatk = character.physicalatk or 0,
		magicatk = character.magicatk or 0,
		physicaldef = character.physicaldef or 0,
		magicdef = character.magicdef or 0,
		accuracy = character.accuracy or 0,
		dodge = character.dodge or 0,
		physicalcritical = character.physicalcritical or 0,
		magiccritical = character.magiccritical or 0,
		--TODO other parameters (also update clone function)

		--fields that are not initialized:
		--readytime (time at which the character finished its entering skill)
		--checkrange (step length of the last movement, usually 12 or 7.5)
		acceleration = 1.0, --stored at the beginning of a skill, affecting next cast time

		--do not write team (we don't know)
		--it's handled by battle state instead

		clone = function(s)
			local ret = core.internal.characterstate(s.character,
				s.hp, s.tp, s.pos, s.skillid,
				core.internal.cloneskilldata(s.skilldata),
				core.internal.cloneskillidlist(s.skilllist),
				core.internal.clonebufflist(s.bufflist))

			ret.level = s.level
			ret.physicalatk = s.physicalatk
			ret.magicatk = s.magicatk
			ret.physicaldef = s.physicaldef
			ret.magicdef = s.magicdef
			ret.accuracy = s.accuracy
			ret.dodge = s.dodge
			ret.physicalcritical = s.physicalcritical
			ret.magiccritical = s.magiccritical

			ret.readytime = s.readytime
			ret.checkrange = s.checkrange
			ret.acceleration = s.acceleration
			return ret
		end
	}
end

function core.internal.cloneteam(team)
	local newteam = {}
	for index, ch in next, team do
		newteam[index] = ch:clone()
	end
	return newteam
end

function core.internal.battlestate(time, team1, team2)
	--set labels to help find allies/enemies
	for _, ch in next, team1 do
		ch.team = core.internal.teams[1]
	end
	for _, ch in next, team2 do
		ch.team = core.internal.teams[2]
	end

	return {
		time = time, --int, frame index starting from 0, pvp timer starts (changing from 1:30 to 1:29) at time = 60
		team1 = team1, --a list of characters
		team2 = team2, --a list of characters

		clone = function(s)
			local ret = core.internal.battlestate(s.time,
				core.internal.cloneteam(s.team1), core.internal.cloneteam(s.team2))
			ret.randomseed = s.randomseed
			return ret
		end,
		clocktime = function(state, format)
			if format == nil then format = "m:s" end
			local m, s, ss, f
			if state.time < 60 then
				m = 1
				s = 30
				ss = 90
				f = 0
			else
				local actualframe = state.time - 60
				local xss = math.floor(actualframe / 60)
				f = actualframe - xss * 60
				ss = 89 - xss

				m = math.floor(ss / 60)
				s = ss - m * 60
			end
			m = string.format("%02d", m)
			s = string.format("%02d", s)
			ss = string.format("%02d", ss)
			f = string.format("%02d", f)
			local ret = format:gsub("m", m):gsub("ss", ss):gsub("s", s):gsub("f", f)
			return ret
		end,
		findcharacter = function(state, teamname, id)
			for _, ch in next, state[teamname] do
				if ch.character.id == id then return ch end
			end
		end,
	}
end

function core.internal.frame(parent, options, state, eventlist)
	return {
		parent = parent, --another frame table
		options = options, --not supported yet
		state = state, --battle state table
		eventlist = eventlist, --a list of events (containing function applied to the last battle state)
	}
end

--state: a table (battlestate table is used in simulation)
function core.internal.randf(state)
	if not state.randomseed then
		--use math.random to initialize the seed
		state.randomseed = math.random(10000)
	end
	state.randomseed = (state.randomseed * 1103515245 + 12345) & ((1 << 31) - 1)
	return ((state.randomseed >> 5) & 65535) / 65536
end

core.simulation = {}
core.simulation.internal = {}

function core.simulation.firstframe(s)
	--sort characters
	table.sort(s.team1, function(ch1, ch2) return ch1.character.order < ch2.character.order end)
	table.sort(s.team2, function(ch1, ch2) return ch1.character.order < ch2.character.order end)
	--TODO need confirmation: according to Xier, lima in team2 is updated before team1

	--set initial position
	for index, ch in next, s.team1 do
		ch.pos = -660 - 200 * (index - 1)
	end
	for index, ch in next, s.team2 do
		ch.pos = 660 + 200 * (index - 1)
	end

	--set initial skills
	for _, ch in next, s.team1 do
		ch.skillid = 0
		ch.skilllist = core.internal.cloneskillidlist(ch.character.initskill)
	end
	for _, ch in next, s.team2 do
		ch.skillid = 0
		ch.skilllist = core.internal.cloneskillidlist(ch.character.initskill)
	end

	return core.internal.frame(nil, nil, s, {})
end

function core.simulation.internal.updatecharacter(character, battle)
	local ret = {}

	if character.skillid == 0 then
		--start next skill
		if #character.skilllist == 0 then
			character.skilllist = core.internal.cloneskillidlist(character.character.loopskill)
		end
		character.skillid = table.remove(character.skilllist, 1)
		character.skilldata = nil

		table.insert(ret, {
			name = "skillstart",
			skillid = character.skillid
		})
	end
	local skill = character.character.skills[character.skillid]

	local noskillupdate = false

	--before calling skill action, check buff actions first
	local index = 1
	while index <= #character.bufflist do
		local buff = character.bufflist[index]

		--call beforeupdate function
		local buffevents = buff.beforeupdate(battle, character, buff)
		if #buffevents > 0 then
			for _, ee in next, buffevents do table.insert(ret, ee) end
		end

		if buff.disableupdate then noskillupdate = true end
		if not buff.active then
			table.remove(character.bufflist, index)
			index = index - 1
		end

		index = index + 1
	end

	--skill
	if not noskillupdate then
		local skillevents = skill.action(battle, character) --call skill action function
		for _, ee in next, skillevents do table.insert(ret, ee) end
	end

	return ret
end

function core.simulation.internal.updatestate(s)
	local updateteam = function(team, battle, results, teamname)
		--remove dead characters
		--TODO is it before or after? 2 teams together or separate? or maybe as soon as damage is applied?
		--if it's as soon as damage is applied, we need to be careful about the iteration
		local i = 1
		while i <= #team do
			if team[i].hp == 0 then
				table.remove(team, i)
			else
				i = i + 1
			end
		end

		--get a list of events and merge them to results
		for _, character in next, team do
			local newresults = core.simulation.internal.updatecharacter(character, battle)
			for _, newevent in next, newresults do
				if newevent.action then
					newevent.action(battle, character) --execute immediately
				end
				newevent.character = character.character.id
				newevent.team = teamname
				table.insert(results, newevent)
			end
		end
	end

	local r = {}
	updateteam(s.team1, s, r, "team1")
	updateteam(s.team2, s, r, "team2")
	--according to Xier, Lima is updated separately, but currently I have no evidence

	return r
end

function core.simulation.next(frame, options)
	local nextstate = frame.state:clone()
	nextstate.time = nextstate.time + 1
	local events = core.simulation.internal.updatestate(nextstate)
	local nextframe = core.internal.frame(frame, options, nextstate, events)
	if options then
		options(nextframe)
	end
	return nextframe
end

function core.simulation.run(frame, options, count)
	if type(options) == "table" then
		--allow using table (array) to merge several handlers
		options = function(f)
			for _, item in next, options do
				item(f)
			end
		end
	end
	if options ~= nil and type(options) ~= "function" then
		print("invalid simulation handler")
		options = nil
	end

	local result = frame
	for i = 1, count do
		result = core.simulation.next(result, options)
	end
	return result
end

return core
