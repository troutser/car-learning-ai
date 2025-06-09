local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Matrices = require(script.Matrices)
local EvolutionaryNN = require(script.EvolutionaryNN)
local CarsModule = require(script.Cars)

local CONFIGURATION = {
	POPULATION_SIZE = 10,
	MUTATION_RATE = 0.1,
	MUTATION_SCALE = 0.01,
	ELITE_SIZE = 5,
	LAYER_SIZES = {12, 25, 2},
	TOTAL_GENERATION_TIME = 10
}
task.wait(3)

local NeuralNetworks = {}
local Cars = {}
for _ = 1, CONFIGURATION.POPULATION_SIZE do
	table.insert(NeuralNetworks, EvolutionaryNN.new(CONFIGURATION.LAYER_SIZES))
	table.insert(Cars, CarsModule.new())
end
local genNumber = 0
while true do
	local generationStartTime = tick()
	local fitnessScores = table.create(CONFIGURATION.POPULATION_SIZE, 0)
	
	local CarsCrashed = 0
	
	for _, car in Cars do
		car:bindCrashDetection()
		task.wait()
	end
	print("Starting generation "..genNumber)
	while tick() - generationStartTime < CONFIGURATION.TOTAL_GENERATION_TIME do
		for index, NeuralNetwork in NeuralNetworks do
			local Car = Cars[index]
			
			if Car.Crashed then CarsCrashed += 1 continue end
			local originalRotation = Car.Rotation
			local input = Car:castRays()
			table.insert(input, Car.Speed)
			table.insert(input, Car.Rotation)
			
			local output = NeuralNetwork:forward(Matrices.new(12, 1, input))
			Car:input(output[1][1], output[2][1])
			
			fitnessScores[index] += tick() - generationStartTime + 3 * math.abs(Car.Speed) - 24 * math.abs(Car.Rotation - originalRotation)
		end
		if CarsCrashed == CONFIGURATION.POPULATION_SIZE then break end
		CarsCrashed = 0
		task.wait()
	end
	genNumber += 1
	for index, Car in Cars do
		if Car.Crashed then 
			fitnessScores[index] -= 5000
		end
		Car.Model:Destroy()
		Cars[index] = nil
		Cars[index] = CarsModule.new()
	end
	NeuralNetworks = EvolutionaryNN.evolve(NeuralNetworks, fitnessScores, CONFIGURATION.ELITE_SIZE, CONFIGURATION.MUTATION_RATE, CONFIGURATION.MUTATION_SCALE)
	
	local totalFitness = 0
	for _, fitness in fitnessScores do
		totalFitness += fitness
	end
	print(totalFitness/#fitnessScores)
end
