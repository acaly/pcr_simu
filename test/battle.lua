pcr=require("env")
math.randomseed(os.time())

--some random numbers...
miyako = pcr.characters.miyako.default()
miyako.physicalatk = 3000
miyako.physicaldef = 300
miyako.dodge = 50
makoto = pcr.characters.makoto.default()
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
      local target = f.state:findcharacter(ee.targetteam, ee.targetid)
      print(f.state:clocktime("m:s+f") .. "  " .. target.character.id .. "  hp = " .. target.hp)
    end
  end
end

frame0 = pcr.utils.makebattle({ miyako }, { makoto })
pcr.core.simulation.run(frame0, h, 3000)
