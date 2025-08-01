# Boundaries
Create dynamic spatial boundaries using Bounding Volume Hierarchy (BVH) with Morton codes for efficient collision detection and boundary management. <br>
Grab the `.rbxm` standalone file from the latest [release](https://github.com/C6H15/Boundaries/releases/latest) to use.

## Types
### Shape
```lua
"Block" | "Ball" | "Complex"
```
### Boundary
```lua
{
	IsDestroyed: boolean, -- (Internal Use)
	Index: number, -- (Internal Use)
	TrackGroups: (self, ...string) -> (),
	UntrackGroups: (self, ...string) -> (),
	Destroy: (self) -> (),
}
```
### BoundaryProperties
```lua
{
	Name: string,
	Shape: Shape,
	CFrame: CFrame,
	Position: Vector3,
	HalfSize: Vector3,
	Part: BasePart?,
	-- Ball
	Radius: number?,
}
```

## Functions
### Boundaries.EnableCollisionDetection()
Starts the boundary collision detection, thus triggering registered callbacks.
- **Type:** <br>
```lua
function Boundaries.EnableCollisionDetection()
```
### Boundaries.DisableCollisionDetection()
Stops the boundary collision detection, thus no longer triggering callbacks.
- **Type:** <br>
```lua
function Boundaries.DisableCollisionDetection()
```
### Boundaries.SetFrameBudgetMillis()
Sets the time budget for collision detection per frame. Processing is distributed across multiple frames when exceeding the budget.
- **Type:** <br>
```lua
function Boundaries.SetFrameBudgetMillis(Value: number)
```
- **Default:** 0.2 ms
> [!IMPORTANT]
> The frame budget doesn't account for callback completion time, thus it's recommended to keep the budget below 0.5 ms and monitor performance. Speed of detection depends on the number of processed boundaries and the frame budget. A lower value spreads work across more frames whereas a higher value processes more per frame. It's a trade-off between performance and speed.
### Boundaries.CreateBoundary()
Creates a boundary for collision detection and returns a table for management.
- **Type:** <br>
```lua
function Boundaries.CreateBoundary(Shape: Shape, Name: string, CF: CFrame, Size: Vector3, Part: BasePart?): Boundary
```
- **Return:** [`Boundary`](#boundary)
### Boundaries.CreateBoundaryFromPart()
Creates a boundary from an existing part for collision detection and returns a table for management.
- **Type:** <br>
```lua
function Boundaries.CreateBoundaryFromPart(Part: BasePart, Name: string?): Boundary
```
- **Return:** [`Boundary`](#boundary)
### Boundaries.TrackPart()
Registers a part to be tracked for collision detection.
- **Type:** <br>
```lua
function Boundaries.TrackPart(Part: BasePart, Groups: {string}, CallbackData: any)
```
> [!NOTE]
> Tracked parts automatically trigger exit callbacks and are untracked when destroyed. However, in games with [StreamingEnabled](https://create.roblox.com/docs/reference/engine/classes/Workspace#StreamingEnabled), parts must be manually untracked.
### Boundaries.UntrackPart()
Deregisters a part from being tracked for collision detection.
- **Type:** <br>
```lua
function Boundaries.UntrackPart(Part: BasePart)
```
### Boundaries.GetBoundariesContainingPart()
Gets all boundaries the part is currently in.
- **Type:** <br>
```lua
function Boundaries.GetBoundariesContainingPart(Part: BasePart): {BoundaryProperties}
```
- **Return:** Array of [`BoundaryProperties`](#boundaryproperties).
### Boundaries.AssignGroups()
Assigns the part to the specified groups.
- **Type:** <br>
```lua
function Boundaries.AssignGroups(Part: BasePart, ...: string)
```
### Boundaries.UnassignGroups()
Unassigns the part from the specified groups.
- **Type:** <br>
```lua
function Boundaries.UnassignGroups(Part: BasePart, ...: string)
```
### Boundaries.IsPartInGroups()
Checks if the part is assigned to the specified groups.
- **Type:** <br>
```lua
function Boundaries.IsPartInGroups(Part: BasePart, ...: string): ...boolean
```
- **Return:** Boolean values that indicate whether the part is assigned to each specified group (in the same order as the inputs).
### Boundaries.GetPartGroups()
Gets the part's assigned groups.
- **Type:** <br>
```lua
function Boundaries.GetPartGroups(Part: BasePart): {string}
```
- **Return:** Array of groups the part is assigned to.
### Boundaries.OnEntered()
Registers a callback for when a part enters a boundary with the specified group.
- **Type:** <br>
```lua
function Boundaries.OnEntered(Group: string, Callback: (Boundary: BoundaryProperties, TrackedPart: BasePart, CallbackData: any) -> ()): () -> ()
```
- **Return:** Disconnect function to remove the callback.
### Boundaries.OnExited()
Registers a callback for when a part exits a boundary with the specified group.
- **Type:** <br>
```lua
function Boundaries.OnExited(Group: string, Callback: (Boundary: BoundaryProperties, TrackedPart: BasePart, CallbackData: any) -> ()): () -> ()
```
- **Return:** Disconnect function to remove the callback.

## Examples
<details>
<summary>Server</summary>

```lua
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boundaries = require(ReplicatedStorage.Boundaries)

local Folder = workspace.Folder

local function OnEntered(Boundary, TrackedPart, CallbackData)
	-- TrackedPart has entered Boundary with CallbackData.
end
local function OnExited(Boundary, TrackedPart, CallbackData)
	-- TrackedPart has exited Boundary with CallbackData.
end
local function OnPlayerAdded(Player: Player)
	local function OnCharacterAdded(Character: Model)
		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") :: Part
		Boundaries.TrackPart(HumanoidRootPart, {"Players"}, Player)
	end
	Player.CharacterAdded:Connect(OnCharacterAdded)
	if Player.Character ~= nil then OnCharacterAdded(Player.Character) end
end

Boundaries.OnEntered("Players", OnEntered)
Boundaries.OnExited("Players", OnExited)
Players.PlayerAdded:Connect(OnPlayerAdded)

Boundaries.EnableCollisionDetection()
for _, Player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, Player)
end
for _, Part in Folder:GetChildren() do
	local Boundary = Boundaries.CreateBoundaryFromPart(Part)
	Boundary:TrackGroups("Players")
end
```
</details>

<details>
<summary>Client</summary>
	
```lua
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local Boundaries = require(ReplicatedStorage.Boundaries)

local Folder = workspace:WaitForChild("Folder")

local function OnEntered(Boundary, TrackedPart, CallbackData)
	-- TrackedPart has entered Boundary with CallbackData.
end
local function OnExited(Boundary, TrackedPart, CallbackData)
	-- TrackedPart has exited Boundary with CallbackData.
end

local Connection_1 = Boundaries.OnEntered("Players", OnEntered)
local Connection_2 = Boundaries.OnExited("Players", OnExited)

Boundaries.EnableCollisionDetection()
Boundaries.TrackPart(Character:WaitForChild("HumanoidRootPart"), {"Players"}, Player)
for _, Part in Folder:GetChildren() do
	local Boundary = Boundaries.CreateBoundaryFromPart(Part)
	Boundary:TrackGroups("Players")
end

-- Later when you want to disconnect whichever callback...
Connection_1()
```
</details>

## Credits
Inspired by [QuickBounds](https://github.com/unityjaeger/QuickBounds) by [@unityjaeger](https://github.com/unityjaeger).
