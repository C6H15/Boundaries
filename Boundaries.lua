--!strict
--!native
--!optimize 2
-- Boundaries v1.3.1
-- https://github.com/C6H15/Boundaries
-- Inspired by QuickBounds (@unityjaeger)
export type _Shape = "Block" | "Ball" | "Complex"
export type _EnteredCallback = (Boundary: _BoundaryProperties, TrackedPart: BasePart, CallbackData: any, IsFirstBoundary: boolean) -> ()
export type _ExitedCallback = (Boundary: _BoundaryProperties, TrackedPart: BasePart, CallbackData: any, IsLastBoundary: boolean) -> ()
export type _Boundary = {
	IsDestroyed: boolean,
	Index: number,
	TrackGroups: (CreatedBoundary: _Boundary, ...string) -> (),
	UntrackGroups: (CreatedBoundary: _Boundary, ...string) -> (),
	Destroy: (CreatedBoundary: _Boundary) -> (),
}
export type _BoundaryProperties = {
	Name: string,
	Shape: _Shape,
	CFrame: CFrame,
	Position: Vector3,
	HalfSize: Vector3,
	Part: BasePart?,
	-- Ball Properties
	Radius: number?,
}
type _Presences = { [number]: boolean }
type _RegisteredPartGroups = { [string]: {LastPresences: _Presences, Count: number} }
type _RegisteredPart = {
	CallbackData: { [string]: any },
	Groups: _RegisteredPartGroups, -- In group if non-nil and presence indicates the boundary it's in.
	Connection: RBXScriptConnection,
}
type _GroupCallbacks = {
	Entered: {_EnteredCallback},
	Exited: {_ExitedCallback},
}
type _BVHItem = {
	Index: number,
	MortonCode: number,
}
type _BVHNode = {
	Index: number?,
	Min: Vector3,
	Max: Vector3,
	LeftNode: _BVHNode?,
	RightNode: _BVHNode?,
}

local RunService = game:GetService("RunService")

local OutdatedBVH: boolean = false
local FrameBudget: number = 0.0002
local LastPresencesCount: number = nil
local CurrentPresencesCount: number = nil

local PostSimulationConnection: RBXScriptConnection? = nil
local ComplexOverlapParams: OverlapParams = nil
local LastPart: BasePart? = nil

local Boundaries = {}
local BoundaryData: { [number]: _BoundaryProperties } = {}
local BoundaryGaps: {number} = {}
local BoundaryCallbacks: { [string]: _GroupCallbacks } = {}
local BoundaryGroups: { [number]: {string} } = {}
local CurrentBoundaries: {number} = {}
local CurrentPresences: _Presences = {}
local RegisteredParts: { [BasePart]: _RegisteredPart } = {}
local BVHRoot: _BVHNode? = nil

local function SpreadBits(Value: number): number
	Value = bit32.band(Value, 0x3FF)
	Value = bit32.band(bit32.bor(Value, bit32.lshift(Value, 16)), 0x30000FF)
	Value = bit32.band(bit32.bor(Value, bit32.lshift(Value, 8)), 0x300F00F)
	Value = bit32.band(bit32.bor(Value, bit32.lshift(Value, 4)), 0x30C30C3)
	Value = bit32.band(bit32.bor(Value, bit32.lshift(Value, 2)), 0x9249249)
	return Value
end
local function CalculateAABB(Boundary: _BoundaryProperties): (Vector3, Vector3)
	local Center = Boundary.Position
	local HalfSize = Boundary.HalfSize
	local CF = Boundary.CFrame
	local WorldExtent = vector.abs(CF.RightVector) * HalfSize.X
		+ vector.abs(CF.UpVector) * HalfSize.Y
		+ vector.abs(CF.LookVector) * HalfSize.Z
	return Center - WorldExtent, Center + WorldExtent
end
local function CalculateBounds(): (Vector3, Vector3)
	local HugeValue, SmallValue = vector.one * math.huge, nil
	local MinBounds, MaxBounds = HugeValue, -HugeValue
	for _, Boundary in BoundaryData do
		local Min, Max = CalculateAABB(Boundary)
		MinBounds = vector.min(MinBounds, Min)
		MaxBounds = vector.max(MaxBounds, Max)
	end
	SmallValue = vector.max(vector.one, (MaxBounds - MinBounds) * 0.01)
	return MinBounds - SmallValue, MaxBounds + SmallValue
