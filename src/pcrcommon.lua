local core = require("pcrcore")
local common = {}

common.utils = {}

--common script

--TODO be careful when using this in skills
--range check in skills might allow equal distance
function common.utils.anyenemyinrange(character, battle, totaldistance)
	for _, ee in next, battle[character.team.enemy] do
		--TODO exclude dead characters?
		if math.abs(ee.pos - character.pos) < totaldistance + ee.width then
			return true
		end
	end
	return false
end

function common.utils.setupacceleration(character)
	character.acceleration = 1.0
end

function common.utils.checkbuffbyname(character, name)
	for _, buff in next, character.bufflist do
		if buff.name == name then
			return true
		end
	end
end

function common.utils.selectprovoking(character, team, skillrange)
	local actualrange = skillrange + character.checkrange
	for _, ee in next, team do
		--allow equal
		--TODO confirm this
		if math.abs(character.pos - ee.pos) <= actualrange + ee.width then
			if common.utils.checkbuffbyname(ee, "provoking") then
				--assuming there is only one with this buff
				return ee
			end
		end
	end
	return nil
end

--quick sort
--normal order is 54321(not same team), inversedinitialorder is 12345 (same team)
--TODO both orders have not been confirmed yet
--note that this returns the most possible character, which might not be with the specified index
--(if distance is not enough)
function common.utils.qsort(team, selectfunction, selectindex, inversedinitialorder)
	local storage = {}
	if inversedinitialorder then
		for _, ch in next, team do
			local val = selectfunction(ch)
			if val then table.insert(storage, { character = ch, value = val }) end
		end
	else
		local index = #team
		while index >= 1 do
			local ch = team[index]
			local val = selectfunction(ch)
			if val then table.insert(storage, { character = ch, value = val }) end
			index = index - 1
		end
	end
	if #storage == 0 then return nil end

	local function iteration(left, right)
		if left >= right then return end

		local scanleft = left
		local scanright = right
		local pivotval = storage[math.floor((left + right) / 2) + 1].value

		while true do
			while scanleft < right and storage[scanleft + 1].value < pivotval do
				scanleft = scanleft + 1
			end
			while scanright > left and storage[scanright + 1].value > pivotval do
				scanright = scanright - 1
			end
			if scanleft > scanright then break end

			local exchange = storage[scanleft + 1]
			storage[scanleft + 1] = storage[scanright + 1]
			storage[scanright + 1] = exchange

			scanleft = scanleft + 1
			scanright = scanright - 1
		end

		if left < scanright then
			iteration(left, scanright)
		end
		if scanleft < right then
			iteration(scanleft, right)
		end
	end

	iteration(0, #storage - 1)

	if selectindex > #storage then selectindex = #storage end
	if selectindex < 0 then selectindex = #storage - selectindex + 1 end
	return storage[selectindex].character
end

function common.utils.selectfunctiondistance(character, maxdistanceinclusive)
	return function(ch)
		local distance = math.abs(ch.pos - character.pos)
		--simply ignore characters out of range (should work)
		if distance > maxdistanceinclusive + ch.width then return nil end
		return distance
	end
end

--index=1: nearest, index=2: second nearest, etc.
--index=-1: farthest
function common.utils.selectnearestenemy(character, team, skillrange, ignoreprovocation, index)
	if not ignoreprovocation then
		local p = common.utils.selectprovoking(character, team, skillrange)
		if p then return p end
	end
	return common.utils.qsort(team,
		common.utils.selectfunctiondistance(character, skillrange + character.checkrange), index or 1)
end

--skill events
common.events = {}

--type=1: physical, type=2: magic
function common.events.damage(source, target, basedamage, type, count, criticalratio)
	local eventtable = {
		name = "damage",
		sourceteam = source.team.ally,
		sourceid = source.character.id,
		targetteam = target.team.ally,
		targetid = target.character.id,
	}
	function eventtable.action(battle, character)
		--we are not recalculating target and source character from the given battle state
		--this should work as long as the simulator always clone a new battle state and execute skill actions there

		local hitprob = 1
		if type == 1 then
			hitprob = 100 / (100 + target.dodge - source.accuracy)
			if hitprob > 1 then hitprob = 1 end
			--TODO dark debuff
		end
		eventtable.miss = core.internal.randf(battle) >= hitprob
		--TODO ensured dodging (miyako)
		--TODO invinsible

		if eventtable.miss then
			eventtable.critical = false
			eventtable.damage = 0
			return
		end

		local critical = 0.05 * 0.01 * source.level / target.level
		if type == 1 then
			critical = critical * source.physicalcritical
		elseif type == 2 then
			critical = critical * source.magiccritical
		end
		eventtable.critical = core.internal.randf(battle) < critical

		local def
		if type == 1 then
			def = target.physicaldef
		elseif type == 2 then
			def = target.magicdef
		end
		local realdamage = basedamage / (1 + math.max(def, 0) / 100)
		if eventtable.critical then
			realdamage = realdamage * (criticalratio or 2)
		end
		--TODO rounding? (according to Xier, TP is not rounded, maybe same for damage?)
		--TODO random damage fluctuation?
		realdamage = realdamage * (count or 1)

		eventtable.damage = realdamage

		if target.hp > realdamage then
			target.hp = target.hp - realdamage
		else
			target.hp = 0
		end
		--TODO hp steal (physical & magic separately?)
		--TODO tp recovery due to damage
		--TODO tp recovery due to killing
	end
	return eventtable
end

--startfunction and finishfunction: function(battle, character, bufftable)
--note that buff starts from the next frame, so be careful about the timing when applying buffs
function common.events.buff(character, name, totalframes, startfunction, finishfunction)
	local eventtable = {
		name = "buff",
		time = totalframes,
		targetteam = character.team.ally,
		targetid = character.character.id,
	}
	function eventtable.action(_, _)
		local bufftable = {
			name = name,
			active = true,
			totalframes = totalframes,
			frames = 0,
		}
		function bufftable.beforeupdate(battle1, character1, bufftable1)
			if bufftable1.frames == 0 then
				startfunction(battle1, character1, bufftable1)
			end
			bufftable1.frames = bufftable1.frames + 1
			if bufftable1.frames == totalframes then
				finishfunction(battle1, character1, bufftable1)
				bufftable1.active = false
			end
		end
		table.insert(character.bufflist, bufftable)
	end
	return eventtable
end

--event generators (used in generic skill)

common.eventgenerators = {}

function common.eventgenerators.damagenearest(type, index)
	return function(battle, character, results)
		local target = common.utils.selectnearestenemy(character, battle[character.team.enemy], character.character.attackrange, false, index)
		local damage
		if type == 1 then
			damage = character.physicalatk
		elseif type == 2 then
			damage = character.magicatk
		end
		table.insert(results, common.events.damage(character, target, damage, type))
	end
end

function common.eventgenerators.buffself(name, totalframes, startfunction, finishfunction)
	return function(battle, character, results)
		table.insert(results, common.events.buff(character, name, totalframes, startfunction, finishfunction))
	end
end

--TODO we need a generator to provide startfunction and finishfunction automatically
--separate buff type, buff strength and generator
--improve buffself

--implementation of empty skill (doing nothing, for testing only)

function common.emptyskill(totalframes)
	return function(battle, character)
		--init skill data
		if character.skilldata == nil then
			character.skilldata = {
				remaining = totalframes,
			}

			--set up acceleration
			--we know the acceleration buff at the beginning of one skill will
			--affect the cast time of next skill, but we don't have tests with
			--the accuracy of 1 frame
			--TODO maybe we should do more tests

			common.utils.setupacceleration(character)
		end

		--update counter
		character.skilldata.remaining = character.skilldata.remaining - 1
		if character.skilldata.remaining == 0 then
			character.skillid = 0 --end current skill
		end

		--no event
		return {}
	end
end

--implementation of idle skill (also used when starting the battle)

function common.idleskill(idletime, velocity)
	return function(battle, character)
		--init skill data
		if character.skilldata == nil then
			local totalframes = 1 + math.floor(character.acceleration * idletime * 60)

			character.skilldata = {
				remaining = totalframes,
				ismoving = false,
			}
		end

		if not character.skilldata.ismoving then
			--only check for starting
			--don't move in this frame
			--TODO need to match frame delay when enemy is killed (between hp -> 0 and ismoving -> true)

			--start check (with extension of last move)
			local checkrange = character.checkrange or 0
			local findenemy = common.utils.anyenemyinrange(character, battle,
				character.character.attackrange + checkrange)

			--set up moving state
			if not findenemy then
				character.skilldata.ismoving = true
				character.checkrange = velocity
			end
			
			--decrement counter
			character.skilldata.remaining = character.skilldata.remaining - 1
			if character.skilldata.remaining == 0 then
				character.skillid = 0 --end current skill
			end

			return {}
		else
			--first check (no extension)
			local firstcheck = common.utils.anyenemyinrange(character, battle,
				character.character.attackrange)
			
			if firstcheck then
				--don't need to move
				--set up stopped state
				character.skilldata.ismoving = false
				character.readytime = character.readytime or battle.time

				--decrement counter
				character.skilldata.remaining = character.skilldata.remaining - 1
				if character.skilldata.remaining == 0 then
					character.skillid = 0 --end current skill
				end

				return {}
			else
				--move
				--TODO we need movestart and movefinish events
				local moveevent = 
				{
					name = "step",
					velocity = velocity,
					action = function(battle1, character1)
						character1.pos = character1.pos + character1.team.direction * velocity

						--second check (with extension)
						local secondcheck = common.utils.anyenemyinrange(character1, battle1,
							character1.character.attackrange + character1.checkrange)

						if secondcheck then
							--we should stop here
							character1.skilldata.ismoving = false
							character1.readytime = character1.readytime or battle.time
						end
					end,
				}
				return { moveevent }
			end
		end
	end
end

function common.enterskill()
	return common.idleskill(2.5, 12)
end

function common.waitskill(totaltime)
	return common.idleskill(totaltime, 7.5)
end

--generic skill (as a template for most skills)

--eventgenerators: { time(frame) -> generator function or list of generator functions }
function common.genericskill(totalframes, eventgenerators)
	return function(battle, character)
		--init skill data
		if character.skilldata == nil then
			character.skilldata = {
				count = 0,
			}

			--set up acceleration
			--we know the acceleration buff at the beginning of one skill will
			--affect the cast time of next skill, but we don't have tests with
			--the accuracy of 1 frame
			--TODO maybe we should do more tests

			common.utils.setupacceleration(character)
		end

		local ret = {}

		local g = eventgenerators[character.skilldata.count]
		if g then
			if type(g) == "function" then
				g(battle, character, ret)
			elseif type(g) == "table" then
				for _, func in next, g do
					func(battle, character, ret)
				end
			end
		end

		--update counter
		character.skilldata.count = character.skilldata.count + 1
		if character.skilldata.count == totalframes then
			character.skillid = 0 --end current skill
		end

		return ret
	end
end

--simple attack skill
function common.attackskill(totalframes, attackframe, type)
	return common.genericskill(totalframes, { [attackframe] = common.eventgenerators.damagenearest(type, 1) })
end

--empty characters

function common.utils.concatname(name, subname)
	if subname == nil then
		return name
	else
		return name .. "_" .. subname
	end
end

function common.makeemptycharacter(name, attackrange, subname)
	return {
		name = name,
		subname = subname,
		id = common.utils.concatname(name, subname),

		attackrange = attackrange,
		order = attackrange,

		skills = {
			[1] = {
				name = "enter",
				idle = true,
				action = common.enterskill(),
			},
			[2] = {
				name = "empty",
				idle = false,
				action = common.emptyskill(60 * 90), --90 seconds
			}
		},
		initskill = { 1 },
		loopskill = { 2 },
	}
end

function common.makeemptycharacter_lima(name, attackrange, subname)
	return {
		name = name,
		subname = subname,
		id = common.utils.concatname(name, subname),

		attackrange = attackrange,
		order = attackrange,

		skills = {
			[1] = {
				name = "wait",
				idle = false,
				action = common.emptyskill(200), --wait for 200 ticks
			},
			[2] = {
				name = "empty",
				idle = false,
				action = common.emptyskill(60 * 90), --90 seconds
			}
		},
		initskill = { 1 },
		loopskill = { 2 },
	}
end

common.emptycharacters =
{
	lima_only = common.makeemptycharacter("lima", 105),
	lima = common.makeemptycharacter_lima("lima", 105),

	miyako = common.makeemptycharacter("miyako", 125),
	kuuka = common.makeemptycharacter("kuuka", 130),
	jun = common.makeemptycharacter("jun", 135),
	kaori = common.makeemptycharacter("kaori", 145),
	peko = common.makeemptycharacter("peko", 155),
	kokkoro_spring = common.makeemptycharacter("kokkoro", 159, "spring"),
	nozomi = common.makeemptycharacter("nozomi", 160),
	makoto = common.makeemptycharacter("makoto", 165),
	tsumugi = common.makeemptycharacter("tsumugi", 195),
	hiyori = common.makeemptycharacter("hiyori", 200),
	misogi = common.makeemptycharacter("misogi", 205),
	tamaki = common.makeemptycharacter("tamaki", 215),
	eriko = common.makeemptycharacter("eriko", 230),
	djeeta = common.makeemptycharacter("djeeta", 245),
	rei = common.makeemptycharacter("rei", 250),
	yukari = common.makeemptycharacter("yukari", 405),
	monika = common.makeemptycharacter("monika", 410),
	nino = common.makeemptycharacter("nino", 415),
	mifuyu = common.makeemptycharacter("mifuyu", 420),
	illya = common.makeemptycharacter("illya", 425),
	saren = common.makeemptycharacter("saren", 430),
	anna = common.makeemptycharacter("anna", 440),
	kokkoro = common.makeemptycharacter("kokkoro", 500),
	rin = common.makeemptycharacter("rin", 550),
	saren_summer = common.makeemptycharacter("saren", 585, "summer"),
	miyako_halloween = common.makeemptycharacter("miyako", 590, "halloween"),
	mitsuki = common.makeemptycharacter("mitsuki", 565),
	rino = common.makeemptycharacter("rino", 700),
	suzuna = common.makeemptycharacter("suzuna", 705),
	io = common.makeemptycharacter("io", 715),
	karyl = common.makeemptycharacter("karyl", 750),
	hatsune = common.makeemptycharacter("hatsune", 755),
	misaki = common.makeemptycharacter("misaki", 760),
	maho = common.makeemptycharacter("maho", 795),
	chika_christmas = common.makeemptycharacter("chika", 770, "christmas"),
	yuki = common.makeemptycharacter("yuki", 805),
	kyouka = common.makeemptycharacter("kyouka", 810),
}

return common
