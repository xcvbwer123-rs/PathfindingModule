local Pathfinding = {}

local Path = {}

local PathfindingService = game:GetService("PathfindingService")

type TargetFindResult = {
	Model: Model,
	Root: BasePart,
	Humanoid: Humanoid,
	Team: string,
	Distance: number
}

local function GetDistance(Position1, Position2): number
	return (Position2 - Position1).Magnitude
end

function Path:Raycast(Start, End, Params, Unit): RaycastResult | nil
	local RaycastOffset = (End - Start)
	Params = Params or (function() local rp = RaycastParams.new() rp.FilterDescendantsInstances = {self.Model} return rp end)()
	local Result = workspace:Raycast(Start, if Unit then RaycastOffset.Unit * Unit else RaycastOffset, Params)
	return Result
end

function Path:FindTrusses(Distance: number, Parent: Instance)
	Parent = Parent or workspace
	if not self.TrussConnect then
		self.TrussConnect = Parent.DescendantAdded:Connect(function(Instance)
			if Instance:IsA("TrussPart") and self.Trusses then
				table.insert(self.Trusses, Instance)
			end
		end)
	end
	if #Parent:GetDescendants() >= 15000 and self.Trusses ~= nil then return self.Trusses end
	local Trusses = {}
	Distance = Distance or math.huge
	for number, Child in ipairs(Parent:GetDescendants()) do
		if Child:IsA("TrussPart") then
			table.insert(Trusses, Child)
		end
		if number%50 == 0 and number ~= 0 then
			task.wait()
		end
	end
	self.Trusses = table.freeze(Trusses)
	return self.Trusses
end

function Path:GetTopnBottom(Truss: TrussPart)
	local MyHuman = self.Humanoid
	local Top = (Truss.CFrame * CFrame.new(0, (Truss.Size.Y / 2) + MyHuman.HipHeight, 0)).Position
	local Bottom = (Truss.CFrame * CFrame.new(0, -((Truss.Size.Y / 2) + MyHuman.HipHeight), 0)).Position
	local Ray = self:Raycast(Truss.Position, Bottom, nil, GetDistance(Truss.Position, Bottom))
	if Ray then
		Bottom = (CFrame.new(Ray.Position) * CFrame.new(0, 0, -2)).Position
	end
	return Top, Bottom
end

function Path:FindTarget(Distance: number, Parent: Instance): TargetFindResult | nil
	local MyTeam = self.Team or game:GetService("HttpService"):GenerateGUID(false)
	local MyRoot: BasePart = self.MyRoot
	Distance = Distance or math.huge
	if typeof(Distance) == "table" then Distance = math.huge end
	local FinalTarget
	for _, Child in ipairs((Parent or workspace):GetChildren()) do
		local Humanoid = Child:FindFirstChildOfClass("Humanoid")
		local RootPart = Child:FindFirstChild("HumanoidRootPart")
		local Team = Child:FindFirstChild("Team")
		if Team and Team:IsA("StringValue") and Team.Value == MyTeam then
			continue
		end
		if Child:IsA("Model") and Child ~= self.Model and Humanoid and RootPart and RootPart:IsA("BasePart") and Humanoid.Health > 0 and GetDistance(RootPart.Position, MyRoot.Position) < Distance then
			FinalTarget = Child
			Distance = GetDistance(RootPart.Position, MyRoot.Position)
		end
	end
	
	if FinalTarget then
		local Humanoid = FinalTarget:FindFirstChildOfClass("Humanoid")
		local RootPart = FinalTarget:FindFirstChild("HumanoidRootPart")
		local Team = FinalTarget:FindFirstChild("Team")
		if not Team then
			Team = {Value = "None"}
		end
		return table.freeze({
			Model = FinalTarget,
			Root = RootPart,
			Humanoid = Humanoid,
			Team = Team.Value,
			Distance = GetDistance(MyRoot.Position, RootPart.Position)
		})
	end
	return
end

function Path:CanSeeTarget(Target: TargetFindResult)
	local MyRoot = self.MyRoot
	local Param = RaycastParams.new()
	Param.FilterDescendantsInstances = {Target.Model}	
	local TargetRoot = Target.Root
	local RootNextPosition = TargetRoot.Position + (TargetRoot.Velocity * Vector3.new(0.25, 0.15, 0.25))
	local Result = workspace:Raycast(MyRoot.Position, (RootNextPosition - MyRoot.Position).Unit * 40, Param)
	if Result and Result.Instance:IsDescendantOf(Target.Model) and math.abs(Result.Position.Y - MyRoot.Position.Y) < 3 then
		return true
	end
	return false
end

