# Garden and shop scale audit

Measured from the playable `main.tscn` scene, not the original staging grid. One world metre is used consistently; no garden/world parent scaling was found. Reproduce with `tests/verify_real_scale.gd`.

| Measurement | Result |
|---|---:|
| Each of nine garden wedge meshes | 7,446.216 m² / 1.84 acres |
| Wedge depth along its center line | 117.52 m |
| Wedge width at the outside edge (chord) | 102.28 m |
| Wedge inside edge chord | 21.89 m |
| Central stone circle, actual polygon mesh | 2,122.202 m² / 0.5244 acre |
| Central stone circle diameter | 52 m |
| Player collision capsule height, default appearance | 1.65 m |
| Exactly two acres, for comparison | 8,093.713 m² |

Each wedge was independently measured by summing transformed world-space triangle areas. All nine agree with 1.84 acres within floating-point tolerance (under 0.004 m²). These are gross plot areas, including space occupied by furnishings/hedges within the plot, and exclude the separate central circle and approach paths. The approved 1.84-acre layout was verified, not enlarged to two acres. The broad shared circle is a different area from an individual garden.

The preserved `staging/asset_staging.tscn` grid uses 18 m × 18 m sample bays: 324 m², about 0.080 acre. Those bays are for previews and do not represent the playable garden acreage. A distant overview also compresses the apparent size of the much larger playable wedges. The main overview now labels the plot and central-paving acreages.

## Representative full-grown shop forms

| Plant | Height | Spread |
|---|---:|---:|
| Sunflower | 1.80 m | 0.55 m |
| Shrub rose | 1.20 m | 1.20 m |
| English lavender | 0.60 m | 0.75 m |
| Mophead hydrangea | 1.50 m | 1.50 m |
| Cosmos | 1.00 m | 0.60 m |
| Shasta daisy | 0.70 m | 0.60 m |
| Sweet basil | 0.50 m | 0.45 m |

Actual prototype mesh bounds, including child transforms, are tested against these dimensions within 1 mm. Immature forms have distinct geometry and metre-sized stages, not miniature flowering adults. The seed stage shows a small soil marker, not an above-ground seed at adult size. Plant spacing reserves the existing mature footprint so growing plants cannot swallow walkways or each other.

These are chosen representative garden forms; real cultivars and growing conditions produce different sizes. They are not claims about every member of a species. Bench, arch, fountain, lantern, trellis, filled planter, watering can and hat preview meshes also now use explicit metre dimensions (for example, a 1.8 m wide × 0.9 m high bench and a 2.5 m high arch). The wider inherited world still contains stylized prototype trees/furnishings, not a completed botanical asset library.

Open `staging/plant_scale_studio.tscn` with F6 for all growth stages alongside a one-metre ruler and a 1.65-metre human-height block. Pan/orbit/zoom to inspect small stages; the model preview in the Shop automatically magnifies them without changing their world size.
