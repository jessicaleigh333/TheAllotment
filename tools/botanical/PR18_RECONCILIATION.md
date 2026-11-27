# PR #18 reconciliation

Issue #34 review at main `861f686`. PR #18 at `e871372` remains an open historical branch. All 33 original botanical files match the current main tree byte for byte. Relative to PR #18, main's botanical subtree adds only the dormant loader UID and two import exclusions for review CSVs. The current pipeline already carries the sources through the foundation merged in #20.

| Pipeline result | Count |
| --- | ---: |
| Source rows ingested | 851 |
| Stable research IDs | 833 |
| Stable IDs represented in two sources | 18 |
| Additional identity candidates flagged for review | 6 |
| Unverified source URL occurrences | 805 |
| Rows rejected by source ingestion | 0 |
| Research IDs withheld from runtime publication | 833 |
| Godot-approved export | 0 |

The build preserves each source revision and exact URL field pointer. Of the research IDs, 12 lack a registry scientific name and 833 lack linked artwork/models. Four current runtime profiles lack a research mapping. Ingestion, genuine field-level validation, asset linkage and runtime publication are distinct steps. Keep the source rows in the foundation and supply scoped reviewed overlays for any future runtime records. No save or live catalog ID migration is required.

The Godot 4.6.3 read-only export check read both bundles. The all-profile growth suite, market suite, vault checks and current item catalog tests exercise the runtime catalog and profile saves independently of the research export.
