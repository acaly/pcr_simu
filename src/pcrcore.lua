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

function core.internal.clonebufflist(data)
	--simply copy each field
	--we may need more complicated method later (deep copy)
	return core.internal.cloneskillidlist(data)
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
		bufflist = bufflist, --not supported yet
		--TODO other parameters (atk, def, etc.)

		--fields that are not initialized:
		--readytime (time at which the character finished its entering skill)
		--checkrange (step length of the last movement, usually 12 or 7.5)

		--do not write team (we don't know)
		--it's handled by battle state instead

		clone = function(s)
			local ret = core.internal.characterstate(s.character,
				s.hp, s.tp, s.pos, s.skillid,
				core.internal.cloneskilldata(s.skilldata),
				core.internal.cloneskillidlist(s.skilllist),
				core.internal.clonebufflist(s.bufflist))
			ret.readytime = s.readytime
			ret.checkrange = s.checkrange
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
			return core.internal.battlestate(s.time,
				core.internal.cloneteam(s.team1), core.internal.cloneteam(s.team2))
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
			local ret = format:gsub("m", m):gsub("ss", ss):gsub("s", s):gsub("f", f)
			return ret
		end,
		--TODO find player in team by id
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

core.simulation = {}

function core.simulation.firstframe(s)
	--sort characters
	table.sort(s.team1, function(ch1, ch2) return ch1.character.order > ch2.character.order end) --big to small
	table.sort(s.team2, function(ch1, ch2) return ch1.character.order < ch2.character.order end) --small to big
	--TODO need confirmation: according to Xier, team1 should also sort from small to big

	--set initial position
	for index, ch in next, s.team1 do
		ch.pos = -660 - 200 * (#s.team1 - index)
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

function core.simulation.makeevents(s) --TODO need options parameter
	local updatecharacter = function(character, battle)
		if character.skillid == 0 then
			--start next skill
			if #character.skilllist == 0 then
				character.skilllist = core.internal.cloneskillidlist(character.character.loopskill)
			end
			character.skillid = table.remove(character.skilllist, 1)
			character.skilldata = nil
		end
		local skill = character.character.skills[character.skillid]
		return skill.action(battle, character) --call skill action function
	end
	local updateteam = function(team, battle, results)
		--remove dead characters (TODO is it before or after? 2 teams together or separate? or maybe as soon as damage is applied?)
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
			local newresults = updatecharacter(character, battle)
			for _, newevent in next, newresults do
				newevent.action(battle, character) --execute immediately
				table.insert(results, newevent)
			end
		end
	end

	local r = {}
	updateteam(s.team1, s, r)
	updateteam(s.team2, s, r)
	--according to Xier, Lima is updated separately, but currently I have no evidence

	return r
end

function core.simulation.next(frame, options)
	local nextstate = frame.state:clone()
	nextstate.time = nextstate.time + 1
	local events = core.simulation.makeevents(nextstate)
	return core.internal.frame(frame, options, nextstate, events)
end

function core.simulation.run(frame, options, count)
	local result = frame
	for i = 1, count do
		result = core.simulation.next(result, options)
	end
	return result
end

return core
