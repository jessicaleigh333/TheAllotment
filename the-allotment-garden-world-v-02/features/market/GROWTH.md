# Real-time plant growth

The owner selected real days and weeks. Shop now offers Seeds, Seedlings, Young plants and Mature plants for seven starter species: sunflower, shrub rose, English lavender, mophead hydrangea, cosmos, Shasta daisy and sweet basil. The prior sunflower/basil seed-packet IDs remain compatible and are now plantable. Items remain free.

Use the stage selector beside Search, choose a plant and Decorate inner circle or Place in Garden 01. Immature cards show actual stage meshes; details show current height, representative mature size and approximate time to full size. Larger starter plants begin at the appropriate existing age. Already placed mature plants without growth metadata stay mature.

Plants progress through Seed → Sprout → Seedling → Young → Mature using saved UTC timestamps and 86,400 seconds per real day. Offline elapsed time counts. While running, visible growth refreshes once a minute. A seed is a small marked soil spot, sprouts/seedlings have stems/leaves, young flowering plants have a green bud, and mature plants use the full species form. Growth is capped at the chosen mature size; no accelerated game clock is used.

| Plant | Sprout day | Seedling day | Young-plant day | Full-size day |
|---|---:|---:|---:|---:|
| Sunflower | 7 | 14 | 28 | 90 |
| Rose | 120 | 180 | 365 | 1,095 |
| Lavender | 21 | 60 | 180 | 730 |
| Hydrangea | 21 | 60 | 365 | 1,095 |
| Cosmos | 10 | 21 | 35 | 90 |
| Shasta daisy | 14 | 35 | 90 | 365 |
| Basil | 7 | 21 | 35 | 56 |

These are representative ideal-condition schedules for the prototype, not guaranteed horticultural predictions or exact bloom dates. Woody shrubs take years to fill out; choose a young or mature plant to avoid waiting from seed. Actual germination/maturity varies by cultivar, propagation, seed treatment and conditions. The current system does not simulate stratification, frost, dormancy, soil, watering, disease, harvest, death or annual senescence. Decorative foliage on arches and filled planters remains fixed decor. Seasonal title visuals do not currently change growth rates.

The computer clock is the time source; this is local saving, not a trusted multiplayer clock. Negative elapsed time is clamped; normal scene exit preserves the greatest observed age. Returning a plant to the bag retains its achieved stage and exact accumulated age. Time in the backpack is paused; replanting resumes growth from that age. Bought seed packets do not sprout in the bag. Growth metadata is optional for old saves and validated for new saves; malformed values do not overwrite a valid file.

Plant height and spread are measured in world metres. See `docs/SCALE_AUDIT.md` and `staging/plant_scale_studio.tscn`. Shop preview cameras zoom close to small stages, but that does not enlarge the planted model.

## Sources and calibration

These resources ground the representative sizes and broad time ranges; individual stage thresholds above are explicit model assumptions, not quotations or universal species rules.

- [Missouri Extension: Growing Sunflowers](https://extension.missouri.edu/publications/ym102) gives a broad 70–120 day bloom range.
- [Oregon State Extension: Grow your own sunflowers](https://extension.oregonstate.edu/catalog/em-9866-grow-your-own-sunflowers) describes differing cultivar heights and maturity ranges.
- [Maryland Extension: Growing Basil in a Home Garden](https://extension.umd.edu/resource/growing-basil-home-garden) describes roughly 18-inch plants and leaf picking around six weeks.
- [UMN Extension: Growing basil](https://extension.umn.edu/garden-and-home/yard-and-garden/yard-and-garden-problems/growing-basil) describes starting plants six to eight weeks before outdoor planting.
- [RHS: Cosmos bipinnatus](https://www.rhs.org.uk/plants/30717/cosmos-bipinnatus/details), [Shasta daisy](https://www.rhs.org.uk/plants/98781/leucanthemum-%C3%97-superbum/details), [English lavender 'Munstead'](https://www.rhs.org.uk/plants/99904/lavandula-angustifolia-munstead/details), and [Hydrangea macrophylla 'Tivoli'](https://www.rhs.org.uk/plants/381429/hydrangea-macrophylla-hortivoli-purple/details) illustrate the need for cultivar/form-specific size choices.

Verification: `tests/verify_plant_growth.gd` covers all seven species/stages, actual mesh sizes, offline boundaries, pickup/replant age, legacy mature saves, live model refresh and stage-specific Shop/Backpack entries. `tests/verify_real_scale.gd` measures all nine garden meshes, courtyard paving, avatar reference and mature plants. Visual/art approval remains pending; the models now use the shared detailed garden asset library; owner visual approval is pending.
