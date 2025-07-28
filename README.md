# Boundaries
Create dynamic spatial boundaries using Bounding Volume Hierarchy (BVH) with Morton codes for efficient collision detection and boundary management.

## API
### Create Boundaries
```luau
Boundaries.CreateBoundary(Shape, Name, CF, Size, Part?)
```
Creates a new boundary with the specified parameters.
#### Parameters:
- `Shape ["Block" | "Ball"]` - Shape of the boundary
- `Name [string]` - Boundary name
- `CF [CFrame]` - Boundary position & orientation
- `Size [Vector3]` - Boundary size
- `Part [BasePart?]` - *Optional* associated part
#### Returns:
`CreatedBoundary [Dictionary]` Methods:
- `:TrackGroups(...string)` - Groups to track
- `:UntrackGroups(...string)` - Groups to remove
- `:Destroy()` - Remove the boundary
```luau
Boundaries.CreateBoundaryFromPart(Part, Name?)
```
Creates a new boundary from an existing BasePart.
#### Parameters:
- `Part [BasePart]` - Associated part
- `Name [string?]` - *Optional* boundary name
#### Returns:
`CreatedBoundary [Dictionary]` Methods:
- `:TrackGroups(...string)` - Groups to track
- `:UntrackGroups(...string)` - Groups to remove
- `:Destroy()` - Remove the boundary
---
### Track & Untrack Parts
```luau
Boundaries.TrackPart(Part, Groups, CallbackData?)
```
Begins tracking a part for boundary detection.
#### Parameters:
- `Part [BasePart]` - Part to track
- `Groups [{string}]` - Array of group names
- `CallbackData [any]` - *Optional* data passed to callbacks
```luau
Boundaries.UntrackPart(Part)
```
Stops tracking a part for boundary detection.
#### Parameters:
- `Part [BasePart]` - Part to track
---
### Assign & Unassign Groups
```luau
Boundaries.AssignGroups(Part, ...string)
```
Add additional groups to a tracked part.
#### Parameters:
- `Part [BasePart]` - Tracked part
- `... [string]` - One or more group names
```luau
Boundaries.UnassignGroups(Part, ...string)
```
Remove additional groups from a tracked part.
#### Parameters:
- `Part [BasePart]` - Tracked part
- `... [string]` - One or more group names
---
### Events
```luau
Boundaries.OnEntered(Group, Callback)
```
Register a callback for when tracked parts enter boundaries.
#### Parameters:
- `Group [string]` - Group name to listen for
- `Callback [(Boundary, TrackedPart, CallbackData?) -> ()]` - Function to call
#### Returns:
`Function [() -> ()]` - Disconnect function
```luau
Boundaries.OnExited(Group, Callback)
```
Register a callback for when tracked parts exit boundaries.
#### Parameters:
- `Group [string]` - Group name to listen for
- `Callback [(Boundary, TrackedPart, CallbackData?) -> ()]` - Function to call
#### Returns:
`Function [() -> ()]` - Disconnect function

## Example
```luau
-- TODO: Incomplete
```

## Credits
Inspired by [QuickBounds](https://github.com/unityjaeger/QuickBounds) by @unityjaeger
