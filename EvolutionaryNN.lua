local Matrices = require(script.Parent.Matrices) 

local EvolutionaryNN = {}
EvolutionaryNN.__index = EvolutionaryNN

local activationFunctions = {
	sigmoid = function(x)
		return 1 / (1 + math.exp(-x))
	end,
	relu = function(x)
		return math.max(0, x)
	end,
	tanh = function(x)
		return math.tanh(x)
	end,
}
local function mutate(x, _, _, args)
	local mutationRate, mutationScale = unpack(args)
	if math.random() < mutationRate then
		return x + (math.random() * 2 - 1) * mutationScale
	end
	return x
end
local function crossover(x, row, col, args)
	local other, crossoverRate, i = unpack(args)
	return math.random() < crossoverRate and x or other.weights[i][row][col]
end
local function clone(x)
	return x
end

function EvolutionaryNN.new(layerSizes: {number}, activation: string?)
	local self = setmetatable({}, EvolutionaryNN)

	self.layerSizes = layerSizes
	self.activation = activation or "relu"
	self.weights = {}
	self.biases = {}

	for i = 1, #layerSizes - 1 do
		local inputSize = layerSizes[i]
		local outputSize = layerSizes[i+1]

		local std = math.sqrt(2.0 / (inputSize + outputSize))
		self.weights[i] = Matrices.random(outputSize, inputSize) * std
		self.biases[i] = Matrices.random(outputSize, 1) * 0.1
	end

	return self
end

function EvolutionaryNN:forward(input: MatrixType): MatrixType
	local current = input

	for i = 1, #self.weights do
		current = (self.weights[i] * current) + self.biases[i] 

		if i == #self.weights then continue end

		current = current:map(activationFunctions[self.activation])
	end

	return current
end

function EvolutionaryNN:mutate(mutationRate: number, mutationScale: number)
	
	for i = 1, #self.weights do
		self.weights[i] = self.weights[i]:map(mutate, {mutationRate, mutationScale})
		self.biases[i] = self.biases[i]:map(mutate, {mutationRate, mutationScale})
	end
end

function EvolutionaryNN:crossover(other: EvolutionaryNN, crossoverRate: number): EvolutionaryNN
	local child = EvolutionaryNN.new(self.layerSizes, self.activation)

	for i = 1, #self.weights do
		child.weights[i] = self.weights[i]:map(crossover, {other, crossoverRate, i})
		child.biases[i] = self.biases[i]:map(crossover, {other, crossoverRate, i})
	end

	return child
end

function EvolutionaryNN:clone(): EvolutionaryNN
	local cloned = EvolutionaryNN.new(self.layerSizes, self.activation)

	for i = 1, #self.weights do
		cloned.weights[i] = self.weights[i]:map(clone)
		cloned.biases[i] = self.biases[i]:map(clone)
	end

	return cloned
end


function EvolutionaryNN.evolve(population: {EvolutionaryNN}, fitnessScores: {number}, 
	eliteSize: number, mutationRate: number, mutationScale: number): {EvolutionaryNN}
	
	local nextGeneration = {}
	local populationFitness = {}
	
	for index, nn in population do
		table.insert(populationFitness, {nn = nn, score = fitnessScores[index]})
	end
	table.sort(populationFitness, function(a,b) return a.score > b.score end)
	
	local totalFitness = 0
	for i = 1, eliteSize do
		table.insert(nextGeneration, populationFitness[i].nn)
		totalFitness += populationFitness[i].score
	end
	while #nextGeneration < #population do
		local parent1 = EvolutionaryNN.selectParent(populationFitness, totalFitness)
		local parent2 = EvolutionaryNN.selectParent(populationFitness, totalFitness)

		local child = parent1:crossover(parent2, 0.5) 

		child:mutate(mutationRate, mutationScale)

		table.insert(nextGeneration, child)
	end
	return nextGeneration
end
function EvolutionaryNN.selectParent(ranked, totalFitness)
	local r = math.random() * totalFitness
	local runningSum = 0

	for _, item in ranked do
		runningSum = runningSum + item.score
		if runningSum >= r then
			return item.nn
		end
	end

	return ranked[1].nn -- fallback
end
return EvolutionaryNN
