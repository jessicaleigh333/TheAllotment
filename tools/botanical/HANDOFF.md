# Botanical foundation handoff

## Delivered

Feature branch: `codex/botanical-database-foundation`, based on main
`63511050dfd7913bd73e5f34981d372e6773cdd0`. No automatic merge.

- All 33 botanical files preserved from `e871372324c4a8780cff45e45dde0b5f334a4844`,
  checked byte-for-byte. Stable existing IDs and both versions of overlapping rose
  research are retained. Original CRLF bytes are protected by `.gitattributes`.
- A lossless read-only importer, constrained relational SQLite build, field-level
  query index and unverified scientific-source traceability.
- A versioned research bundle and separate approved Godot bundle. A reproducible
  manifest hashes inputs, effective content, approved change history, tooling and
  generated text outputs. Original sources can be restored byte-for-byte.
- Six scientific-scope candidate pairs and explicit taxonomic/identity assertions;
  no scientific identity merges or invented classification decisions.
- Artwork/model binding roles, shared component/link tables, future growth profile
  and instance contracts, executable profile/schema validation, and missing-path checks.
- Sixteen CSV review tabs and an importable multi-tab workbook for Google Sheets.
  Corrections pass through a revision-checked, auditable overlay; repeated imports
  are idempotent, explicit clearing is required, and original research is untouched.
- Automated Python/workbook tests and a GitHub Actions workflow producing review
  artifacts. A detached Godot export smoke test performs no game/save writes.
- Source-file audit, executable SQL, JSON schemas, architecture/workflow/field
  documentation and a staged development backlog.

## Verified baseline counts

| Item | Count |
|---|---:|
| Source rows | 851 |
| Permanent registry IDs | 833 |
| Indexed field leaves | 18,553 |
| URL occurrences with provenance, all unverified | 805 |
| Family/genus/taxon nodes | 544 |
| Source-reported hierarchy edges | 475 |
| Identity assertions | 2,025 |
| Scientific-scope candidate pairs | 6 |
| Intended asset bindings, all missing/unlinked | 9,163 |
| Live growth profiles audited | 16 |
| Newer woody profile IDs requiring botanical mapping | 4 |
| Approved simulation records exported | 0 |

The 18 rose overlaps are confirmed same-ID source overlaps, not 18 records to
delete. The six scientific-scope pairs include different cultivated forms sharing
species names; none is confirmed as a redundant botanical identity. The registry
also has 12 empty scientific-name summaries; underlying source detail remains queryable.

## Validation performed

- **28 Python tests passed**, including all-record/all-field round trips, byte
  restoration, SQLite foreign keys, broken taxonomy, ID uniqueness, schema rejection,
  evidence pointers, scientific-scope matching, asset traversal/missing paths,
  deterministic exports, approved overlays and subsequent change chains, stale
  conflicts, retry idempotency, explicit clears, type/identity restrictions,
  spreadsheet formula protection, profile contracts and workbook contents.
- **Six existing Godot suites passed** on Godot 4.6.3, each with its own temporary
  XDG data/config/cache directories: `verify_plant_growth`, `verify_woody_growth`,
  `verify_market`, `verify_local_vault`, `verify_local_profiles`, `verify_weather`.
  These exercise all 16 growth profiles, stages/metre bounds, offline clocks,
  legacy saves, age-preserving pickup/replant, market and local vault behavior.
- **Godot read-only bundle test passed:** 833 research records and zero approved
  records parse successfully in the actual engine.
- Godot resource import completed after excluding review CSV directories with
  `.gdignore`; no script parse errors or CSV translation import failures remained.
  Editor debugger sockets are restricted in this sandbox; that does not prevent
  headless execution of the six passing suites.
- Current-main gameplay, assets, scenes, design document, project configuration
  and save scripts are unchanged. Test saves used temporary directories, not
  player profiles. Generated import/translation sidecars were excluded/removed.

Reproduction commands are in README.md. The Godot bundle check is:

```sh
godot --headless --path the-allotment-garden-world-v-02 --script "$PWD/tools/botanical/verify_bundle.gd" -- "$PWD/.botanical-build/v1/knowledge.json" "$PWD/.botanical-build/v1/godot_approved.json"
```

Run each existing suite with its own empty `XDG_DATA_HOME`, `XDG_CONFIG_HOME`,
`XDG_CACHE_HOME` so their test fixtures cannot contaminate one another. Do not run
save-writing tests against real player directories. The current project declares
Godot 4.7; the available official runtime is 4.6.3, also used by the existing
distribution work. Native Windows/mobile and full graphical interaction were not
retested for this offline-only change.

## What remains deliberately unfinished

- A hosted Google Sheet: Google Drive/Sheets is not connected. The importable
  workbook and validated round-trip workflow are ready; no live spreadsheet URL
  or account write is claimed.
- Scientific field verification, actual identity/synonym decisions and the four
  woody-to-botanical mappings. Taxonomic/source labels remain provisional.
- Structured new-record intake and identity/type/schema extensions. Changes.csv
  supports reviewed edits to existing nonidentity leaf fields; draft owner notes
  capture larger requests. It does not silently add plants or reinterpret units.
- The November 14 rose originals: no verified cultivar-specific files located.
  No artwork/model creation, approval or live integration is claimed.
- Publication approvals tied to specific scientific/profile/asset revisions,
  typed domain schemas for all environmental/health/breeding/harvest mechanics,
  populated biological profiles and shared model components.
- Live recurring phenology, continued post-maturity biological age, environmental
  simulation, diagnostic reasoning, reproduction/harvest and expanded instance
  saves. These require a reviewed pilot and compatibility migrations before use.

No further owner decision blocks this foundation. Consequential future decisions
are the pilot climate/site, identity dispositions, profile calibration policy for
existing plants, and actual artwork approvals. They should be resolved before the
corresponding gameplay/art changes, rather than guessed during ingestion.
