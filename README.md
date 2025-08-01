# Boundaries
Create dynamic spatial boundaries using Bounding Volume Hierarchy (BVH) with Morton codes for efficient collision detection and boundary management.

Grab the `.rbxm` standalone file from the latest [release](https://github.com/C6H15/Boundaries/releases/latest).

## Functions
### Boundaries.EnableCollisionDetection()
Starts the boundary collision detection.
- **Type:** <br>
```luau
function Boundaries.EnableCollisionDetection()
```
### Boundaries.DisableCollisionDetection()
Stops the boundary collision detection.
- **Type:** <br>
```lua
function Boundaries.DisableCollisionDetection()
```
### Boundaries.SetFrameBudgetMillis()
Sets the maximum time (ms) allowed per frame to process boundaries.
- **Type:** <br>
```luau
function Boundaries.SetFrameBudgetMillis(Value: number)
```
- **Default:** 0.2 ms
> [!NOTE]
> The frame budget doesn't account for callback completion times, hence it's recommended to keep the budget below 0.5 ms.
### Boundaries.CreateBoundary()
Creates a boundary that can be used to detect parts.
- **Type:** <br>
```luau
function Boundaries.CreateBoundary(Shape: "Block" | "Ball" | "Complex", Name: string, CF: CFrame, Size: Vector3, Part: BasePart?): {
	IsDestroyed: boolean,
	Index: number,
	TrackGroups: (self, ...string) -> (), -- To specify which groups the boundary should consider.
	UntrackGroups: (self, ...string) -> (), -- To specify which groups the boundary should stop considering.
	Destroy: (self) -> (), -- To remove the boundary. Any associated parts will still remain.
}
```
### Boundaries.CreateBoundaryFromPart()
Creates a boundary from an existing part to detect parts.
- **Type:** <br>
```luau
function Boundaries.CreateBoundaryFromPart(Part: BasePart, Name: string?): {
	IsDestroyed: boolean,
	Index: number,
	TrackGroups: (self, ...string) -> (), -- To specify which groups the boundary should consider.
	UntrackGroups: (self, ...string) -> (), -- To specify which groups the boundary should stop considering.
	Destroy: (self) -> (), -- To remove the boundary. Any associated parts will still remain.
}
```
### Boundaries.TrackPart()
Registers a part to be tracked for detection.
- **Type:** <br>
```luau
function Boundaries.TrackPart(Part: BasePart, Groups: {string}, CallbackData: any): {
	CallbackData: { [string]: any },
	Groups: { [string]: { [number]: boolean } },
	Connection: RBXScriptConnection,
}
```
### Boundaries.UntrackPart()
Deregisters a part from being tracked for detection.
- **Type:** <br>
```luau
function Boundaries.UntrackPart(Part: BasePart)
```
### Boundaries.AssignGroups()
Assigns a part to the specified groups.
- **Type:** <br>
```luau
function Boundaries.AssignGroups(Part: BasePart, ...: string)
```
### Boundaries.UnassignGroups()
Unassigns a part from the specified groups.
- **Type:** <br>
```luau
function Boundaries.UnassignGroups(Part: BasePart, ...: string)
```
### Boundaries.OnEntered()
Registers a callback for when a part enters a boundary with the specified group.
- **Type:** <br>
```luau
function Boundaries.OnEntered(
	Group: string,
	Callback: (
		Boundary: {
			Name: string,
			Shape: _Shape,
			CFrame: CFrame,
			Position: Vector3,
			HalfSize: Vector3,
			Part: BasePart?,
			Radius: number?, -- Exists only for ball shapes.
		},
		TrackedPart: BasePart,
		CallbackData: any
	) -> () -- Callback gets the boundary data, detected part, and any associated data.
): () -> () -- A function that deregisters the callback when called.
```
### Boundaries.OnExited()
Registers a callback for when a part exits a boundary with the specified group.
- **Type:** <br>
```luau
function Boundaries.OnExited(
	Group: string,
	Callback: (
		Boundary: {
			Name: string,
			Shape: _Shape,
			CFrame: CFrame,
			Position: Vector3,
			HalfSize: Vector3,
			Part: BasePart?,
			Radius: number?, -- Exists only for ball shapes.
		},
		TrackedPart: BasePart,
		CallbackData: any
	) -> () -- Callback gets the boundary data, detected part, and any associated data.
): () -> () -- A function that deregisters the callback when called.
```

## Examples
<details>
<summary>Server</summary>

```luau
local Players = game:GetService("Players")

local Boundaries = require(PATH_TO_BOUNDARIES)
Boundaries.EnableCollisionDetection()

local function OnPlayerAdded(Player: Player)
	local function OnCharacterAdded(Character: Model)
		local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") :: Part
		Boundaries.TrackPart(HumanoidRootPart, {"Players"}, Player)
	end
	Player.CharacterAdded:Connect(OnCharacterAdded)
	if Player.Character ~= nil then
		OnCharacterAdded(Player.Character)
	end
end

local PlayesEntered = Boundaries.OnEntered("Players", function(Boundary, TrackedPart, CallbackData)
	print(`{TrackedPart.Name} has entered {Boundary.Name} with data: {CallbackData}.`)
end)
local PlayersExited = Boundaries.OnExited("Players", function(Boundary, TrackedPart, CallbackData)
	print(`{TrackedPart.Name} has exited {Boundary.Name} with data: {CallbackData}.`)
end)

Players.PlayerAdded:Connect(OnPlayerAdded)

for _, Player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, Player)
end
for _, BoundaryPart in workspace.PATH_TO_FOLDER:GetChildren() do
	local Boundary = Boundaries.CreateBoundaryFromPart(BoundaryPart)
	Boundary:TrackGroups("Players")
end
```
</details>

<details>
<summary>Client</summary>
	
```luau
local Players = game:GetService("Players")

local Boundaries = require(PATH_TO_BOUNDARIES)
Boundaries.EnableCollisionDetection()

local function OnPlayerAdded(Player: Player)
	local function OnCharacterAdded(Character: Model)
		local Highlight: Highlight = Instance.new("Highlight")
		Highlight.FillTransparency = 1
		Highlight.Parent = Character
		local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") :: Part
		Boundaries.TrackPart(HumanoidRootPart, {"Players"}, Player)
	end
	Player.CharacterAdded:Connect(OnCharacterAdded)
	if Player.Character ~= nil then
		OnCharacterAdded(Player.Character)
	end
end

Boundaries.OnEntered("Players", function(Boundary, TrackedPart, CallbackData)
	local Character = TrackedPart.Parent
	if Character == nil then return end
	local Highlight = Character:FindFirstChildWhichIsA("Highlight")
	if Highlight == nil then return end
	Highlight.OutlineColor = Boundary.Part and Boundary.Part.Color or Color3.fromRGB(255, 255, 255)
end)
Boundaries.OnExited("Players", function(Boundary, TrackedPart, CallbackData)
	local Character = TrackedPart.Parent
	if Character == nil then return end
	local Highlight = Character:FindFirstChildWhichIsA("Highlight")
	if Highlight == nil then return end
	Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
end)

Players.PlayerAdded:Connect(OnPlayerAdded)

for _, Player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, Player)
end
for _, BoundaryPart in workspace.PATH_TO_FOLDER:GetChildren() do
	local Boundary = Boundaries.CreateBoundaryFromPart(BoundaryPart)
	Boundary:TrackGroups("Players")
end
```
</details>

## Credits
Inspired by [QuickBounds](https://github.com/unityjaeger/QuickBounds) by [@unityjaeger](https://github.com/unityjaeger).
