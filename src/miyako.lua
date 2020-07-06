local common = require("pcrcommon")

local miyako = {}

local function create(skill1level, skill2level)
	local invinsibleframes = 180 + math.floor(skill1level * 0.01 * 60)
	return {
		name = "miyako",
		subname = nil,
		id = "miyako",

		attackrange = 125,
		order = 125,

		maxhp = 1000,
		
		skills = {
			[1] = {
				name = "enter",
				idle = true,
				action = common.enterskill(),
			},
			[2] = {
				name = "wait_attack",
				idle = true,
				action = common.waitskill(1.7),
			},
			[3] = {
				name = "attack",
				idle = false,
				action = common.attackskill(93, 27, 1),
			},
			[4] = {
				name = "wait_skill1",
				idle = true,
				action = common.waitskill(0),
			},
			[5] = {
				name = "skill1",
				idle = false,
				action = common.genericskill(30 + invinsibleframes + 28, {
					[30] = {
						pcr.common.eventgenerators.selectself(),
						pcr.common.eventgenerators.bufftargetsname(invinsibleframes, "invinsible"),
						pcr.common.eventgenerators.bufftargetsname(invinsibleframes, "ensureddodging"),
					},
				}),
			},
			[6] = {
				name = "wait_skill2",
				idle = true,
				action = common.waitskill(0.27),
			},
			[7] = {
				name = "skill2",
				idle = false,
				action = common.genericskill(189, {
					[30] = {
						pcr.common.eventgenerators.selectself(),
						pcr.common.eventgenerators.healtargets(1, 7.5 + 7.5 * skill2level, 1),
					},
				}),
			},
		},
		initskill = { 1, 3, 2, 3, 4, 5, 2, 3, 6, 7 },
		loopskill = { 2, 3, 2, 3, 4, 5, 6, 7 },
	}
end

function miyako.default()
	return create(93, 93)
end

return miyako
