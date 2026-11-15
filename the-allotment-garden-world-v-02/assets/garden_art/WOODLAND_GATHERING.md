# Woodland gathering collection

13 original free Shop → Decor items interpret the owner's additional woodland Campsite screenshots. Search **Woodland** (also finds the earlier fairy-light arbor), or **gathering play** for exactly these 13. No Pinterest photographs, product designs, account names or branding are included. These are independent softly stylized interpretations, pending owner visual approval.

| Item ID | Width × height × depth, metres | Behavior |
|---|---|---|
| log_bench | 2.1 × 0.5 × 0.65 | Decorative live-edge seating |
| paddle_back_bench | 2.1 × 1.3 × 0.75 | Decorative paddle-backed seating |
| round_log_bench | 2.1 × 1.1 × 0.8 | Decorative rounded-log seating |
| stump_stool | 0.5 × 0.45 × 0.5 | Decorative seating; can be placed on a supported flat top |
| branching_picnic_table | 3.6 × 0.85 × 3.2 | Three-armed timber table and stump seats |
| lantern_picnic_canopy | 3.6 × 2.7 × 2.8 | Table, benches, branch frame and three night-glowing lanterns |
| woodland_potting_station | 2.5 × 1.8 × 0.9 | Decorative worktable, shelves, pots, foliage and tools |
| sheltered_workbench | 2.8 × 2.8 × 1.8 | Decorative worktable beneath a pitched plank roof |
| tree_trunk_bar | 3.6 × 3 × 3.6 | Decorative counter, freestanding central trunk and stools |
| forest_gathering_deck | 4 × 0.24 × 4.9 | Walkable four-metre flat platform plus entry ramp |
| stump_balance_trail | 3 × 0.45 × 4.8 | Walkable zigzag beams, stump supports, landing and entry ramp |
| log_seesaw | 3.4 × 1.1 × 1.2 | Static decorative seesaw, handles and pivot |
| rope_beam_swing | 4 × 3.2 × 1.7 | Static decorative pole, crossbeam, ropes and seats |

## Integration and controls

Use the existing free Shop, placement, R rotation, Backpack retrieval and local profile save. Existing ground, protected paths and planted areas are unchanged. All entries have individual SVG icons, exact measured model bounds, conservative footprints, collision and three shared mesh detail levels. Closed cut ends have modeled growth rings; material roles reuse the shared wood, metal, foliage and night shaders.

The deck's flat top is 0.24 m high, four metres square, offset 0.45 m behind its placement origin. Its ramp occupies the remaining 0.9 m of depth. T enables stack mode for compatible furniture, pots or Roman parts; point at the flat deck top. Every contact must be supported; the sloping ramp is excluded. Rotation-aware support checks and existing dependency-safe saves/retrieval apply. Deck and trail themselves are ground items. The trail includes an extended landing so the player reaches beam height before encountering its first stump. Walk up the ramps with ordinary movement; no jump is required.

Lanterns use visible open metal frames and night-emissive cores, with one soft halo and one shadow-free light for the complete picnic setting. They join the existing six-nearest-light, 24-metre budget. The Garden lighting preview control and reduced-motion setting apply.

Seating, swinging, seesaw riding, crafting, serving drinks, playing music and yoga activities are **not implemented**. These objects are placeable scenery; their descriptions identify decorative use. The deck and balance trail provide collision-based walking, not a minigame or balance animation.

## Preview and verification

Open `staging/woodland_gathering_showcase.tscn`, press F6, select an item, right-drag to orbit and scroll to zoom. Toggle day/night for the picnic setting. The general garden gallery includes the collection too. Owner visual review is required before treating the artwork as final.

`tests/verify_woodland_collection.gd` checks all 13 free entries, icons, exact metre bounds, footprint coverage of the complete bounds, idempotent collisions, all-item placement/save reload, search, night hookup, actual player passage up both entry ramps, and rotated deck support/exclusion rules. `tests/verify_garden_art.gd` audits all 137 asset/stage combinations and 411 mesh variants for UVs, normals, indices, shared resources, material roles, collision and LOD budgets (under 40,000 triangles per variant). Market, courtyard, vertical-building, enchanted and rustic regressions are also required. Validated with Godot 4.6.3 Compatibility; the owner's 4.7.2 editor was not available here.
