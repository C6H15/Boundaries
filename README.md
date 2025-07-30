# Boundaries
Create dynamic spatial boundaries using Bounding Volume Hierarchy (BVH) with Morton codes for efficient collision detection and boundary management.

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

## Example
```luau
local Players = game:GetService("Players")

local Boundaries = require(path.to.Boundaries)
Boundaries.EnableCollisionDetection()

local BoundaryOne = Boundaries.CreateBoundaryFromPart(path.to.Part)
BoundaryOne:TrackGroups("Players")

Boundaries.OnEntered("Players", function(Boundary, Part, Data)
	-- Your logic here.
end)
Boundaries.OnExited("Players", function(Boundary, Part, Data)
	-- Your logic here.
end)

local function OnPlayerAdded(Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	Boundaries.TrackPart(HumanoidRootPart, {"Players"}, Player)
end
Players.PlayerAdded:Connect(OnPlayerAdded)
for _, Player in Players:GetPlayers() do
	OnPlayerAdded(Player)
end
```

## Credits
Inspired by [QuickBounds](https://github.com/unityjaeger/QuickBounds) by [@unityjaeger](https://github.com/unityjaeger).
