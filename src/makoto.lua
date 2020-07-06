local common = require("pcrcommon")

local makoto = {}

local function create(skill1level, skill2level)
	return {
		name = "makoto",
		subname = nil,
		id = "makoto",

		attackrange = 165,
		order = 165,

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
				action = common.waitskill(2.125),
			},
			[3] = {
				name = "attack",
				idle = false,
				action = common.attackskill(69, 30, 1),
			},
			[4] = {
				name = "wait_skill1",
				idle = true,
				action = common.waitskill(1.125),
			},
			[5] = {
				name = "skill1",
				idle = false,
				action = common.genericskill(121, {
					[33] = {
						common.eventgenerators.selectnearestenemy(nil, 1),
						common.eventgenerators.damagetargets(1, 20 + 20 * skill1level, 1.6)
					},
				}),
			},
			[6] = {
				name = "wait_skill2",
				idle = true,
				action = common.waitskill(1.895),
			},
			[7] = {
				name = "skill2",
				idle = false,
				action = common.genericskill(75, {
					[48] = {
						common.eventgenerators.selectnearestenemy(nil, 1),
						common.eventgenerators.bufftargetspropertyfixed(720, "physicaldefdown", "physicaldef", 0.8 + 0.8 * skill2level)
					},
				}),
			},
		},
		initskill = { 1, 7, 4, 5 },
		loopskill = { 2, 3, 2, 3, 6, 7, 2, 3, 4, 5 },
	}
end

function makoto.default()
	return create(93, 93)
end

return makoto
