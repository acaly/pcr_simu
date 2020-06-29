local printpos = {}

local width = function(str, w)
	local ret = str
	while #ret < w do
		ret = ret .. " "
	end
	return ret
end

local getremaining = function(ch)
	local ret = nil
	if ch.skilldata ~= nil then
		ret = ch.skilldata.remaining
	end
	if ret == nil then return "nil" end
	return ret
end

function printpos.print(frame)
	print("Ally")
	for index, character in next, frame.state.team1 do
		print("  " .. width(character.character.name, 10) .. "\t" .. character.pos .. "\t" .. getremaining(character))
	end
	print("Enemy")
	for index, character in next, frame.state.team2 do
		print("  " .. width(character.character.name, 10) .. "\t" .. character.pos .. "\t" .. getremaining(character))
	end
end

return printpos
