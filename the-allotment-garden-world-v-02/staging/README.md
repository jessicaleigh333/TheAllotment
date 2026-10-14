# Asset staging grid

Open `staging/asset_staging.tscn` and press F6 to preview walls and other assets separately from the game. F5 runs the permanent circular game layout with its detailed navigation buttons.

The original grid terrain, stone paths, sample gardens and park are preserved by inheriting `scripts/world.gd`. Nine editable Node3D slots under `AssetSlots` align with the nine grid bays. Instance a wall or other asset scene under a slot in the editor; at runtime that bay's sample garden automatically hides. An empty slot continues showing its sample garden. Slots use the existing prototype scale; keep assets within the 18×18 bay for clear comparisons. Position larger landmarks across several bays as needed.

There are no new wall prototypes in this change. This scene prepares their review area. Staging has its own explanatory overlay and no game navigation. WASD/arrows pan, Q/E rotate, right-drag orbits, wheel zooms, and R resets the camera.

Main layout logic lives in `scripts/courtyard_world.gd`: nine non-overlapping annular wedge gardens, each 1.84 acres (7,446.22 m²), shared green hedge dividers with no radial paths between gardens, inward-facing entrances at a radius of 32 metres and paths to a 26-metre-radius shared stone courtyard. The existing planted centerpiece is reused. This implements the approved layout; the current garden models, collision/player navigation and fountain artwork still need future work.

Validation: Godot 4.6.3 import and startup, all twelve HUD destinations, and `tests/verify_layouts.gd` passed. The layout test checks actual triangle-mesh acreage, wedge bounds and separation, plot count, inward-facing entrances, camera reset and staging replacement behavior.
