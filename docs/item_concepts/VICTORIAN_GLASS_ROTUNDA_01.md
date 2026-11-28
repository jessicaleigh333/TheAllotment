# Victorian Glass Rotunda Conservatory — design concept for The Allotment

**Request ID:** `victorian-glass-rotunda-01`  
**Suggested permanent item ID:** `victorian_glass_rotunda_01` (check conflicts before publication)  
**Category:** Buildings / Greenhouses / Victorian Conservatories  
**Status:** Owner-provided inspiration, draft concept for review; **not implemented** in Godot/3D/runtime inventory.

## Source and artwork
- **Inspiration:** user screenshot shared November 17, 2026, labeled by seller as entrance to an abandoned greenhouse in France; contains ornamental iron doors opened into a glazed domed rotunda, circular upper lantern and red-and-cream checkerboard tile. No measurements in image. The original building may be larger than the visible rotunda.
- **Structural reference:** https://drive.google.com/file/d/15dOTAjHut45W5MUzxcod_DFlIZ_PQvgP/view
- **Isolated shop artwork:** https://drive.google.com/file/d/1BQ30_M5o6mW1w9foN6R5Gw1gIz1rEroP/view
- **Spreadsheet:** https://docs.google.com/spreadsheets/d/1XlA0-MiOi2xq8rGziCxw-AQM7CfUrEIdKP_uDteItx4/edit → `New Item Requests` and `Structure Design Specs`.

The two concept artworks are separate cropped outputs and are **design references**, not scale-accurate CAD, current working Godot textures, or proof of any existing functionality.

## Key visual features
1. A circular or many-sided plan, glazed vertical walls with repetitive narrow mullions and arched upper windows.
2. A wide glazed shallow domed roof with radial curved roof ribs.
3. A pronounced central **raised round clerestory/lantern** ring, giving the appearance of an oculus from below. The reference appears to show glass panes above; **do not assume an unglazed hole**.
4. Tall, ornate double wrought-iron entrance gates with scrolls, aging/patina, lower solid panels and functioning-looking hinges.
5. Terracotta-and-cream diamond/checkerboard tiled floor; low stone/brick base.
6. The illustration includes a central basin/fountain. This should be a **separate optional game prop**, not baked into the main rotunda model. Planter pots, vines, fairy lights and vegetation are shop dressing only.

## Proposed game measurements (not derived as facts from the photograph)
- Exterior diameter: **9.8 m / 32 ft**.
- Overall height: **about 7.9 m / 26 ft**.
- Raised upper lantern diameter: **about 4.3 m / 14 ft**, height above dome **about 1.8 m / 6 ft**.
- Approximate walkable floor area if a full 9.1 m / 30 ft interior circle: ~65.0 m² / ~707 ft². This is geometry-derived and depends on actual wall thickness and platform geometry.
- Entrance: double doors, target clear opening **1.8–2.4 m / 6–8 ft**; exact figure needs avatar collision checks.
- Curvature, plinth, wall height, dome springline and lantern geometry need a coherent dimensioned radial section designed before build. These are NOT structural engineering specifications.

## Modular Codex 3D guidance
- Build the rotunda from radial sectors/wedge bays rather than dozens of unique meshes.
- Share structural ring beams, vertical mullions, arched transoms, glass pane families, radial ribs, lantern glazing, hinge assemblies, ornamental railing/scroll panels, tiled-floor instancing and stone curb materials.
- Specify door clearances, collision boundary, exterior placement/plot footprint, readable transparencies and performance LOD; avoid glass sorting/z-fighting.
- Separate optional center furniture/fountain and surrounding foliage from structural geometry.
- Link the shop art as inventory illustration, and the dimensioned drawing as preliminary modeling reference.
- Do not silently substitute fantasy mechanisms, real-world engineering claims, new greenhouse climate effects, player access, price or ornamental interactions for working mechanics. Implement and test these in a future Codex branch if approved.

**Owner approval** of the final geometry and artwork remains pending. This design handoff changes no Godot scene, original source array, save data, or catalog export.
