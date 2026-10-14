# Open the updated game in Godot

1. Extract the ZIP into a NEW folder so it is easy to distinguish from older copies.
2. In Godot Project Manager choose Import, select this folder's project.godot, then Import & Edit. Wait for the first import to finish.
3. In the editor's FileSystem panel double-click main.tscn and press F6 (Run Current Scene) to enter the garden directly.

For the avatar workshop, open features/avatar/screen.tscn and press F6 instead. It remains separate from the main menu.

F5 runs the welcome-flow preview: select Find a neighborhood or use the demo code BLOOM-0001 to enter the game.

The editor viewport may look empty: the neighborhood, character and interfaces are created when the scene runs. Workspace changes do not automatically update a separate copy on your computer. Two identical titles in Project Manager can point to different folders; import this newly extracted folder for this version.

Controls: WASD/arrows stroll; Shift faster; right-drag or Q/E camera; mouse wheel zoom; Tab neighborhood overview.

This update contains the revised hat, slimmer sleeves/arms, shared texture maps, continuous sculpted face, improved hair fitting and natural image-based lighting. Gameplay and appearance tests pass in Godot 4.6.3. Final character artwork is still under visual review.

Free-resource sources, verified licenses and ready-to-copy credits: CREDITS.md. Technical preview and tests: features/avatar/README.md and TESTING.md. No Blender installation or internet connection is required to play; the rigged GLB and textures are included.