end
local function CalculateMortonCodes(CF: CFrame, MinBounds: Vector3, MaxBounds: Vector3): number
	local Scaled = vector.clamp((CF.Position - MinBounds) / (MaxBounds - MinBounds), vector.zero, vector.one) * 1023
	local Indices = vector.floor(Scaled)
	return bit32.bor(SpreadBits(Indices.x), bit32.lshift(SpreadBits(Indices.y), 1), bit32.lshift(SpreadBits(Indices.z), 2))
end
local function CalculateSplitIndex(StartIndex: number, EndIndex: number, BVHItems: {_BVHItem}): number
	if EndIndex == StartIndex + 1 then return EndIndex end
	local FirstMortonCode, LastMortonCode = BVHItems[StartIndex].MortonCode, BVHItems[EndIndex].MortonCode
	if FirstMortonCode == LastMortonCode then return (StartIndex + EndIndex) // 2 end
	local CommonPrefixLength = bit32.countlz(bit32.bxor(FirstMortonCode, LastMortonCode))
	local Left, Right = StartIndex, EndIndex
	while Left + 1 < Right do
		local Pivot = (Left + Right) // 2
		if bit32.countlz(bit32.bxor(FirstMortonCode, BVHItems[Pivot].MortonCode)) > CommonPrefixLength then
			Left = Pivot else Right = Pivot
		end
	end
	return Left + 1
end
local function CreateBVHNode(StartIndex: number, EndIndex: number, MinBounds: { [number]: Vector3 }, MaxBounds: { [number]: Vector3 }, BVHItems: {_BVHItem}): _BVHNode
	if StartIndex == EndIndex then
		local Index = BVHItems[StartIndex].Index
		return {
			["Index"] = Index,
			["Min"] = MinBounds[Index],
			["Max"] = MaxBounds[Index],
		}
	end
	local SplitIndex = CalculateSplitIndex(StartIndex, EndIndex, BVHItems)
	local LeftNode = CreateBVHNode(StartIndex, SplitIndex - 1, MinBounds, MaxBounds, BVHItems)
	local RightNode = CreateBVHNode(SplitIndex, EndIndex, MinBounds, MaxBounds, BVHItems)
	local Min, Max = vector.min(LeftNode.Min, RightNode.Min), vector.max(LeftNode.Max, RightNode.Max)
	return {
		["Min"] = Min,
		["Max"] = Max,
		["LeftNode"] = LeftNode,
		["RightNode"] = RightNode,
	}