function Path:MoveTo(TargetFindRange: number, Parent: Instance, Target: TargetFindResult)
	if Target == nil then
		Target = self:FindTarget(TargetFindRange, Parent)
	end
	
	self.Following = true
	
	local MyHuman: Humanoid = self.Humanoid
	local MyRoot: BasePart = self.MyRoot
	
	local TargetHuman = Target.Humanoid
	local TargetRoot = Target.Root
	
	local NextCalculatePosition = TargetRoot.Position + (TargetRoot.Velocity * 0.25)
	
	local MovePath: Path = PathfindingService:CreatePath(self.PathfindingParams)
	MovePath:ComputeAsync(MyRoot.Position, if GetDistance(NextCalculatePosition * Vector3.new(1, 0, 1), TargetRoot.Position * Vector3.new(1, 0, 1)) > 10 then TargetRoot.Position else NextCalculatePosition)
	
	if MovePath.Status == Enum.PathStatus.Success then
		local Waypoints = MovePath:GetWaypoints()
		for Index, Waypoint: PathWaypoint in ipairs(Waypoints) do
			local Distance = GetDistance(MyRoot.Position * Vector3.new(1, 0, 1), Waypoint.Position * Vector3.new(1, 0, 1))
			
			if self.Following == false then
				break
			end
			
			if Waypoint.Action == Enum.PathWaypointAction.Jump then
				MyHuman.Jump = true
			end
			
			if self:CanSeeTarget(Target) then
				repeat
					local NextCalculatePosition = TargetRoot.Position + (TargetRoot.Velocity * 0.25)
					MyHuman:MoveTo(NextCalculatePosition)
					if Target == nil then
						break
					elseif TargetRoot.Parent == nil then
						break
					end
					task.wait()
				until self:CanSeeTarget(Target) == false or MyHuman.Health < 1
			end
			
			MyHuman:MoveTo(Waypoint.Position)
			
			local Timeout = MyHuman.MoveToFinished:Wait()
			
			if not Timeout then
				MyHuman.Jump = true
				self:MoveTo(self:FindTarget(TargetFindRange, Parent))
				break
			end
			
			if GetDistance(MyRoot.Position, Waypoints[1].Position) > MyHuman.WalkSpeed*1.25 then
				self:MoveTo(self:FindTarget(TargetFindRange, Parent))
				break
			end
		end
	else
		if self.AgentCanMoveWithTrussParts then
			local Trusses = self:FindTrusses()
			for _, Truss: TrussPart in ipairs(Trusses) do
				local Top, Bottom = self:GetTopnBottom(Truss)
				MovePath:ComputeAsync(MyRoot.Position, Bottom)
				if MovePath.Status == Enum.PathStatus.Success then
					self:MoveToByPosition(Bottom)
					MyHuman:MoveTo(Top)
					MyHuman.MoveToFinished:Wait()
				end
				self:MoveTo(self:FindTarget(TargetFindRange, Parent))
				break
			end
		end
		self:MoveTo(self:FindTarget(TargetFindRange, Parent))
	end
end

function Path:MoveToByPosition(TargetPosition: Vector3)
	self.Following = true

	local MyHuman: Humanoid = self.Humanoid
	local MyRoot: BasePart = self.MyRoot

	local MovePath: Path = PathfindingService:CreatePath(self.PathfindingParams)
	MovePath:ComputeAsync(MyRoot.Position, TargetPosition)

	if MovePath.Status == Enum.PathStatus.Success then
		local Waypoints = MovePath:GetWaypoints()
		for Index, Waypoint: PathWaypoint in ipairs(Waypoints) do
			local Distance = GetDistance(MyRoot.Position * Vector3.new(1, 0, 1), Waypoint.Position * Vector3.new(1, 0, 1))

			if self.Following == false then
				break
			end

			if Waypoint.Action == Enum.PathWaypointAction.Jump then
				MyHuman.Jump = true
			end

			MyHuman:MoveTo(Waypoint.Position)

			local Timeout = MyHuman.MoveToFinished:Wait()

			if not Timeout then
				MyHuman.Jump = true
				self:MoveToByPosition(TargetPosition)
				break
			end
		end
	else
		if self.AgentCanMoveWithTrussParts then
			local Trusses = self:FindTrusses()
			for _, Truss: TrussPart in ipairs(Trusses) do
				local Top, Bottom = self:GetTopnBottom(Truss)
				MovePath:ComputeAsync(MyRoot.Position, Bottom)
				if MovePath.Status == Enum.PathStatus.Success then
					self:MoveToByPosition(Bottom)
					MyHuman:MoveTo(Top)
					MyHuman.MoveToFinished:Wait()
				end
				self:MoveToByPosition(TargetPosition)
				break
			end
		end
		self:MoveToByPosition(TargetPosition)
	end
end

function Path:StopFollowing()
	self.Following = false
end

function Path:SetNetworkOwner(Owner)
	for _, Part in ipairs(self.Model:GetChildren()) do
		if Part:IsA("BasePart") and Part:CanSetNetworkOwnership() then
			Part:SetNetworkOwner(Owner)
		end
	end
end

function Pathfinding.new(Character: Model, Team)
	local Metatable = setmetatable({
		Model = Character,
		Humanoid = Character:FindFirstChildOfClass("Humanoid"),
		MyRoot = Character:FindFirstChild("HumanoidRootPart"),
		Following = false,
	}, {__index = Path, __metatable = "Current metatable is locked"})
	
	local Newtable = setmetatable({
		PathfindingParams = {AgentRadius = 2.5},
		Team = Team or Character.Name,
		AgentCanMoveWithTrussParts = false
	}, {__index = Metatable, __metatable = "Current metatable is locked", __newindex = function(Table, Index, Value) if getfenv(2).script ~= script then return Table[Index] else rawset(Table, Index, Value) end end})
	
	Newtable:SetNetworkOwner(game:GetService("Players"):GetPlayerFromCharacter(Character))
	
	return Newtable
end

return Pathfinding
