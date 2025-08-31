---
next:
  text: 'API'
  link: '/api/types'
---

# Tutorial {#1}
This tutorial will guide you through a basic implementation of Boundaries. By the end of this tutorial, you should have a good understanding of how boundaries are created to track parts.

## Prerequisites
- A basic understanding of [Luau](https://create.roblox.com/docs/luau)
- Latest version of Boundaries

## Basic Usage

> [!IMPORTANT] Tutorial Coverage
> Not all functions and methods in the [API](/api/functions) will be covered.

### Create a Boundary
You can create a boundary by using `.CreateBoundaryFromPart()`. This function takes an existing `BasePart` and an optional name to set the boundary's name, otherwise defaulting to the given part's name.
```luau{5,16}
-- Place this code in any Script or LocalScript.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Boundaries = require(ReplicatedStorage.Boundaries)

local BoundaryPart = Instance.new("Part")
BoundaryPart.Anchored = true
BoundaryPart.Position = vector.zero
BoundaryPart.Size = vector.create(25, 25, 25)
BoundaryPart.Material = Enum.Material.ForceField
BoundaryPart.Color = Color3.fromRGB(255, 0, 0)
for _, CanProperties in {"CastShadow", "CanCollide", "CanQuery", "CanTouch"} do
	BoundaryPart[CanProperties] = false
end
BoundaryPart.Parent = workspace

local Boundary = Boundaries.CreateBoundaryFromPart(BoundaryPart, "BoundaryOne")
```
In the provided snippet a boundary is created using the existing part from just before, and its name is set.
### Use the Boundary
The newly created boundary needs to be assigned groups to track for collisions. Use the `:TrackGroups()` method to assign groups the boundary should consider and `:UntrackGroups()` to ignore groups, both take variadic string arguments.
```luau
local Boundary = Boundaries.CreateBoundaryFromPart(BoundaryPart, "BoundaryOne")
Boundary:TrackGroups("Players") -- [!code focus:2]
--Boundary:UntrackGroups("Players")
```
If you no longer need a boundary, use the `:Destroy()` method to clean it up. Subsequent methods called for the boundary are ignored.
```luau
Boundary:Destroy()
```

### Track a Part
To detect a part use the `.TrackPart()` function which will register it for collision calculations. A `BasePart` and string array must be passed with an optional custom data for the last argument. Use `.UntrackPart()` to deregister a tracked part.
```luau{8-9}
Boundary:TrackGroups("Players")

local Players = game:GetService("Players") -- [!code focus:13]

local function OnPlayerAdded(Player: Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	Boundaries.TrackPart(HumanoidRootPart, {"Players"}, Player)
	--Boundaries.UntrackPart(HumanoidRootPart)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, Player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, Player)
end
```

### Set Up Callbacks
You have to define callbacks to handle collisions that are detected using `.OnEntered()` and `.OnExited()` functions. Pass the group you want to handle along with the callback function as arguments. Both functions have a boolean flag as the last parameter, indicating whether or not it's the part's first and last boundary group. This helps distinguish between moving within a group boundary to entering and exiting group boundaries entirely.
```luau
for _, Player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, Player)
end

Boundaries.OnEntered("Players", function(Boundary, TrackedPart, CallbackData, IsFirstBoundary) -- [!code focus:8]
	print(`{TrackedPart.Name} has entered {Boundary.Name} with data: {CallbackData}...`)
	print(IsFirstBoundary and "Hasn't been in this boundary group before." or "Has already been in this boundary group before.")
end)
Boundaries.OnExited("Players", function(Boundary, TrackedPart, CallbackData, IsLastBoundary)
	print(`{TrackedPart.Name} has entered {Boundary.Name} with data: {CallbackData}...`)
	print(IsLastBoundary and "Has left this boundary group entirely." or "Hasn't left this boundary group entirely.")
end)
```
### Enable Boundaries
Now that everything is properly set, use `.EnableCollisionDetection()` to start detecting collisions and `.DisableCollisionDetection()` to stop it. You can call these functions at any point, even at the start of the script.
```luau
Boundaries.OnExited("Players", function(Boundary, TrackedPart, CallbackData, IsLastBoundary)
	print(`{TrackedPart.Name} has entered {Boundary.Name} with data: {CallbackData}...`)
	print(IsLastBoundary and "Has left this boundary group entirely." or "Hasn't left this boundary group entirely.")
end)

Boundaries.EnableCollisionDetection() -- [!code focus:2]
--Boundaries.DisableCollisionDetection()
```
Run the script to see the output. You can also copy and paste the script provided below. It should print messages as you walk in and out of the boundary.

::: details Basic Usage Script
```luau
-- Place this code in any Script or LocalScript.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Boundaries = require(ReplicatedStorage.Boundaries)

local BoundaryPart = Instance.new("Part")
BoundaryPart.Anchored = true
BoundaryPart.Position = vector.zero
BoundaryPart.Size = vector.create(25, 25, 25)
BoundaryPart.Material = Enum.Material.ForceField
BoundaryPart.Color = Color3.fromRGB(255, 0, 0)
for _, CanProperties in {"CastShadow", "CanCollide", "CanQuery", "CanTouch"} do
	BoundaryPart[CanProperties] = false
end
BoundaryPart.Parent = workspace

local Boundary = Boundaries.CreateBoundaryFromPart(BoundaryPart, "BoundaryOne")
Boundary:TrackGroups("Players")
--Boundary:UntrackGroups("Players")
--Boundary:Destroy()

local Players = game:GetService("Players")

local function OnPlayerAdded(Player: Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	Boundaries.TrackPart(HumanoidRootPart, {"Players"}, Player)
	--Boundaries.UntrackPart(HumanoidRootPart)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, Player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, Player)
end

Boundaries.OnEntered("Players", function(Boundary, TrackedPart, CallbackData, IsFirstBoundary)
	print(`{TrackedPart.Name} has entered {Boundary.Name} with data: {CallbackData}...`)
	print(IsFirstBoundary and "Hasn't been in this boundary group before." or "Has already been in this boundary group before.")
end)
Boundaries.OnExited("Players", function(Boundary, TrackedPart, CallbackData, IsLastBoundary)
	print(`{TrackedPart.Name} has entered {Boundary.Name} with data: {CallbackData}...`)
	print(IsLastBoundary and "Has left this boundary group entirely." or "Hasn't left this boundary group entirely.")
end)

Boundaries.EnableCollisionDetection()
--Boundaries.DisableCollisionDetection()
```
:::