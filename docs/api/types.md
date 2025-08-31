---
outline: 2
---

# Types {#1}
::: info Syntax
Type declarations are internally prefixed with an underscore `_` to distinguish them from other variables. When importing, use the underscore:
```luau:no-line-numbers
type Boundary = Boundaries._Boundary
```
:::

## _Shape
```luau:no-line-numbers
"Block" | "Ball" | "Complex"
```

## _Boundary
```luau:no-line-numbers
{
	IsDestroyed: boolean,
	Index: number,
	-- Methods
	TrackGroups: (self, ...string) -> (),
	UntrackGroups: (self, ...string) -> (),
	Destroy: (self) -> (),
}
```
### Properties
- `IsDestroyed` - Whether the boundary has been destroyed.
- `Index` - Identifier for the boundary.
### Methods
- `TrackGroups` - Assigns the boundary to one or more groups.
- `UntrackGroups` - Unassigns the boundary from one or more groups.
- `Destroy` - Removes the boundary and frees up resources.
> [!NOTE] Boundary Part Removal
> Upon destroying a boundary, any associated part will remain. You must manually destroy the part if you want it removed. This only applies if you supplied a part when creating a boundary.

## _BoundaryProperties
```luau:no-line-numbers
{
	Name: string,
	Shape: _Shape,
	CFrame: CFrame,
	Position: Vector3,
	HalfSize: Vector3,
	Part: BasePart?,
	-- Ball
	Radius: number?,
}
```
### Properties
- `Name` - The name of the boundary.
- `Shape` - The shape of the boundary.
- `CFrame` - The `CFrame` of the boundary.
- `Position` - The 3D position of the boundary.
- `HalfSize` - The boundary's given size in half.
- `Part` - Associated `BasePart` of the boundary, `nil` if unspecified.
- `Radius` - The extents from center to edge for spherical shapes.

## _EnteredCallback
```luau:no-line-numbers
(
  Boundary: _BoundaryProperties,
  TrackedPart: BasePart,
  CallbackData: any,
  IsFirstBoundary: boolean
) -> ()
```
### Parameters
- `Boundary` - The boundary that was entered.
- `TrackedPart` - The `BasePart` that entered the boundary.
- `CallbackData` - Custom data provided when tracking a part, `nil` if unspecified.
- `IsFirstBoundary` - Is `true` if this is the first boundary the part has entered of its group.

## _ExitedCallback
```luau:no-line-numbers
(
  Boundary: _BoundaryProperties,
  TrackedPart: BasePart,
  CallbackData: any,
  IsLastBoundary: boolean
) -> ()
```
### Parameters
- `Boundary` - The boundary that was exited.
- `TrackedPart` - The `BasePart` that exited the boundary.
- `CallbackData` - Custom data provided when tracking a part, `nil` if unspecified.
- `IsLastBoundary` - Is `true` if this is the last boundary the part has exited of its group.