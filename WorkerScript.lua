local Actor = script:GetActor()

local Operations = {
	MultiplyMatrix = function(m1, m2, m1columns, m2columns, outputTable, m1rows, FinishedFlags, workerIndex, workerCount)
		for i = workerIndex, m1rows, workerCount do
			for j = 1, m2columns do
				local cell = 0
				for k = 1, m1columns do
					cell += m1[i][k] * m2[k][j]
				end
				outputTable[i][j] = cell
			end
		end
		FinishedFlags[workerIndex] = true
	end,
}

for operation, func in Operations do
	Actor:BindToMessageParallel(operation, func)
end