end
local function CreateBVH(): _BVHNode?
	if #BoundaryData == 0 then return end
	local MinBounds, MaxBounds = CalculateBounds()
	local BoundaryMinBounds, BoundaryMaxBounds = {}, {}
	local BVHItems: {_BVHItem} = {}
	for Index, Boundary in BoundaryData do
		local Min, Max = CalculateAABB(Boundary)
		BoundaryMinBounds[Index] = Min
		BoundaryMaxBounds[Index] = Max
		table.insert(BVHItems, {
			Index = Index,
			MortonCode = CalculateMortonCodes(Boundary.CFrame, MinBounds, MaxBounds),
		})
	end
	table.sort(BVHItems, function(a, b)
		return a.MortonCode < b.MortonCode
	end)
	return CreateBVHNode(1, #BVHItems, BoundaryMinBounds, BoundaryMaxBounds, BVHItems)
end
local function InsertBoundary(Boundary: _BoundaryProperties): number
	local Output: number
	if #BoundaryGaps > 0 then
		local Index = table.remove(BoundaryGaps, 1) :: number
		BoundaryData[Index] = Boundary
		Output = Index
	else -- BoundaryGaps is empty.
		table.insert(BoundaryData, Boundary)
		Output = #BoundaryData
	end
	return Output
end
local function TrackGroups(CreatedBoundary: _Boundary, ...: string)
	if CreatedBoundary.IsDestroyed then return end
	local Groups = BoundaryGroups[CreatedBoundary.Index]
	if Groups == nil then return end
	local GroupCount: number = select("#", ...)
	for i = 1, GroupCount do
		local Group = select(i, ...)
		if table.find(Groups, Group) == nil then table.insert(Groups, Group) end
	end
end
local function UntrackGroups(CreatedBoundary: _Boundary, ...: string)
	if CreatedBoundary.IsDestroyed then return end
	local Groups = BoundaryGroups[CreatedBoundary.Index]
	if Groups == nil then return end
	local GroupCount: number = select("#", ...)
	for i = 1, GroupCount do
		local Index = table.find(Groups, select(i, ...))
		if Index ~= nil then table.remove(Groups, Index) end
	end
end
local function Destroy(CreatedBoundary: _Boundary)
	if CreatedBoundary.IsDestroyed then return end
	CreatedBoundary.IsDestroyed = true
	local Index = CreatedBoundary.Index
	if Index == #BoundaryData then
		-- Index specified for safety.
		table.remove(BoundaryData, Index) else table.insert(BoundaryGaps, Index)
	end
	BoundaryData[Index] = nil
	for _, RegisteredPart in RegisteredParts do
		for _, Presences in RegisteredPart.Groups do
			Presences[Index] = nil
		end
	end
	BoundaryGroups[Index] = nil
	OutdatedBVH = true
end
local function RemoveRegisteredPart(Part: BasePart)
	local RegisteredPart = RegisteredParts[Part]
	if RegisteredPart == nil then return end
	for Group, Presences in RegisteredPart.Groups do
		local GroupCallbacks = BoundaryCallbacks[Group]
		if GroupCallbacks == nil then continue end
		for Index, Inside in Presences do
			local Boundary = BoundaryData[Index]
			if not Inside or Boundary == nil then continue end
			for _, Callback in GroupCallbacks.Exited do
				task.spawn(Callback, Boundary, Part, RegisteredPart.CallbackData, true)
			end
		end
	end
	RegisteredPart.Connection:Disconnect()
	RegisteredParts[Part] = nil
end
local function PointInBoundary(Boundary: _BoundaryProperties, Part: BasePart): boolean
	local Position: Vector3 = Part.Position
	if Boundary.Shape == "Block" then
		local LocalPosition = vector.abs(Boundary.CFrame:PointToObjectSpace(Position))
		return vector.min(LocalPosition, Boundary.HalfSize) == LocalPosition
	elseif Boundary.Shape == "Ball" then
		return vector.magnitude(Boundary.Position - Position) <= Boundary.Radius :: number
	elseif Boundary.Shape == "Complex" then
		local LocalPosition = vector.abs(Boundary.CFrame:PointToObjectSpace(Position))
		if vector.min(LocalPosition, Boundary.HalfSize) == LocalPosition then
			-- Querying for each part isn't optimal, but it's better than querying the entire boundary even if batched.
			ComplexOverlapParams.FilterDescendantsInstances = {Boundary.Part :: BasePart} -- Inserting into an existing table won't work.
			return #workspace:GetPartsInPart(Part, ComplexOverlapParams) > 0
		end
	end
	return false
end
local function QueryBoundaries(Node: _BVHNode?, Part: BasePart, Callback: (Index: number) -> ())
	local Position: Vector3 = Part.Position
	if Node == nil or vector.clamp(Position, Node.Min, Node.Max) ~= Position then return end
	if Node.Index ~= nil then
		local Boundary = BoundaryData[Node.Index]
		if Boundary ~= nil and PointInBoundary(Boundary, Part) then Callback(Node.Index) end
	else
		if Node.LeftNode ~= nil then QueryBoundaries(Node.LeftNode, Part, Callback) end
		if Node.RightNode ~= nil then QueryBoundaries(Node.RightNode, Part, Callback) end
	end
end
local function OnPostSimulation(DeltaTime: number)
	if OutdatedBVH then
		BVHRoot = CreateBVH()
		OutdatedBVH = false
	end
	if BVHRoot == nil then return end
	local TotalTime: number = 0
	while TotalTime < FrameBudget do
		local Part, RegisteredPart = next(RegisteredParts, LastPart)
		if Part == nil then LastPart = nil break end
		LastPart = Part
		table.clear(CurrentBoundaries)
		local QueryStartTime: number = os.clock()
		QueryBoundaries(BVHRoot, Part, function(Index)
			table.insert(CurrentBoundaries, Index)
		end)
		for Group, PartGroups in RegisteredPart.Groups do
			local LastPresences = PartGroups.LastPresences
			table.clear(CurrentPresences)
			CurrentPresencesCount = 0
			for _, Index in CurrentBoundaries do
				local Groups = BoundaryGroups[Index]
				if Groups ~= nil and table.find(Groups, Group) ~= nil then
					CurrentPresences[Index] = true
					CurrentPresencesCount += 1
				end
			end
			local GroupCallbacks = BoundaryCallbacks[Group]
			if GroupCallbacks ~= nil then
				LastPresencesCount = PartGroups.Count or 0
				local IsFirstBoundary: boolean = LastPresencesCount <= 0
				local IsLastBoundary: boolean = CurrentPresencesCount <= 0
				-- Exited
				for Index, Inside in LastPresences do
					if Inside and not CurrentPresences[Index] then
						local Boundary = BoundaryData[Index]
						if Boundary == nil then continue end
						for _, Callback in GroupCallbacks.Exited do
							task.spawn(Callback, Boundary, Part, RegisteredPart.CallbackData, IsLastBoundary)
						end
					end
				end
				-- Entered
				for Index, _ in CurrentPresences do
					if LastPresences[Index] then continue end
					local Boundary = BoundaryData[Index]
					if Boundary == nil then continue end
					for _, Callback in GroupCallbacks.Entered do
						task.spawn(Callback, Boundary, Part, RegisteredPart.CallbackData, IsFirstBoundary)
					end
				end
			end
			table.clear(LastPresences)
			PartGroups.Count = CurrentPresencesCount
			for Index, _ in CurrentPresences do
				LastPresences[Index] = true
			end
		end
		TotalTime += os.clock() - QueryStartTime
	end
end
function Boundaries.EnableCollisionDetection()
	if typeof(PostSimulationConnection) ~= "RBXScriptConnection" then
		PostSimulationConnection = RunService.PostSimulation:Connect(OnPostSimulation)
	end
end
function Boundaries.DisableCollisionDetection()
	if typeof(PostSimulationConnection) == "RBXScriptConnection" then
		PostSimulationConnection:Disconnect()
		PostSimulationConnection = nil
	end
end
function Boundaries.SetFrameBudgetMillis(Value: number)
	if type(Value) == "number" then FrameBudget = Value / 1000 end
end
function Boundaries.CreateBoundary(Shape: _Shape, Name: string, CF: CFrame, Size: Vector3, Part: BasePart?): _Boundary
	if type(Shape) ~= "string" then
		error("Shape must be a string.", 2)
	elseif type(Name) ~= "string" then
		error("Name must be a string.", 2)
	elseif typeof(CF) ~= "CFrame" then
		error("CF must be a CFrame.", 2)
	elseif typeof(Size) ~= "Vector3" then
		error("Size must be a Vector3.", 2)
	elseif Part ~= nil and (typeof(Part) ~= "Instance" or not Part:IsA("BasePart")) then
		error("Part must be a BasePart.", 2)
	end
	local Boundary: _BoundaryProperties = {
		["Name"] = Name,
		["Shape"] = Shape,
		["CFrame"] = CF,
		["Position"] = CF.Position,
		["HalfSize"] = Size / 2,
		["Part"] = Part,
		["Radius"] = nil,
	}
	if Shape == "Ball" then
		if Size.X ~= Size.Y or Size.Y ~= Size.Z then error(`{Name} ({Shape}) must have equal dimensions.`, 2) end
		Boundary.Radius = Boundary.HalfSize.Y
	elseif Shape == "Complex" then
		if Part == nil then error(`{Name} ({Shape}) must have a part specified.`, 2) end
		if ComplexOverlapParams == nil then
			ComplexOverlapParams = OverlapParams.new()
			ComplexOverlapParams.FilterType = Enum.RaycastFilterType.Include
		end
		Part.CanQuery = true
	end
	local Index = InsertBoundary(Boundary)
	BoundaryGroups[Index] = {}
	OutdatedBVH = true
	return {
		["IsDestroyed"] = false,
		["Index"] = Index,
		["TrackGroups"] = TrackGroups,
		["UntrackGroups"] = UntrackGroups,
		["Destroy"] = Destroy,
	}
end
function Boundaries.CreateBoundaryFromPart(Part: BasePart, Name: string?): _Boundary
	if typeof(Part) ~= "Instance" then error("Part isn't an Instance.", 2) end
	local Shape: _Shape
	if Part:IsA("Part") then
		local PartType = Part.Shape
		if PartType == Enum.PartType.Block then
			Shape = "Block"
		elseif PartType == Enum.PartType.Ball then
			Shape = "Ball"
		else
			error(`{Part.Name} is an unsupported {PartType.Name}-shaped part.`, 2)
		end
	elseif Part:IsA("UnionOperation") or Part:IsA("MeshPart") then
		Shape = "Complex"
	else
		Shape = "Block"
	end
	return Boundaries.CreateBoundary(Shape, Name or Part.Name, Part.CFrame, Part.Size, Part)
end
function Boundaries.TrackPart(Part: BasePart, Groups: {string}, CallbackData: any)
	local RegisteredPart = RegisteredParts[Part]
	local GroupSet: _RegisteredPartGroups = {}
	for _, Group in Groups do
		if type(Group) == "string" then
			GroupSet[Group] = {
				["LastPresences"] = {},
				["Count"] = 0,
			}
		end
	end
	if RegisteredPart == nil then
		local function OnAncestryChanged(_, Parent: Instance)
			if Parent == nil then RemoveRegisteredPart(Part) end
		end
		RegisteredPart = {
			["CallbackData"] = CallbackData,
			["Groups"] = GroupSet,
			["Connection"] = Part.AncestryChanged:Connect(OnAncestryChanged),
		}
		RegisteredParts[Part] = RegisteredPart
	else -- RegisteredPart exists already.
		RegisteredPart.Groups = GroupSet
	end
end
function Boundaries.UntrackPart(Part: BasePart)
	if RegisteredParts[Part] ~= nil then RemoveRegisteredPart(Part) end
end
function Boundaries.GetBoundariesContainingPart(Part: BasePart): {_BoundaryProperties}
	-- TODO: Incomplete
end
function Boundaries.AssignGroups(Part: BasePart, ...: string)
	local RegisteredPart = RegisteredParts[Part]
	if RegisteredPart == nil then return end
	local GroupCount: number = select("#", ...)
	for i = 1, GroupCount do
		local Group = select(i, ...)
		if type(Group) ~= "string" then continue end
		if RegisteredPart.Groups[Group] == nil then RegisteredPart.Groups[Group] = {} end
	end
end
function Boundaries.UnassignGroups(Part: BasePart, ...: string)
	local RegisteredPart = RegisteredParts[Part]
	if RegisteredPart == nil then return end
	local GroupCount: number = select("#", ...)
	for i = 1, GroupCount do
		local Group = select(i, ...)
		if type(Group) ~= "string" then continue end
		RegisteredPart.Groups[Group] = nil
	end
end
function Boundaries.IsPartInGroups(Part: BasePart, ...: string): ...boolean
	-- TODO: Incomplete
end
function Boundaries.GetPartGroups(Part: BasePart): {string}
	-- TODO: Incomplete
end
function Boundaries.OnEntered(Group: string, Callback: _EnteredCallback): () -> ()
	local GroupCallbacks = BoundaryCallbacks[Group]
	local Index: number
	if GroupCallbacks == nil then
		GroupCallbacks = {
			["Entered"] = {},
			["Exited"] = {},
		}
		BoundaryCallbacks[Group] = GroupCallbacks
	end
	table.insert(GroupCallbacks.Entered, Callback)
	Index = #GroupCallbacks.Entered
	return function()
		GroupCallbacks = BoundaryCallbacks[Group]
		if GroupCallbacks == nil then return end
		GroupCallbacks.Entered[Index] = nil
		if #GroupCallbacks.Entered + #GroupCallbacks.Exited ~= 0 then return end
		BoundaryCallbacks[Group] = nil
	end
end
function Boundaries.OnExited(Group: string, Callback: _ExitedCallback): () -> ()
	local GroupCallbacks = BoundaryCallbacks[Group]
	local Index: number
	if GroupCallbacks == nil then
		GroupCallbacks = {
			["Entered"] = {},
			["Exited"] = {},
		}
		BoundaryCallbacks[Group] = GroupCallbacks
	end
	table.insert(GroupCallbacks.Exited, Callback)
	Index = #GroupCallbacks.Exited
	return function()
		GroupCallbacks = BoundaryCallbacks[Group]
		if GroupCallbacks == nil then return end
		GroupCallbacks.Exited[Index] = nil
		if #GroupCallbacks.Exited + #GroupCallbacks.Entered ~= 0 then return end
		BoundaryCallbacks[Group] = nil
	end
end

return Boundaries
