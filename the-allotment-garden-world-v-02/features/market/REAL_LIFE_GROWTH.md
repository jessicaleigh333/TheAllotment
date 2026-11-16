# Real-life growth scale: living woody plants

Owner direction, 2026-11-16: living plants must have their own growth stages and real-life growth scale; this is the standard for future plants and objects. One Godot unit remains one metre. One day remains 86,400 actual elapsed seconds, including offline time. This change does not add a network clock or advance game time for previews.

## New plantable profiles

Search **Living trees and hedges** in Shop → Plants. Choose seeds, seedlings, young nursery stock or mature specimens with the existing stage selector. Mature nursery stock can be placed immediately at its mature size. These are four growing profiles, covering three species and one dwarf cultivar/group presentation, not four newly discovered species.

| Existing art family / shop ID | Identified plant | Representative mature height × width × depth | Representative age |
|---|---|---|---|
| tree | English oak, Quercus robur | 20 × 16 × 16 m | 50 real years |
| cypress | Italian cypress, Cupressus sempervirens | 15 × 3 × 3 m | 30 real years |
| shrub | Common box, Buxus sempervirens | 5 × 5 × 5 m, untrimmed | 20 real years |
| hedge | Dwarf box, Buxus sempervirens 'Suffruticosa', five plants | 1 × 1.5 × 2.9 m overall | 10 real years |

The hedge consists of five plants at 0.35 m intervals along the row. Its 2.9 m mature depth includes 1.4 m of fixed plant-centre spacing plus 1.5 m individual spread. Seeds and seedlings already occupy those spaced row positions; this is not one seed that later turns into five plants. The dwarf cultivar provides a low hedge without pretending that a full-sized box shrub naturally stops growing at a clipped size. Pruning gameplay is not added.

## Source basis and limits

Authoritative source pages checked 2026-11-16:

- [RHS English oak](https://www.rhs.org.uk/plants/14294/quercus-robur/details): broad-crowned mature tree; 20–40 m narrative height, spread above 8 m, 20–50-year maturity band. We choose a representative 20 m / 16 m crown benchmark at 50 years; RHS does not prescribe that exact paired trajectory.
- [RHS Italian cypress](https://www.rhs.org.uk/plants/5079/cupressus-sempervirens/details): columnar tree reaching 15 m, spread 2.5–4 m, 20–50-year maturity band. We choose 15 × 3 m at 30 years.
- [RHS common box](https://www.rhs.org.uk/plants/2579/buxus-sempervirens/details): large shrub/small tree, size range 4–8 m and 10–20-year maturity band. We choose an untrimmed 5 m specimen at 20 years.
- [RHS dwarf box cultivar](https://www.rhs.org.uk/plants/99372/buxus-sempervirens-suffruticosa/details): 0.5–1 m height, 1–1.5 m spread, 5–10-year maturity band. We choose the upper benchmark at 10 years.
- [RHS box growing guide](https://www.rhs.org.uk/plants/box/growing-guide): common-box hedging spacing of 30–40 cm informs the representative 35 cm row spacing.

Mature benchmarks fit those references. Germination dates, intermediate age/size knots, trunk diameters and the particular growth trajectories are **explicit calibrated estimates**, not field-measured predictions or universal horticultural constants. Seeds assume viable, prepared propagules under favourable conditions; no stratification/temperature dependency is simulated. Piecewise interpolation is species-specific, with growth in real years. A 365.25-day year is an elapsed-time convention, not an exact calendar anniversary. Profiles stop at their selected mature benchmark; centuries of later growth, dormancy, weather-dependent development, pests, pruning and mortality remain unimplemented. The existing twelve growth profiles are preserved rather than silently recalibrated.

## Art, collision and compatibility

Five distinct visual phases per profile add seed/acorn, cotyledon/sprout, seedling, branching young plant and mature crown architecture. Each phase has three detail levels. Woody geometry uses the current curve dimensions and trunk size, rather than stretching one adult mesh through every age. Individual oak/box leaves and cypress foliage sprays use native metre dimensions; cache buckets are 1 cm in height/spread and 1 mm in trunk diameter. Exact displayed model bounds are fitted to the current curve state. The small bucket size prevents nearly identical mesh allocations on each minute tick.

Plant growth collisions follow the current trunk or woody canopy and are rebuilt after visible growth. Seeds and sprouts do not create tree-sized barriers. Placement reserves conservative mature crown/row clearance; plants do not later grow into layouts permitted only because the initial seed was tiny. Planting, retrieval with retained age, local vault save/reload and clock rollback protection use the existing systems.

Existing neighbourhood scenery keeps its original generic meshes, sizes and positions. New living models use separate `@growing` art cache IDs. We do not assign invented species/ages to old decorative scenery, alter the courtyard, rescale the garden, or move player items. Previously saved plants retain their schedules and save format. Saves without growth metadata still mean mature existing plants. No Windows build, updater release or main-branch merge is made for this task.

## Future acceptance rule

Every new growing profile must provide scientific identity/cultivar scope, named visual phases, finite increasing real-day age knots, positive metre height/width/depth knots, mature size, source URLs, and an explanation separating referenced facts from estimates. `Growth.validate_profiles()` checks all new profiles; only the twelve pre-existing profiles are explicitly grandfathered. Invalid future profiles are unavailable in the catalog. Existing all-profile growth tests verify stage timing and metre bounds; new woody tests verify architecture/LOD budgets, row dimensions, saved progress, collision resizing and placement. Do not count LODs, stages, meshes or colour variants as different species.

Open `staging/woody_growth_showcase.tscn` and press F6 for a read-only age/stage preview with a 1.65 m reference post and the existing gardener. Preview choices never advance live save time. The new art is ready for owner visual approval.
