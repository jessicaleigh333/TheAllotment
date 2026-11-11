# Real-time climbing plants

Five original free plants are available by searching **Climbing vines** in Shop → Plants. The existing stage selector supplies seeds, seedlings, young plants or mature plants. Their low unsupported crowns retain realistic metre dimensions; trained stems follow nearby supports at metre scale.

| Species | Seed germination | Seedling | Young plant | Representative maturity | Maximum trained stem length |
|---|---:|---:|---:|---:|---:|
| Climbing rose | 120 days | 180 days | 365 days | 1,095 days | 5 m |
| Clematis | 30 days | 90 days | 180 days | 730 days | 4 m |
| Honeysuckle | 30 days | 90 days | 180 days | 730 days | 6 m |
| Ivy | 28 days | 90 days | 365 days | 1,095 days | 6 m |
| Wisteria | 21 days | 90 days | 365 days | 1,825 days | 8 m |

These are representative ideal-condition establishment schedules, not accelerated game days or cultivar-specific horticultural predictions. All 12 growing species use the same system Unix clock and 86,400 seconds per day. Planted growth includes offline time; observed ages do not shrink on clock rollback. Changing seasons, the lighting preview or the review-scene age selector never advances a live garden. Real establishment of perennial climbers can take years. Wisteria flowers only at the mature stage. A mature shop plant starts at its representative mature age and can already cover its available support; seedlings grow continuously between stage thresholds. Existing non-climbing plant schedules are unchanged. Plants retain achieved age on retrieval/replant; bagged plants retain that age while packed.

## Training and placement

Plant roots within 0.85 m of a compatible support's base, at a similar ground height and in the same garden/courtyard. Placement text identifies the selected support. Vines can share the otherwise reserved footprint of that support, while roots still obey terrain, protected-route and other-object rules. Roots are excluded from lattice planes, column interiors and cone/planter interiors. Other plants and decorations keep their old overlap rules. Placing a support beside an existing vine works too.

Supported objects: timber/branch trellises, espalier, rose/rustic/fairy/moon arches, pergola, iron pavilion, branch fence, fixed garden-gate piers, climbing cones, Roman column/base/drum/capital/pedestal parts, woodland potting/sheltered stations, lantern picnic posts and rope-swing pole. Benches, stools and other low scenery do not become climbing supports. Existing decorative foliage/flowers on older props remain part of those props; this system grows the newly planted vines independently.

Routes follow authored structural members, transformed with the same measured mesh fit and rotation as their models. Arches follow their curved crowns; pergola routes can cross overhead beams. A contiguous aligned stack of Roman parts forms a longer column route. Maximum reach and biological age limit the covered route. Foliage never adds collision or blocks a gate's moving leaves.

The nearest eligible route is selected deterministically in saved record order. Geometry is reconstructed from saved plant age, support positions/rotations, scope and stable item IDs; no online account or fast simulation is needed. Removing a support leaves the vine's rooted crown and age intact. Replacing it can retrain the plant at its achieved age. This is automatic visual training, not a simulation of stem attachment forces, invasive spread, pruning or structural damage.

## Art and tests

Original branching stems, paired leaves and pink rose/purple clematis/cream honeysuckle/violet hanging wisteria flowers reuse the garden materials. Ivy has no ornamental flowers. Three detail levels use a 2 cm growth-change threshold to avoid rebuilding nearly identical training meshes every minute. Standalone meshes share the art cache; trained paths are per plant. Review `staging/climbing_vine_showcase.tscn` with F6. Owner visual approval remains pending for the new plant artwork.

`tests/verify_climbing_vines.gd` verifies all five species/stage shop entries, real/offline/rollback clocks, rotated support matching, scope/height separation, column assemblies, planting in both orders, live trained geometry, trained mesh LOD budgets, saved reconstruction and support removal. The general plant, market, ground-cover, courtyard, vertical-building, profile and woodland regressions also apply. The shared mesh audit now includes 114 entries, 162 asset/stage combinations and 486 variants.
