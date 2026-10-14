# Ground cover & pathway editor

A functioning local Godot 4.6 editor, integrated into the main world's trowel button. This is not the previous placeholder panel. Edits change the live terrain overlay, save to disk, and support undo/redo.

## Preview

Actual in-game captures: [daytime workshop](previews/ground-cover-day.png), [nighttime workshop](previews/ground-cover-night.png), and [color customization](previews/ground-cover-customization.png).

1. Open `project.godot` in Godot 4.6 or later and press F5. Continue through the welcome-flow preview, then use **Find a neighborhood** or the demo code **BLOOM-0001**.
2. Click the **trowel / Garden Editor** icon. This opens the explicitly labeled local demo scope for Garden 01 and moves the camera into it. No account ownership or live multiplayer claims are created.
3. For a direct preview, open `main.tscn` and press F6, then click the trowel.
4. For a workshop containing eight starter surfaces, layered inlay, separate edging and a luminous trail, run `staging/ground_cover_demo.tscn` with F6. Run `staging/ground_cover_night.tscn` for the nighttime version. The workshop ground is sloped to demonstrate terrain conformity. Press **N** to toggle day/night there, or use the sidebar's day/night slider.

The original square asset-staging grid and permanent nine 1.84-acre wedge gardens remain intact. The surface workshop is a separate staging scene. In the workshop, **Return to garden** returns to the main world.

## Editing

- **Paint:** drag the brush on the ground. Brush diameter is measured in metres. A continuous stroke is one undo action, including when the mouse is released over the sidebar.
- **Line:** click its start and end. Path width is independent from brush size.
- **Curve:** click control points, then Enter or **Finish curve**. The points define a baked cubic curve, with rounded rasterized joins. Escape cancels the pending shape.
- **Circle:** click its center and outer edge.
- **Rectangle:** click opposite patio corners.
- **Erase:** drag to remove ground-cover cells; the original terrain is revealed.
- **Recolor:** drag over already placed surfaces. Their material identities and pattern scale are retained; the selected colors, finish, brightness, saturation, glow and layered details are applied.
- **Sample:** click a placed surface to copy its full appearance into the controls. Change it, then recolor or paint to replace.
- **Undo / Redo:** toolbar or Ctrl+Z / Ctrl+Shift+Z / Ctrl+Y. History retains 64 committed operations. A load is also undoable. History is intentionally not restored from disk.
- **Save / Load:** toolbar or Ctrl+S. Saving is explicit. Pending uncommitted shapes are cancelled before history/save actions. Existing saves automatically load when the main-world editor first opens. The workshop always starts with its demonstration layout; use Load to restore your saved workshop edits.
- Right-drag orbits; WASD/arrows pan; Q/E rotate; wheel zooms. Camera keyboard movement pauses while a text field has focus. Escape cancels an active gesture or returns to the garden.

No other garden is touched. Placement validates the entire cell footprint against the selected plot, reserves shared hedge boundaries, and skips protected structure footprints. Painting does not alter any underlying terrain, plant, building or path mesh.

## Catalog and appearance controls

There are **83 selectable ground-cover definitions** across all seven requested categories, plus a separate metallic edging definition:

| Category | Entries |
| --- | ---: |
| Stone & Cobblestone | 15 |
| Brick & Terracotta | 9 |
| Decorative Tiles | 14 |
| Natural Ground Covers | 15 |
| Wood & Rustic Surfaces | 7 |
| Ornamental & Specialty Surfaces | 9 |
| Luminous Garden Materials | 14 |

The starter collection provides cobblestone, brick, moss, gravel, basic tile, ornate tile, glowing pebbles and glowing stepping stones. Categories and search expose the rest. Catalog thumbnails and the selected material preview render the actual shared material shader on small 3D tiles. They render once, refreshing on selection/appearance/lighting changes, instead of running 83 continuously updating cameras.

Each entry is a usable procedural preset, rather than a disconnected model or an unavailable menu item. The 27 shader profiles include rounded cobble, irregular flagstone, fan paving, running bond, herringbone-inspired brick, basketweave-inspired brick, circular paving, square/hex/octagonal tiles, checkerboard, floral/compass/star/mosaic patterns, wood grain and rounds, moss, clover/meadow/leaf details, gravel, stepping stones, crescents and crystal facets. Presets reuse geometry and shader code; these are art prototypes, not final historically verified surface assets.

The color wheel uses Godot's OKHSL circle and includes HEX entry. The component selector independently edits daytime surface, grout/mortar, pattern/accent, primary glow and secondary glow colors. Palettes, brightness, saturation, roughness/finish, tile scale, directional rotation, saved favorite colors, saved combinations and Restore defaults are functional. Every saved color is available in the favorites selector; recent colors also appear as swatches.

Luminous controls include on/off, independent intensity, any primary/secondary color, two-color mixing, rainbow, and named blue/turquoise/green/purple/pink/gold/white/rainbow presets. Glow scopes are selected details, whole surface, soft edges, grout, embedded patterns or scattered stones. Daytime color is independent from night emission. The shader blends between low daytime emission and nighttime luminosity as the day/night driver changes.

Layered details add moss-filled joints, selected luminous pebbles or ornate inlays without changing the base material. Their accent colors are editable. For green moss-filled joints, choose a green accent/joint color.

Borders include brick, stone, cobblestone, tile, timber, metallic edging, glowing stone, illuminated mosaic and no edging. Color, width, glow color, intensity and glow on/off are independent of the main surface. These are flush ground strips, not raised 3D curb/wall models. The Compatibility shader keeps emissive colors readable using a bounded emission response. Forward+/Mobile paths preserve HDR emission and enable environment bloom when supported. The project's renderer has not been switched.

