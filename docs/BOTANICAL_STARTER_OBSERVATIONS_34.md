# Starter botanical evidence review

The first review batch covers the existing `basil` and `cosmos` research records. These field notes support the Growing Guide. Both registry records remain research-only, and the existing legacy profile bindings still require identity review before publication.

| Record and source location | Directly supported observations | Open review |
| --- | --- | --- |
| `basil` · `botanical_library.json#/entries/6` · `/evidence/references/0` | UMD identifies sweet basil as *Ocimum basilicum*, recommends full sun and moist, well-drained soil, describes pinching to encourage bushy growth, and reports leaf picking at around six weeks under its guidance. [University of Maryland Extension](https://extension.umd.edu/resource/growing-basil-home-garden) | The source gives general advice. Cultivar identity, game age knots and quantities need separate evidence or explicit calibration. |
| `cosmos` · `botanical_library.json#/entries/4` · `/evidence/references/0` | RHS identifies *Cosmos bipinnatus*, recommends full sun and moist, well-drained soil, and lists possible susceptibility to aphids and slugs. It recommends deadheading to extend flowering. [Royal Horticultural Society](https://www.rhs.org.uk/plants/30717/cosmos-bipinnatus/details) | The species page gives no cultivar-specific thresholds or elapsed-day curves. The presence of leaf damage alone cannot identify a pest. |

Watering after rain depends on the soil observation. The Growing Guide presents this as practical advice. The game's Diary still records watering and harvest events. Weather effects, soil moisture and pest damage need a simulation model before the game can report them as observations.

The fresh foundation build contained 851 source rows, 833 stable IDs and 805 evidence occurrences. The approved Godot export contained zero records. This batch leaves the original registry and runtime export intact. Review cultivar, growth-stage and asset evidence separately before preparing any publication overlay.
