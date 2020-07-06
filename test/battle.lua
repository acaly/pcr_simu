pcr=require("env")
math.randomseed(os.time())

--some random numbers...
miyako = pcr.characters.miyako.default()
miyako.level = 93
miyako.maxhp = 20000
miyako.physicalatk = 3000
miyako.physicaldef = 300
miyako.dodge = 50
makoto = pcr.characters.makoto.default()
makoto.level = 93
makoto.maxhp = 10000
makoto.physicalatk = 6000
makoto.physicaldef = 150

h = function(f)
	for _, ee in next, f.eventlist do
		if ee.name == "skillstart" then
			local skill = f.state:findcharacter(ee.team, ee.character).character.skills[ee.skillid]
			if not skill.idle then
				--print(f.state:clocktime("m:s+f") .. "  " .. ee.character .. "  " .. skill.name)
			end
		elseif ee.name == "damage" then
			local src = f.state:findcharacter(ee.sourceteam, ee.sourceid)
			local target = f.state:findcharacter(ee.targetteam, ee.targetid)
			local hp = math.floor(target.hp)
			if target then
				if ee.invinsible then
					print(f.state:clocktime("m:s+f") .. "  attack  " .. src.character.id .. "->" .. target.character.id ..
						"  hp = " .. hp .. "(invinsible)")
				elseif ee.miss then
					print(f.state:clocktime("m:s+f") .. "  attack  " .. src.character.id .. "->" .. target.character.id ..
						"  hp = " .. hp .. "(miss)")
				else
					print(f.state:clocktime("m:s+f") .. "  attack  " .. src.character.id .. "->" .. target.character.id ..
						"  hp = " .. hp .. "(-" .. math.floor(ee.damage) .. ")")
				end
			end
		elseif ee.name == "heal" then
			local src = f.state:findcharacter(ee.sourceteam, ee.sourceid)
			local target = f.state:findcharacter(ee.targetteam, ee.targetid)
			local hp = math.floor(target.hp)
			print(f.state:clocktime("m:s+f") .. "  heal    " .. src.character.id .. "->" .. target.character.id .. "  hp = " .. hp .. "(+" .. math.floor(ee.heal) .. ")")
		end
	end
end

frame0 = pcr.utils.makebattle({ miyako }, { makoto })
pcr.core.simulation.run(frame0, h, 3000)
