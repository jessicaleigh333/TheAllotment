# Testing ground covers

Run these commands from the Godot project directory (where `project.godot` lives):

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/verify_ground_cover.gd
godot --headless --script res://tests/verify_editor_interaction.gd
godot --headless --script res://tests/verify_layouts.gd
godot --headless --script res://ui/verify_hud.gd
```

For a graphical shader/lighting check (not headless), run:

```sh
godot --script res://tests/verify_ground_cover_rendering.gd
```

This verifies pixel brightness for ordinary versus emissive surfaces at night, verifies that lighting changes do not alter placement data, and captures the daytime workshop, nighttime workshop and color-wheel UI under `user://`.

Use a writable Godot user-data/cache directory in restricted environments. Tests use temporary, separately named save files and remove those files after passing. The main-world integration tests do not save test paint into the player's garden file.

## Automated coverage

- 83 catalog entries, all seven categories, starter collection, search, thumbnails and normalized material caching.
- Surface, grout, accent and glow colors; finish; directional rotation; independent metallic borders; saved colors and combinations.
- Brush/straight path/curved path/circle/rectangle placement, erasing and recoloring.
- Full-cell plot constraints, structure exclusion and protected shared hedge boundaries.
- Actual sloped terrain height/UV consistency and real-wedge confinement.
- One operation for a drag stroke, cancel/undo/redo, loading as an undoable operation and restoration after revoking permission mid-stroke.
- Save roundtrip, invalid colors/cells, different plot/owner/seed rejection, and atomic rejection without partial scene changes.
- Actual viewport-dispatched mouse gestures, release over the sidebar, curve completion with Enter and editing-state cleanup.
- Day/night uniform updates and lighting controls without changing daytime color.
- Original nine 1.84-acre wedges, hedges, staging slots, camera reset and all HUD destinations.

## Manual daylight checklist

1. Run `main.tscn`, click the trowel, and paint cobblestone in Garden 01.
2. Attempt painting across a hedge, inside another garden, or over a bed/shed. Those cells must be skipped; no structure should be removed or moved.
3. Choose Brick; edit Surface to a red HEX value and Grout to cream. Rotate it 45 degrees, vary roughness, and place a straight path.
4. Choose Curve, click three or more points and finish with Enter. Try different path widths. Cancel another curve with Escape.
5. Place a circle and a rectangle. Add a tile border with a different color, then try no edging.
6. Select Sample on an existing patch. Change its colors and use Recolor; its material should remain the same. Restore defaults and replace a small area with Moss.
7. Erase an area. Undo and redo each operation, including a long brush drag ending over the sidebar.
8. Save. Change/erase a patch, then Load. Undo the load and redo it. Exit/reopen the scene and verify the saved patch loads when the editor opens.
9. Save a color and a material/color combination. Restart the editor and select both favorites.
10. Run `staging/ground_cover_demo.tscn` and inspect the shared patterns on its sloped ground. Surfaces should follow the slope and retain consistent texture scale.

## Manual night checklist

1. Run `staging/ground_cover_night.tscn` or press N in the daytime workshop.
2. Compare glow pebbles, stepping stones, luminous inlay, mixed gravel accents, the separate illuminated border and the luminous trail.
3. Scroll the editor sidebar to Luminous details. Change the primary and secondary glow colors using the color wheel or HEX field; choose two-color mixing or rainbow.
4. Try blue, turquoise, green, purple, pink, gold and white presets. Change intensity from subtle to bright.
5. Turn glow off and on. Try whole surface, grout, edges, embedded patterns and scattered stones. Use Recolor to update an existing patch rather than only the preview.
6. Give the border a separate glow color/intensity; toggle its glow off independently.
7. Move the day/night slider gradually. Daytime color must remain independent while emission increases at night.

Godot Compatibility renders emission but does not implement bloom or emission-driven lighting of surrounding objects. The system preserves color in that renderer without spawning expensive stone lights. Forward+/Mobile bloom requires supported hardware/renderer validation and is not part of the verified Compatibility result.

## Visual review

Day and night images were captured from the running workshop with the actual material shader and UI. The procedural surfaces and flush borders are functional first-pass artwork. Evaluate close-up detail and approve/refine the art before calling the catalog visually final. The main full-neighborhood overview is intentionally far away; use the editor camera or workshop for surface review.
