# Character and appearance testing

Use Godot 4.6+. Import the project first:

```sh
godot --headless --editor --import --quit
godot --headless --path . --script tests/verify_avatar.gd
```

The avatar test checks saved appearance round trips, malformed input, all modular visibility combinations, actual face/eye/nose morph values, shared detail maps with independent dyes for cloth/hair/leather/skin/eyes, map-preserving recolor, slim arm/sleeve bounds, independent character materials, rig bindings, animated walk pose changes and calf/foot boot weighting, idle/walk animations, floor grounding, movement, UI/editor/overview pauses, all nine entrance routes, hedge collision and respawn. It uses a separate temporary save, preserving the player's appearance.

Regression checks:

```sh
godot --headless --path . --script tests/verify_layouts.gd
godot --headless --path . --script ui/verify_hud.gd
godot --headless --path . --script tests/verify_ground_cover.gd
godot --headless --path . --script tests/verify_editor_interaction.gd
godot --headless --path . --script tests/verify_weather.gd
```

Manual visual checks:

1. Run `features/avatar/screen.tscn` with F6. Try every hair/outfit, toggles, colors and face/body sliders. Turn around and switch idle/walk. Check clothing coverage, hat flowers and solid underside of the brim. Inspect woven cloth, embroidery, hair strands, leather grain, complexion and iris detail. Confirm the slimmer sleeves and gentle face.
2. Save a visibly different look, enter the garden and confirm it is used. Restart the scene and confirm persistence. Restore the original look and save to return to defaults.
3. Walk through each gate and against hedges/structures. Tab to the overview and back. Open weather and the editor; ensure movement pauses and camera input still works afterward.
4. Verify the nine wedge gardens, courtyard, existing navigation icons and separate grid staging remain available.

Automated checks exercise local gameplay only. They do not validate final artwork, multiplayer permissions, mobile controls, production performance or account services.

Verification on Godot 4.6.3 Compatibility: avatar, layout, HUD, weather, ground-cover and editor-interaction assertions passed. Native avatar/workshop and in-game captures rendered successfully. Avatar material overrides now release before mesh teardown; the prior null-material warnings no longer reproduce in layout/weather checks. Software-rendered X11 reports unavailable V-Sync. Final artwork, hardware performance and multiplayer remain outside these checks.
