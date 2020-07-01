local common = require("pcrcommon")

local makoto = {}

--TODO
--wait time (before skills) should -1 or -2 (129/115/69 -> 128/114/68 or 127/113/67)
--can't decide by acceleration
--need to confirm with auto UB
local function create()
	local attackrange = 165 --TODO move attackrange to character table
	return {
		name = "makoto",
		subname = nil,
		id = "makoto",
		skills = {
			[1] = {
				name = "enter",
				idle = true,
				action = common.idleskill(37, attackrange, 12, true),
			},
			[2] = {
				name = "wait_attack",
				idle = true,
				action = common.waitskill(128, attackrange),
			},
			[3] = {
				name = "attack",
				idle = false,
				action = common.emptyskill(69),
			},
			[4] = {
				name = "wait_skill1+",
				idle = true,
				action = common.waitskill(68, attackrange),
			},
			[5] = {
				name = "skill1+",
				idle = false,
				action = common.emptyskill(121),
			},
			[6] = {
				name = "wait_skill2",
				idle = true,
				action = common.waitskill(114, attackrange),
			},
			[7] = {
				name = "skill2",
				idle = false,
				action = common.emptyskill(75),
			},
		},
		initskill = function() return { 1, 6, 7, 4, 5 } end,
		loopskill = function() return { 2, 3, 2, 3, 6, 7, 2, 3, 4, 5 } end,
		order = attackrange,
	}
end

function makoto.default()
	return create()
end

return makoto
