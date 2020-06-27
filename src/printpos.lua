local printpos = {}

function printpos.print(frame)
	print("Ally")
	for index, character in next, frame.state.team1 do
		print("  " .. character.character.name .. "\t" .. (character.pos + 1080))
	end
	print("Enemy")
	for index, character in next, frame.state.team2 do
		print("  " .. character.character.name .. "\t" .. (character.pos + 1080))
	end
end

return printpos
