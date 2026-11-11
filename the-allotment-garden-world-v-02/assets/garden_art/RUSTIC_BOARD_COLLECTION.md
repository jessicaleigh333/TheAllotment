# Campsite board-inspired garden collection

The owner's two supplied Pinterest board screenshots are the visual references for this pack. They show woven willow planters with climbing cones, rustic branch trellises/obelisks/gates, a wooden quilt rack, fairy-lit garden paths, giant chessboards, an outdoor wooden bowling lane and a formal compartmented garden. This collection responds to those visible references; no claim is made to having accessed the live Pinterest boards. All meshes and thumbnail artwork are original interpretations. No screenshots or third-party product images are embedded in the game.

## Integrated free Decor inventory

| Item | Width × height × depth (m) |
|---|---|
| Woven-branch trellis | 2 × 2.2 × 0.4 |
| Twig climbing obelisk | 1.1 × 2.2 × 1.1 |
| Woven willow basket planter | 1.1 × 0.4 × 1.1 |
| Willow basket teepee planter | 1.1 × 2.2 × 1.1 |
| Rustic branch arbor | 2.6 × 2.8 × 0.8 |
| Opening twig garden gates | 2.4 × 1.7 × 0.45 |
| Woven branch fence | 2 × 1.2 × 0.35 |
| Wooden quilt-drying rack | 1.8 × 1.7 × 1.2 |
| Giant garden chess display | 4.8 × 0.7 × 4.8 |
| Grass/stone checkerboard insert | 4.8 × 0.025 × 4.8 |
| Backyard bowling display | 1.5 × 0.45 × 6 |
| Formal garden parterre module | 4.8 × 0.8 × 4.8 |
| Fairy-lit woodland arbor | 2.6 × 2.8 × 0.8 |

The pieces use curved branches, tapered crossbars, rope lashings, actual interlaced willow strands/stakes, an open soil-filled basket, shaped quilt patches, 32 turned/carved chess pieces, ten pins/two bowls, and planting compartments with clipped greenery and an open cross path. Garden chess uses alternating squares and a complete starting arrangement. The grass/stone checkerboard is a separate low stone insert: open squares reveal the existing lawn, so place it on grass.

## Find and use

Shop → Decor → search `Campsite` lists all 13 items. All use the existing free Backpack, rotation, placement, retrieval and local save system. Full metre bounds and footprint radii are validated. The gate automatically opens/closes as the gardener approaches/leaves; gate/fence ends use existing boundary connections. The arbor and parterre cross path remain walkable. Garden inserts do not replace or resize the neighborhood terrain, existing grass or stone paths.

The fairy-lit arbor reuses the established night material, soft halo and bounded light pool. Warm string bulbs light at night and follow the garden clock/day-night previews. Other wicker/wood pieces remain natural by day and moonlight-lit at night. The new light fixture uses the same reduced-motion behavior as the enchanted collection.

`staging/rustic_garden_showcase.tscn` (F6) browses all 13 with orbit/zoom, gate open/close and day/night controls. The full art gallery includes them too.

The chess and bowling sets are decorative garden displays; move validation, turns, scoring and bowling physics are not newly implemented minigames. The rack is a static quilt display. Basket soil, trellis greenery and parterre flowers are decorative; planting into a purchased basket or training live growth onto its cone is not a new mechanic in this pack. Flat inserts rely on the existing ground collision; small decorative board thickness does not introduce a curb that blocks walking.

## Validation and status

Original source is `rustic_collection.gd`; original SVG icons are in `icons/`. All pieces have shared material batches and three distance-detail variants. Smaller sculpted foliage avoids oversized sphere meshes. The full gallery now has 96 entries / 124 asset-stage combinations (372 base detail variants, plus shared gate-leaf variants). Every individual base variant remains below 40k triangles and lower detail never adds geometry.

`tests/verify_rustic_collection.gd` checks all 13 free entries/icons/metre bounds/full footprints, collision/idempotence, gate motion, boundary compatibility, all-item placement/save restoration, Campsite search, night-light integration and actual gardener passage through the new gate, both arbors and parterre cross path. Market, courtyard, vertical building, enchanted-night and shared geometry regressions are also run, plus import and rendered previews.

Godot 4.6.3 Compatibility/Mesa was available here; owner's 4.7.2 was not run. This collection is implemented and integrated, and ready for owner visual approval under AGENTS.md. It is not an exact recreation of the pictured products or their photographed gardens.