## Architecture

| File | Responsibility |
| --- | --- |
| `ground_cover/catalog.json` | Versioned catalog data and border data |
| `ground_cover/surface_definition.gd` | Reusable Resource definition |
| `ground_cover/catalog.gd` | Loading, style validation, shared shader-material cache |
| `ground_cover/surface.gdshader` | Tileable patterns, surface grain/normal detail, recoloring, layering and emission |
| `ground_cover/terrain_adapter.gd` | Existing wedge-mesh height/ray sampling and structure/hedge protection |
| `ground_cover/surface_store.gd` | Owner-scoped cell state, shapes, transactions, batching and persistence |
| `ground_cover/material_preview.gd` | On-demand 3D thumbnail/preview rendering |
| `ground_cover/favorites.gd` | Favorite colors and normalized combinations |
| `editor_panel.gd` / `screen.tscn` | Scrollable editing UI |
| `editor_session.gd` | Input, curve baking, live placement preview and world integration |
| `day_night.gd` | Lighting, backdrop tint and emissive material updates |
| `staging/ground_cover_demo.gd` | Editable sloped daytime/nighttime workshop |

One world unit is one metre. Editing uses **0.5 m cells**. Shape edges therefore have half-metre raster precision, rather than freeform sub-centimetre precision. Tile UVs are anchored in garden-local metres and continue across chunk boundaries; resizing a brush does not stretch the material. Gentle feathering on outer cell edges blends natural surfaces into the original ground. Surfaces use a 2.5 cm terrain-following offset, with normals sampled from the height function. They do not require a mesh or a light per stone.

Rendering batches matching styles within 16×16-cell chunks (8×8 m). Only affected chunks and adjoining edge chunks rebuild. Normalized material instances are reused. A garden has a 60,000-cell limit, sufficient for its full 1.84-acre footprint at the current resolution. Large previews/shapes are clipped to the scope before rasterization. Highly fragmented color combinations increase draw calls; no production multiplayer/mobile stress benchmark is claimed.

The terrain adapter currently handles the main world's unindexed wedge ground mesh and BoxMesh structure footprints. Shared hedge boundaries are reserved on both sides. It supports sloped triangles and ray picking, and the store accepts alternate height/contains callbacks and protected Rect2 regions for future terrain/asset systems. An arbitrary imported/landscaped terrain system must supply the corresponding adapter and obstruction updates.

## Ownership, persistence and future synchronization

Every store is configured with a context ID, owner, acting player and saved world seed. Paint, erase, recolor, undo, redo, save and load require matching actor/owner IDs. The current integration deliberately supplies **local-demo** only to Garden 01. This is a local development sandbox, not account authentication or server-enforced ownership.

`operation_committed` emits context, actor, seed, monotonically increasing revision and changed normalized cell records. This gives a future multiplayer adapter a small logical change set instead of scene-tree geometry to synchronize. The server will still need to validate identity/ownership, revisions and placement bounds; an untrusted client must not be allowed to assign its own owner ID. Network transport, authoritative claiming and remote replay are not implemented.

Saves use a versioned JSON schema with context/owner/seed/cell size, a deduplicated style table and integer cell/style records. Writes go through a flushed temporary file and rename. Loads validate the entire snapshot before modifying any cell; malformed data, changed seed, different ownership, unknown materials, protected footprints or out-of-plot cells are rejected atomically. A failed load leaves current edits intact.

Main garden save: `user://ground_cover/local_demo_neighborhood_garden_01.json`.
Workshop save: `user://ground_cover/workshop_demo.json`.
Favorite colors/combinations: `user://ground_cover/favorites.json`.

The day/night node can be driven manually via `set_night_amount(0..1)` or run automatically with `cycle_enabled = true` and `cycle_duration_seconds`. It updates registered catalogs and existing lighting, with no per-stone lights. It does not randomize or regenerate the garden.

## Extending the catalog

Add an entry to `catalog.json` with a stable unique ID, display name, category, existing profile number, variant, metre-based scale, daytime base/joint/accent colors, roughness and natural/luminous flags. Existing save IDs must remain stable. New entries appear in their category and search automatically and use the same customization, placement, persistence and thumbnails.

For a new pattern family, add its shader profile and a corresponding catalog entry. For sculpted surface details or new imported terrain, add the dedicated asset/adapter without replacing the logical cell store. Do not add one separate scene per recolor.

## Validation and remaining work

Test commands and a manual checklist are in `TESTING.md`. Verified on Godot 4.6.3 with the Compatibility renderer and Mesa software rendering. Behavioral tests cover ownership, bounds, structure protection, slope conformity, all shape types, whole strokes, undo/redo, save roundtrip/rejection, color/glow state, favorites, UI interactions, catalog browsing, curve Enter, mouse release over UI, and the existing layout/HUD.

Completed: the functional catalog architecture, eight starter surfaces, expanded procedural catalog, live material/glow customization, all editing tools, flush borders and transitions, mixing, favorites, persistence, transaction history, main-world entry, and a day/night workshop.

Remaining: final artist-approved surface textures/sculpted details, actual tall vegetation/raised curbs/3D crystal detail, production LOD/performance tuning and mobile verification, authoritative multiplayer/account ownership, and integration with future terrain/obstruction services. Forward+/Mobile bloom could not be validated on the available Compatibility setup. The ground-cover system itself has no growth/trampling physics. Night emission does not dynamically illuminate surrounding objects on Compatibility; no costly stone lights are substituted.
