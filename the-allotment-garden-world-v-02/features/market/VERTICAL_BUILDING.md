# Roman columns and vertical building

Fourteen original Roman-inspired building pieces are free in Shop → Decor. Search `Roman`, `shaft`, `capital` or `column`. The classical orders are interpreted as garden architecture, not presented as replicas of an excavated Roman monument.

| Piece | Width × height × depth, metres |
|---|---|
| Square plinth | 0.9 × 0.22 × 0.9 |
| Attic-style base | 0.85 × 0.28 × 0.85 |
| Plain shaft section | 0.6 × 1 × 0.6 |
| Fluted shaft section | 0.6 × 1 × 0.6 |
| Fluted half-shaft | 0.6 × 0.5 × 0.6 |
| Doric-style capital | 0.9 × 0.3 × 0.9 |
| Ionic-style capital | 1 × 0.4 × 0.8 |
| Corinthian-style capital | 1 × 0.6 × 1 |
| Complete Doric-style column | 0.9 × 3.2 × 0.9 |
| Complete Ionic-style column | 1 × 3.6 × 1 |
| Complete Corinthian-style column | 1 × 4 × 1 |
| Architrave beam | 3 × 0.35 × 0.8 |
| Cornice slab | 1.2 × 0.25 × 1.2 |
| Paneled pedestal | 0.8 × 1 × 0.8 |

Shapes include closed flat shaft ends, actual fluted profiles, torus/scotia moldings, scroll volutes, lobed carved acanthus leaves, molded abaci, dentils and relief panels. Sizes are fitted and tested against live meshes. Three shared distance-detail variants and simple collision are used, with original SVG Shop icons. Original implementation: `assets/garden_art/roman_collection.gd`.

## Build in the game

1. Choose a plinth or complete column in Shop → Decor, then choose the inner circle or Garden 01.
2. Place it on clear ground. Roman pieces start with **Stack: on**. Toggle the button or press **T** to switch ground/stack behavior.
3. Choose a base, shaft or capital. Point at a compatible flat top: the ghost snaps onto it at its real height. Green means supported and clear; red means it cannot be placed there. Click to add it. Repeat shaft sections for more height.
4. Place two equal-height columns roughly 2.4 m apart. Choose the 3 m architrave beam and point at one top; the beam aligns between compatible level supports. Both end contact points must be supported. A sufficiently broad continuous top can also carry it.
5. Flat wide tops retain the picked horizontal position on a 0.1 m alignment grid, so several pieces can be built above a beam. Narrow column tops center the new piece. Columns, pedestals and the existing stone-end pier provide compatible flat supports. Suitable pots and sculptures can be placed on them. Open vessels, plants, gates and roofs are not universal building surfaces.

R rotates. WASD pans, the wheel zooms, and **View ↑ / View ↓** raise/lower the camera. The camera follows the newly placed top. This moves the view, not a piece into unsupported air. Roman placement opens closer to the building area. Done/Esc restores the previous view. Every elevated piece still respects the area's protected route/terrain footprint.

Example: plinth + base + two 1 m shafts + Corinthian capital = 3.1 m. Two such columns support a beam at 3.1 m. The existing muse bust on the beam reaches 5.15 m. `staging/roman_building_showcase.tscn` (F6) browses all pieces and includes **Show stacked colonnade** using the same dimensions and support rules.

## Saving, retrieval and limits

Existing version-1 ground records remain readable. Old records gain stable placement IDs and sampled ground height when placement is opened. New optional `elevation`, `supports` and `ground_y` fields preserve height and support relationships; ground placements default to zero elevation. IDs are random placement identifiers, not account credentials. The existing local profile isolation and atomic save writes are retained. Use this updated build to display elevated saves; older builds do not know how to render elevation.

Support checks use the declared flat contact shapes and actual top heights. Cycles, missing/duplicate/foreign supports, invalid numbers, unsupported positions and out-of-order dependencies are rejected. Two-dimensional overlaps on the same level are tested in the actual rotated horizontal model bounds for elevated pieces; disjoint height intervals can occupy the same horizontal position. Existing ground placement rules stay in force.

Remove upper pieces first through Backpack → placed items. A support cannot be returned to the bag while another piece depends on it. The placed list shows height and lists upper pieces first; the per-item return action searches newest placements first. Remaining pieces retain their stable IDs when an array index changes.

Buildings may reach 24 m above their sampled ground surface; each piece's top must fit this limit. The existing 500-piece save limit remains. Support is geometric assembly snapping, not a gravity, fracture, engineering-load or structural-stability simulation. Arbitrary floating placement, leaning/tilting and growth inside pots are outside this change. Terrain, grass, stone paths and acreage are unchanged.

## Verification and art status

`tests/verify_vertical_building.gd` covers all 14 models/icons/metre bounds; a supported 12-piece showcase; legacy IDs/ground migration; stacked placement and save restoration; actual top ray picking; wide-surface building; two-column beam alignment; same-level overlap and unsupported/cyclic/foreign/malformed rejection; 24 m limits; dependency-safe retrieval; and walking under the built beam. The shared mesh audit covers 93 asset/stage combinations and three LODs, each base variant under 40k triangles. Market, courtyard, plant growth, French collection, original walls/gates and sidewalk regressions are run, plus import and real game renders.

Test environment is Godot 4.6.3 Compatibility/Mesa; owner's Godot 4.7.2 was not run here. The new Roman art is integrated and ready for owner visual review before final art sign-off under AGENTS.md.
