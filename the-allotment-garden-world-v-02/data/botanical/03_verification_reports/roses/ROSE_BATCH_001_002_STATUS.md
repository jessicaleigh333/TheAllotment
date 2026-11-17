# Verification report — rose library intake (2026-11-16)
Scope: recovered 18 named cultivars; research and specification preparation, **not** 3D/game integration.

## Verification gates
| Gate | Present state | Evidence / action |
|---|---|---|
| Source record recovered | PASS | Six from existing saved Rose Collection prototype; twelve from saved Batch 002 preview |
| Stable distinct IDs | PASS | 18 namespaced `rose-...` IDs and 18 distinct source links in the recovered register; individually fetched from feature branch |
| Original batch completeness | PARTIAL | Preview claims 20 total; only 18 identities recovered. Two never invented |
| Field-level botanical validation | PENDING | Records have source URLs and status `pending_field_audit`; source page must support each trait separately |
| Species-level data | PARTIAL | Generic Rosa shared profile exists but cultivar-specific environmental thresholds are not yet established |
| Construction spec | WRITTEN | `../02_construction_specs/roses/ROSE_FAMILY_CODEX_SPEC.md`; design, not live code |
| New 3D assets, Godot integration | NOT STARTED | No generated scene or model from this intake |
| Godot test suite and screenshots | NOT RUN | Requires project runtime; do not claim verified in-game |
| Save compatibility | NOT YET TESTED | No direct changes to live growth or shop IDs by these files |
| Owner visual review | PENDING | Concept illustrations are not cultivar-verified likenesses |

## Verification instructions for Codex
1. Parse `../01_scientific_records/roses/recovered_rose_cultivars.json` and reject duplicate or missing cultivar IDs.
2. Confirm all 18 original source links return suitable cultivar references; store retrieval date, applicable scope and field-specific excerpts within fair quotation limits.
3. Validate rose class, RHS/registration synonym and breeder code, floral form, mature dimensions, season/bloom type, region, pruning group and support habit. Mark contradictions rather than invent data.
4. Use RHS and extension rose growing/pruning guides as class-level references, not proof of every cultivar's behavior.
5. Add automated Godot and JSON tests before enabling new live shop/catalog items; verify legacy generic rose and climbing rose save compatibility.
6. Report commits, commands, exact outcomes, screenshots and limitations. The owner's existing reporting instructions apply.
7. If a source page is gone or contradicts a profile, mark the field `needs_review` and avoid exposing it as scientific truth.

## Outstanding source review
General RHS roses guide: https://www.rhs.org.uk/plants/roses/growing-guide
Shrub roses pruning: https://www.rhs.org.uk/plants/roses/shrub/pruning-guide
Climbing roses pruning: https://www.rhs.org.uk/plants/roses/climbing/pruning-guide
Illinois Extension old-garden rose timing: https://extension.illinois.edu/roses/pruning

## Release criteria
Do not merge rose records as 'fully verified' or describe any 3D cultivar models as completed. Merge research/data safely once basic schema tests pass; only enable physical/gameplay behavior after independent Godot tests and visual inspection.
