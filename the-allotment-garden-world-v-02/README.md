# The Allotment — Garden prototype

Open this folder's `project.godot` in Godot 4.6+. F5 starts the welcome-flow preview; Find a neighborhood (or demo code BLOOM-0001) opens the permanent garden world. For a direct world preview, open `main.tscn` and press F6.

The 3D editor viewport can look empty: the neighborhood and avatar are generated when you run the scene. Press F6 with `main.tscn` open for the game, or with `features/avatar/screen.tscn` open for the separate avatar workshop. These files must be inside the project you imported; workspace edits do not automatically update a project on another computer.

The permanent world has nine 1.84-acre wedge gardens, shared hedge dividers, a circular courtyard, storybook background and detailed side-navigation icons. The trowel button opens a functioning local ground-cover/pathway editor for Garden 01.

Ground-cover system, controls, persistence, limitations and testing: [features/garden_editor/README.md](features/garden_editor/README.md) and [TESTING.md](features/garden_editor/TESTING.md).

Separate asset previews:

- `staging/asset_staging.tscn`: preserved grid with nine editable prototype slots.
- `staging/ground_cover_demo.tscn`: editable daytime material workshop on sloped ground.
- `staging/ground_cover_night.tscn`: the same workshop at night. N toggles day/night.

The game now starts with an animated, playable garden character. WASD/arrows stroll, Shift moves faster, right-drag or Q/E turns the camera, the wheel zooms, and Tab switches to the preserved neighborhood overview. Walking pauses while menus or the garden editor are open.

The separate avatar workshop is ready for development preview: open `features/avatar/screen.tscn` and press F6. It is intentionally not linked from the main menu yet. Hair, clothing, accessory, color, body and face controls update the real 3D model; saved appearance is used on the next garden entry. See [features/avatar/README.md](features/avatar/README.md) and [TESTING.md](features/avatar/TESTING.md).

This is local prototype gameplay. Live account login, legal terms, neighborhood-code services, garden claiming and authoritative multiplayer ownership are not connected. The welcome screen labels its preview state, and the editor labels its local demo scope. The weather icon opens a simulated neighborhood-weather module with the next five days. Other menu destinations remain placeholders.
