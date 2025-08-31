---
next:
  text: 'Resources'
  link: '/resources/troubleshooting'
outline: 2
---

# Functions {#1}

## .EnableCollisionDetection()
Starts the boundary collision detection, enabling registered callbacks to trigger.
```luau:no-line-numbers
Boundaries.EnableCollisionDetection()
```

## .DisableCollisionDetection()
Stops the boundary collision detection, preventing registered callbacks from triggering.
```luau:no-line-numbers
Boundaries.DisableCollisionDetection()
```

## .SetFrameBudgetMillis()
Sets the time budget for collision detection per frame. Processing is distributed across multiple frames when near the budget.
```luau:no-line-numbers
Boundaries.SetFrameBudgetMillis(Value: number)
```
### Parameters
- `Value` - The maximum time in milliseconds to spend on collision detection per frame.<br>(Default: 0.2 ms)
> [!IMPORTANT] Frame Budget Suggestion
> The frame budget doesn't account for callback completion time, thus it's recommended to keep the budget below 0.5 ms and monitor performance.
>
> Detection speed depends on the budget, the number of tracked parts, and the boundaries. A lower budget spreads the work across more frames, whereas a higher budget processes more per frame, potentially increasing CPU time. It's a trade-off between speed and performance, and in most scenarios, the perceived delay is negligible.

## .CreateBoundary()
Creates a boundary for collision detection and returns a table to manage it.
```luau:no-line-numbers
Boundaries.CreateBoundary(
	Shape: _Shape,
	Name: string,
	CF: CFrame,
	Size: Vector3,
	Part: BasePart?
): _Boundary
```
### Parameters
- `Shape` - The shape of the boundary.
- `Name` - A name for the boundary.
- `CF` - The `CFrame` of the boundary.
- `Size` - The size of the boundary.
- `Part` - Optional `BasePart` to associate with the boundary.
### Returns
- `_Boundary` - A table containing methods to manage the boundary.

## .CreateBoundaryFromPart()
Creates a boundary using an existing part for collision detection and returns a table to manage it.
```luau:no-line-numbers
Boundaries.CreateBoundaryFromPart(
	Part: BasePart,
	Name: string?
): _Boundary
```
### Parameters
- `Part` - A `BasePart` to associate with the boundary.
- `Name` - Optional name for the boundary.<br>(Default: `Part.Name`)
### Returns
- `_Boundary` - A table containing methods to manage the boundary.

## .TrackPart()
Registers a part for boundary collision detection.
```luau:no-line-numbers
Boundaries.TrackPart(
	Part: BasePart,
	Groups: {string},
	CallbackData: any
)
```
### Parameters
- `Part` - A `BasePart` to track.
- `Groups` - An array of group names to assign.
- `CallbackData` - Optional custom data to associate with the part.
> [!NOTE] Tracked Part Removal
> Tracked parts are automatically untracked when destroyed, so manual cleanup isn't necessary. If the part is inside a boundary during automatic removal, the [.OnExited()](#onexited) callback will be triggered.

## .UntrackPart()
Deregisters a part from boundary collision detection.
```luau:no-line-numbers
Boundaries.UntrackPart(Part: BasePart)
```
### Parameters
- `Part` - The `BasePart` to untrack.

## .GetBoundariesContainingPart()
Gets all boundaries where the part is currently detected inside.
```luau:no-line-numbers
Boundaries.GetBoundariesContainingPart(
	Part: BasePart
): {_BoundaryProperties}
```
### Parameters
- `Part` - A `BasePart` that has been registered for tracking.
### Returns
- `{_BoundaryProperties}` - An array of all boundaries containing the part, or an empty array if untracked.

## .AssignGroups()
Assigns the part with the specified groups.
```luau:no-line-numbers
Boundaries.AssignGroups(Part: BasePart, ...: string)
```
### Parameters
- `Part` - A `BasePart` that has been registered for tracking.
- `...` - One or more group names to add the part to.

## .UnassignGroups()
Unassigns the part from the specified groups.
```luau:no-line-numbers
Boundaries.UnassignGroups(Part: BasePart, ...: string)
```
### Parameters
- `Part` - A `BasePart` that has been registered for tracking.
- `...` - One or more group names to remove the part from.

## .IsPartInGroups()
Checks if the part is assigned to the specified groups.
```luau:no-line-numbers
Boundaries.IsPartInGroups(Part: BasePart, ...: string): ...boolean
```
### Parameters
- `Part` - A `BasePart` that has been registered for tracking.
- `...` - One or more group names to check for the part.
### Returns
- `...boolean` - One boolean for each group name passed, indicating whether the part is assigned to that group.

## .GetPartGroups()
Gets all groups the part is currently assigned to.
```luau:no-line-numbers
Boundaries.GetPartGroups(Part: BasePart): {string}
```
### Parameters
- `Part` - A `BasePart` that has been registered for tracking.
### Returns
- `{string}` - An array of all groups the part is assigned to, or an empty array if untracked.

## .OnEntered()
Registers a callback for when a part assigned to the specified group enters a boundary.
```luau:no-line-numbers
Boundaries.OnEntered(Group: string, Callback: _EnteredCallback): () -> ()
```
### Parameters
- `Group` - Group to detect collisions for.
- `Callback` - A function to handle upon a collision occurring.
### Returns
- `() -> ()` - A disconnect function to remove the callback.

## .OnExited()
Registers a callback for when a part assigned to the specified group exits a boundary.
```luau:no-line-numbers
Boundaries.OnExited(Group: string, Callback: _ExitedCallback): () -> ()
```
### Parameters
- `Group` - Group to detect collisions for.
- `Callback` - A function to handle upon a collision occurring.
### Returns
- `() -> ()` - A disconnect function to remove the callback.