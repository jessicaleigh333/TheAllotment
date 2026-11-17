# Botanical source-file audit

Botanical branch `e871372324c4a8780cff45e45dde0b5f334a4844`; main `63511050dfd7913bd73e5f34981d372e6773cdd0`; common ancestor `1d4ca5a5c5d4191e3dc10ffd0c811a5f25385bda`.

The reported 67 files / approximately 68,000 added lines could not be reproduced from these revisions. The botanical branch adds **33 files / 84,077 lines** from the common ancestor. Comparing whole current branch trees instead shows 59 differing paths, including older gameplay and missing newer woody-growth files. That is branch divergence, not 59 proposed changes in this PR.

All 33 botanical originals are preserved byte-identically. This includes five historical generated review views; keeping them preserves the previous owner-review work. They are inputs/archive material, not extra plants. New SQLite builds, generated JSON/CSV workbooks and caches are ignored and are not committed.

## Content by purpose

| Purpose | Added lines |
|---|---:|
| Dormant knowledge loader | 52 |
| Historical generated review view | 56,395 |
| Original research collection | 24,568 |
| Research/construction documentation | 327 |
| Source-reported taxonomy index | 2,516 |
| Unpopulated cultivar template | 82 |
| Visual linkage design contract | 137 |

The five generated views account for 56,395 lines. The master registry JSON alone has 36,313 lines; the all-fields CSV has 18,365 physical lines because JSON/text is quoted across multiple lines. Physical line counts are not plant counts. The two rose collections overlap on 18 exact IDs; both versions remain preserved. Species/cultivar and shared-name overlaps are reported for review, not deleted.

## Every original file

| Project-relative file | Added lines | Purpose |
|---|---:|---|
| `data/botanical/01_scientific_records/cultivar_template.json` | 82 | Unpopulated cultivar template |
| `data/botanical/01_scientific_records/family_genus_index_batch_002.json` | 2,516 | Source-reported taxonomy index |
| `data/botanical/01_scientific_records/mixed_garden_batch_001.json` | 1,689 | Original research collection |
| `data/botanical/01_scientific_records/roses/recovered_rose_cultivars.json` | 501 | Original research collection |
| `data/botanical/01_scientific_records/starter_named_varieties_batch_001.json` | 1,930 | Original research collection |
| `data/botanical/01_scientific_records/starter_named_varieties_batch_002.json` | 1,309 | Original research collection |
| `data/botanical/01_scientific_records/starter_named_varieties_batch_003.json` | 1,310 | Original research collection |
| `data/botanical/01_scientific_records/starter_named_varieties_batch_004.json` | 1,550 | Original research collection |
| `data/botanical/01_scientific_records/starter_named_varieties_batch_005.json` | 1,690 | Original research collection |
| `data/botanical/01_scientific_records/starter_named_varieties_batch_006.json` | 758 | Original research collection |
| `data/botanical/01_scientific_records/starter_named_varieties_batch_007.json` | 858 | Original research collection |
| `data/botanical/01_scientific_records/starter_named_varieties_batch_008.json` | 959 | Original research collection |
| `data/botanical/01_scientific_records/starter_named_varieties_batch_009.json` | 958 | Original research collection |
| `data/botanical/01_scientific_records/taxonomic_skeleton_batch_002.json` | 9,838 | Original research collection |
| `data/botanical/02_construction_specs/PLANT_VISUAL_ASSET_SCHEMA_V1.json` | 137 | Visual linkage design contract |
| `data/botanical/02_construction_specs/ROSE_REFERENCE_ART_TO_3D_CONTRACT.md` | 22 | Research/construction documentation |
| `data/botanical/02_construction_specs/roses/ROSE_FAMILY_CODEX_SPEC.md` | 66 | Research/construction documentation |
| `data/botanical/03_verification_reports/STARTER_500_CODEX_HANDOFF.md` | 30 | Research/construction documentation |
| `data/botanical/03_verification_reports/broad_taxonomy_batch_002_STATUS.md` | 25 | Research/construction documentation |
| `data/botanical/03_verification_reports/mixed_garden_batch_001_STATUS.md` | 30 | Research/construction documentation |
| `data/botanical/03_verification_reports/roses/ROSE_BATCH_001_002_STATUS.md` | 34 | Research/construction documentation |
| `data/botanical/BREADTH_FIRST_ROADMAP.md` | 33 | Research/construction documentation |
| `data/botanical/CODEX_CONSTRUCTION_CONTRACT.md` | 43 | Research/construction documentation |
| `data/botanical/README.md` | 29 | Research/construction documentation |
| `data/botanical/botanical_library.gd` | 52 | Dormant knowledge loader |
| `data/botanical/botanical_library.json` | 908 | Original research collection |
| `data/botanical/master_registry/README.md` | 15 | Research/construction documentation |
| `data/botanical/master_registry/master_botanical_duplicate_candidates.csv` | 31 | Historical generated review view |
| `data/botanical/master_registry/master_botanical_registry.json` | 36,313 | Historical generated review view |
| `data/botanical/master_registry/master_botanical_review.csv` | 834 | Historical generated review view |
| `data/botanical/review_exports/botanical_all_fields_review.csv` | 18,365 | Historical generated review view |
| `data/botanical/review_exports/botanical_records_review.csv` | 852 | Historical generated review view |
| `data/botanical/rose_cultivar_register.json` | 310 | Original research collection |

## PR scope controls

- Only the botanical subtree is brought across from the older branch; latest-main game scripts, art, scenes and save code remain untouched.
- Two `.gdignore` files prevent the historical review CSV directories from being imported as Godot translation resources. A stable UID accompanies the existing dormant botanical loader.
- New work is limited to offline tooling, schemas/contracts, tests, documentation and a CI workflow. No generated database, review output, artwork substitute, player save or local path/secret is staged.
- No November 14 cultivar illustration files exist under the imported botanical subtree. Relevant asset directories in main contain generic art/icons, not verified source-to-cultivar rose illustrations. No such image was claimed located.
- The final staged diff is checked against main for unexpected edits and all 33 imported originals are compared against the pinned branch bytes.
