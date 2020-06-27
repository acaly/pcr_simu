local pcr = {}

pcr.internal = {}

--[[
    character table:
        name: string, for display only
        initskill: a function returning a list of skill index filled initially
        loopskill: a function returning a list of skill index after the initskill
        skills: a list of skill table
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

pcr.internal.teams = {
    { ally = "team1", enemy = "team2", direction = 1 },
    { ally = "team2", enemy = "team1", direction = -1 },
}

function pcr.internal.characterstate(character, hp, tp, pos, skillid, skilldata, skilllist, bufflist)
    return {
        character = character, --table
        hp = hp, --int
        tp = tp, --int
        pos = pos, --int
        skillid = skillid, --int, 0 is no skill (simulation system will initialize the next skill in next frame)
        skilldata = skilldata, --skill-defined value (usually a table)
        skilllist = skilllist, -- a list of skills (index) that would start after the current one
        bufflist = bufflist, --not supported yet
        clone = function(s)
            return pcr.internal.characterstate(s.character, s.hp, s.tp, s.pos, s.skillid, s.skilldata, s.bufflist);
        end
	}
end

function pcr.internal.cloneteam(team)
    local newteam = {}
    for index, ch in next, team do
        newteam[index] = ch:clone()
    end
    return newteam
end

function pcr.internal.battlestate(time, team1, team2)
    --set labels to help find allies/enemies
    for index, ch in next, team1 do
        ch.team = pcr.internal.teams[1]
    end
    for index, ch in next, team2 do
        ch.team = pcr.internal.teams[2]
    end

    return {
        time = time, --int, frame index starting from 0
        team1 = team1, --a list of characters
        team2 = team2, --a list of characters
        clone = function(s)
            return pcr.internal.battlestate(s.time,
                pcr.internal.cloneteam(s.team1), pcr.internal.cloneteam(s.team2))
        end
	}
end

function pcr.internal.frame(parent, options, state, eventlist)
    return {
        parent = parent, --another frame table
        options = options, --not supported yet
        state = state, --battle state table
        eventlist = eventlist, --a list of events (function that applied to the last battle state)
	}
end

pcr.simulation = {}

function pcr.simulation.firstframe(s)
    return pcr.internal.frame(nil, nil, s, {})
end

function pcr.simulation.makeevents(s) --TODO need options parameter
    local updatecharacter = function(character, battle)
        if character.skillid == 0 then
            --start next skill
            if #character.skilllist == 0 then
                character.skilllist = character.character.loopskill()
            end
            character.skillid = table.remove(character.skilllist, 1)
            character.skilldata = nil
        end
        local skill = character.character.skills[character.skillid]
        return skill.action(battle, character) --call skill action function
    end
    local updateteam = function(team, battle, results)
        --remove dead characters (TODO is it before or after? 2 teams together or separate?)
        local i = 1
        while i <= #team do
            if team[i].hp == 0 then
                table.remove(team, i)
            else
                i = i + 1
            end
        end

        --get a list of events and merge them to results
        for index, character in next, team do
            local newresults = updatecharacter(character, battle)
            for index, newevent in next, newresults do
                newevent.action(battle, character) --execute immediately
                table.insert(results, newevent)
            end
        end
    end
    local r = {}
    updateteam(s.team1, s, r)
    updateteam(s.team2, s, r)
    return r
end

function pcr.simulation.next(frame, options)
    local nextstate = frame.state:clone()
    nextstate.time = nextstate.time + 1
    local events = pcr.simulation.makeevents(nextstate)
    return pcr.internal.frame(frame, options, nextstate, events)
end

function pcr.simulation.run(frame, options, count)
    local result = frame
    for i = 1, count do
        result = pcr.simulation.next(result, options)
    end
    return result
end

pcr.test = {}

--implementation of idle skill

function pcr.test.testidleskill_move(battle, character)
    character.pos = character.pos + character.team.direction * 7.5
end

function pcr.test.testidleskill(idletime, attackrange)
    return function(battle, character)
        if character.skilldata == nil then
            --init skill data
            character.skilldata = {
                remaining = idletime,
			}
        end

        --TODO temporary code: find nearest enemy's distance
        --need to move to a shared helper function
        local nearestdist = -1
        local enemylist = battle[character.team.enemy]
        for index, enemy in next, enemylist do
            local dd = math.abs(enemy.pos - character.pos)
            if nearestdist < 0 or dd < nearestdist then nearestdist = dd end
        end

        if nearestdist > attackrange + 125 then
            --need to move
            --TODO Lima can stand within enemies
            --how will this affect move direction?
            return {
                { action = pcr.test.testidleskill_move }
            }
        else
            character.skilldata.remaining = character.skilldata.remaining - 1
            if character.skilldata.remaining == 0 then
                character.skillid = 0 --end current skill
            end
            return {}
        end
    end
end

--a simple test

function pcr.test.makeemptycharacter(name, attackrange)
    return {
        name = name,
        initskill = function() return { 1 } end,
        loopskill = function() return { 1 } end,
        skills = {
            [1] = {
                name = "idle",
                idle = true,
                action = pcr.test.testidleskill(60 * 90, attackrange), --idle for 90 seconds
			}
		}
	}
end

local miyako = pcr.test.makeemptycharacter("miyako", 125)
local kuka = pcr.test.makeemptycharacter("kuka", 130)
local jun = pcr.test.makeemptycharacter("jun", 135)
local nozomi = pcr.test.makeemptycharacter("nozomi", 160)
local tamaki = pcr.test.makeemptycharacter("tamaki", 215)
local makoto = pcr.test.makeemptycharacter("makoto", 165)
local suzuna = pcr.test.makeemptycharacter("suzuna", 705)
local maho = pcr.test.makeemptycharacter("maho", 795)

function pcr.test.characterstate(character, pos)
    return pcr.internal.characterstate(character, 10000, 0, pos, 0, nil, {}, {})
end

function pcr.test.battlestate()
    return pcr.internal.battlestate(0,
        {
            pcr.test.characterstate(miyako, -1080),
            pcr.test.characterstate(kuka,   -1080 - 200 * 1),
            pcr.test.characterstate(jun,    -1080 - 200 * 2),
            pcr.test.characterstate(nozomi, -1080 - 200 * 3),
            pcr.test.characterstate(tamaki, -1080 - 200 * 4),
        },
        {
            pcr.test.characterstate(jun,    1080),
            pcr.test.characterstate(makoto, 1080 + 200 * 1),
            pcr.test.characterstate(tamaki, 1080 + 200 * 2),
            pcr.test.characterstate(suzuna, 1080 + 200 * 3),
            pcr.test.characterstate(maho,   1080 + 200 * 4),
        })
end

return pcr
