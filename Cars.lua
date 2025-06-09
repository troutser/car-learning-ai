local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Include
RaycastParams.FilterDescendantsInstances = {workspace.Obstacles}

local Cars = {}
Cars.__index = Cars
Cars.numberOfRays = 10

local Config = {
	VISUALIZATION_RAY_THICKNESS = 0.1,
	VISUALIZATION_RAY_COLOR = Color3.fromRGB(113, 255, 97),
	
}

function Cars.new()
	local Car = {}

	Car.Model = game.ReplicatedStorage.Car:Clone()
	Car.Model.Parent = workspace.Cars
	Car.Crashed = false
	Car.Speed = 0
	Car.Rotation = 0

	setmetatable(Car, Cars)
	
	return Car
end

function Cars:bindCrashDetection()
	local function onCrash(hit)
		if not (hit:IsDescendantOf(workspace.Obstacles) and not hit:IsDescendantOf(workspace.Cars)) then return end

		self.Crashed = true
		self.Model.PrimaryPart.Anchored = true
	end
	
	for _, part in self.Model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		
		part.Touched:Connect(onCrash)
	end
end


function Cars:castRays(visualize)
	local results = {}
	local startAngle = -math.pi/2
	local increment = math.pi / (Cars.numberOfRays - 1)

	for i = 0, Cars.numberOfRays - 1 do
		local currentAngle = startAngle + (i * increment)
		local rayDir = (self.Model.PrimaryPart.CFrame * CFrame.Angles(0, currentAngle, 0)).LookVector * 300

		local rayResult = workspace:Raycast(
			self.Model.PrimaryPart.Position,
			rayDir,
			RaycastParams
		)

		local distance = 300
		if rayResult then
			distance = (rayResult.Position - self.Model.PrimaryPart.Position).Magnitude
		end
		table.insert(results, distance)
		
		if visualize then
			local origin, lookAt = self.Model.PrimaryPart.Position * 0.5 + rayResult.Position * 0.5, rayResult.Position
			local RayPart = ReplicatedStorage.Ray:Clone()
			RayPart.Parent = workspace
			RayPart.Size = Vector3.new(0.1,0.1, (self.Model.PrimaryPart.Position - rayResult.Position).Magnitude)
			RayPart.CFrame = CFrame.lookAt(origin, lookAt)

			Debris:AddItem(RayPart, 0.1)
		end
	end
	return results
end
function Cars:input(speed, rotation)
	self.Speed = speed
	self.Rotation = rotation
	
	self:turn()
	self:drive()
end
function Cars:turn()
	self.Model.Chassis.AssemblyAngularVelocity = Vector3.new(0,self.Rotation,0)
end
function Cars:drive()
	self.Model.Chassis.BodyPosition.Position = self.Model.Chassis.Position + self.Model.PrimaryPart.CFrame.LookVector * self.Speed * Vector3.new(1,0,1)
end
return Cars
