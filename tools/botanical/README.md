# Botanical foundation, stage 1

This is an offline, read-only ingestion and review system. It does not change
Godot growth, catalog IDs, scenery, player saves, economics or game time.
Python 3.10+ and SQLite are sufficient to build. Development tests use
`requirements-dev.txt`; workbook creation additionally uses openpyxl.

## Reproduce

Run from the repository root:

```sh
python -m pip install -r tools/botanical/requirements-dev.txt
python -m unittest tools.botanical.test_foundation -v
python -m tools.botanical.foundation build --out .botanical-build/v1
python -m tools.botanical.workbook --build .botanical-build/v1 --out .botanical-build/BotanicalReview.xlsx
```

Use a new output directory for every build. Outputs must be outside the Godot
project. Builds publish an entire directory by rename after validation; failure
removes temporary output. `.botanical-build/` is ignored. Do not commit SQLite,
new spreadsheet exports, workbooks or engine cache files.

The workbook can be imported into Google Sheets as one master spreadsheet.
CSV tabs are available separately. There is no automatic Google connection,
upload, source replacement or live-game synchronization. The connected account
and sharing/protection choices must be configured before a hosted sheet can be
created. A Google Drive connector supports Sheets but was not connected during
this work. Spreadsheet protection is a usability aid, not authorization.

## Data flow and authority

`preserved source JSON + reviewed overlay -> SQLite -> review tabs and versioned JSON`

Original research in Git is immutable input. Approved overlays are small, textual,
auditable changes applied to effective records in a new build. They never overwrite
originals. Sheets is the owner's primary *review interface*, not a separate writable
authority. Accepted overlays belong in a reviewed PR. Each released build retains
its inputs, overlay and manifest; rollback selects a previous build/overlay, never
resets player saves.

`knowledge.json` exposes all 833 handles and all original/effective source rows.
It is explicitly research-only. `godot_approved.json` is the publication boundary
and currently has zero records: intake and owner editing are not scientific,
artwork or simulation approval. No game script consumes either new export yet.
Formal bundle format: `bundle.schema.json`. Source schema versions `1.0` and
`1.0.0` are supported explicitly; unknown versions, malformed documents, duplicate
JSON keys and non-finite values fail ingestion. The existing visual schema is a
historical design example; it is preserved, not misrepresented as executable schema.

## Losslessness and provenance

- Every original file is stored byte-for-byte in `source_file.content` with SHA-256.
  This includes supporting documents, templates, indexes and historical CSVs.
- Fourteen explicitly recognized collections contribute 851 source rows. Generated
  master summaries, templates and taxonomy indexes are not counted as additional
  plants. IDs cannot repeat inside one source collection. Across-source overlaps
  retain separate rows with a shared permanent plant ID.
- `source_record` retains raw JSON and effective JSON, source path, RFC 6901 pointer
  and revision hash. `field_value` indexes every effective leaf, including null,
  false, zero and empty containers. The original file snapshot retains formatting,
  ordering and every collection-level note.
- URL occurrences are extracted from all supported nested source shapes. Their
  pointers and full context are retained. A URL is explicitly an unverified record
  lead, not proof that it supports every adjacent claim. Research review must add
  field-specific evidence before scientific publication.
- `restore` reconstructs the complete byte-identical source snapshot into a new
  directory; it refuses to overwrite anything.

```sh
python -m tools.botanical.foundation restore --database .botanical-build/v1/botanical.sqlite --out /tmp/botanical-originals
```

## Tables, relationships and field definitions

See `schema.sql` for executable fields, constraints and indexes.

| Table | Meaning and keys |
|---|---|
| metadata | Tool schema version and complete input-set hash |
| source_file | Original relative path PK, original byte content and SHA-256 |
| plant | Existing permanent plant_id PK; original registry summary; unresolved identity and research-only publication status |
| source_record | source path + pointer PK; plant FK; raw/effective objects and effective revision |
| field_value | record FK + relative field pointer PK; JSON value and explicit JSON type |
| evidence | URL occurrence ID; record FK and source field pointer; unverified context |
| taxon_node | Existing family/genus/taxon IDs; source-reported labels/ranks and provenance |
| taxon_edge | Parent/child FKs; source location; no self-links or cycles |
| identity_assertion | Plant and source-record FKs; exact source identity label/pointer; optional exact-label taxon candidate FK, never verified identity inference |
| record_relationship | Source-declared parent-profile links, not invented breeding parentage |
| duplicate_candidate | Scientific-scope candidate pair with two plant FKs; explicitly requires identity review |
| asset_binding | Plant FK; intended artwork/model role/stage; path, existence, model family/base IDs, dimensions/material/animation slots and independent status |
| model_component/link | Shared geometry/material/rig/animation definitions and binding-specific override JSON; empty until actual reviewed assets exist |
| profile_definition | Plant FK, independently versioned future biological profile and approval state; no profiles fabricated by this importer |
| gameplay_binding | Exact live profile ID PK, nullable botanical FK, original source text and mapping status |
| review_change | Unique change ID, record FK, field path, before/after, revision, reviewer/time/reason/evidence |
| issue | Stable issue ID; severity, code, optional plant FK and actionable detail |

Identity assertions preserve cultivar, parent, family and scientific label scope.
An exact label match may have multiple candidate taxon nodes; such cases stay
unresolved. No automatic genus/species splitting, spelling correction, accepted-name
resolution, synonym merging or parentage invention occurs. Hybrid, cultivar,
selection and trade-name relationships need reviewed identity decisions; arbitrary
free text is not converted to definitive biological relationships.

SQL query example:

```sql
SELECT r.plant_id, f.pointer, f.value_json, r.source_path, r.pointer
FROM field_value f JOIN source_record r USING(record_key)
WHERE r.plant_id = 'apple';
```

Keep botanical variety distinct from cultivar, cultivar group and mixed seed
strain. Original record IDs are never regenerated from names. New identities need
their own immutable namespace policy and reviewed import adapter before ingestion;
existing scientific names alone cannot identify a unique cultivar.

## Owner editing and approved overlays

Workbook tabs include Plants, Fields, Sources, GrowingRequirements, LifeStages,
HealthAndEcology, Workflow, Assets, IdentityAssertions, Taxonomy/Links, Relationships,
GameplayBindings, DuplicateCandidates, Issues and Changes. Some tabs are overlapping
views; Fields remains the complete indexed view. Original prose is never discarded
because it did not fit a specialized tab.

1. Inspect a field in Fields or a specialized tab. Copy its `record_key`, plant ID,
   pointer and base revision into Changes. IDs/revisions are text, not numbers.
2. Supply a unique change ID, explicit `set` or `clear`, JSON value, decision,
   reviewer, real UTC review date, reason and evidence URL. Example string value:
   `"well_drained"`. Clear requires explicit `null`. A blank row is not deletion.
3. Export only Changes as UTF-8 CSV, retaining the exact column names/order.
4. Run the review validator to produce an overlay and inspect its before/after diff.
5. Build a new version with that overlay, run tests and submit the overlay in a PR.

```sh
python -m tools.botanical.foundation review --database .botanical-build/v1/botanical.sqlite --changes /tmp/Changes.csv --out /tmp/approved-overlay.json
python -m tools.botanical.foundation build --out .botanical-build/v2 --overlay /tmp/approved-overlay.json
```

Stale revisions, duplicate IDs, conflicting field edits, altered identity fields,
unknown fields, unsupported type/container replacements, missing review metadata
and invalid JSON are rejected. Retrying an already applied identical change is a
no-op. Reusing its ID with different content fails. A later review extends the
previous overlay history and uses current effective revisions. The complete change
chain is replayed and revalidated against original inputs at every build.

Source evidence/notes remain in raw records even when an effective value is cleared.
New records, new fields, identity resolution, unit/schema changes and simulation
publication require separate structured review; the current CSV patcher deliberately
does not guess their meaning. Record additions/corrections as draft owner notes
until the corresponding adapter/schema change is reviewed. No bulk arbitrary SQL
or spreadsheet formula is executed. Spreadsheet formula prefixes are neutralized
on export; raw source strings remain intact outside Sheets.

## Artwork and growth contracts

`contracts.json` defines future asset/profile/instance field families and invariants.
`profile.schema.json` and `profiles.validate_profile` validate future profile types,
positive metre dimensions, increasing real-day knots, botanical/evidence references
and calibration context. No biological profile is populated or activated by this
foundation; environmental/health/breeding rule bodies still need specialized schemas.
Asset bindings include illustration, Field Guide, thumbnail/icon, construction
reference, base/stage model, preview, animation, material and editable source roles.
All 9,163 initial bindings are missing placeholders for 833 records, not 9,163
assets. Existing game prototype art is not reclassified as missing; these are
unpopulated botanical-registry links. Paths are validated against traversal and
symlink escape; file existence alone never grants visual/scientific approval.

No November 14 rose originals were found in the botanical branch directory. They
remain unlinked. Future ingestion must verify the actual image, origin/license,
hash, identity binding and owner review before using it for construction. Do not
infer cultivar identity from an image or substitute generic recolors for structural
differences. Shared components and cultivar overrides avoid duplicating geometry.

Future simulation separates continuously increasing chronological age from
developmental maturity, seasonal organ states and capped structural size curves.
Flowering/fruiting/dormancy may recur and overlap; physiology, environment,
health/differential diagnoses, propagation, rootstock/lineage and harvesting have
separate interfaces. Real elapsed/offline time is retained. Per-instance history
must survive retrieval; five-member hedge items must not become one biological
plant. Idempotent harvest transactions and deterministic bounded offline catch-up
need implementation and tests before those mechanisms go live.

Current live profiles and save formats are unchanged. The compatibility audit
records all 16 live growth IDs, including the four unresolved newer woody IDs;
it does not silently manufacture new species or remap saved items. The legacy
botanical loader brought across from the source branch remains unhooked and its
12-profile coverage is not claimed complete.

## Remaining development gates

1. Review identity mappings, synonyms, cultivated forms and true duplicate decisions
   with taxonomic authorities. All six scientific-scope pairs are candidates only.
2. Add schema-specific typed trait/evidence adapters and structured new-record review.
   Provisional source notes cannot justify numeric physiology, yield or breeding rules.
3. Connect the owner-approved workbook to a Google account; establish sharing,
   protected ranges and approved export ownership. No live sheet exists yet.
4. Supply and verify rose originals; build reviewed shared model components and
   stage variants with metre bounds, LOD/material/collision budgets and actual previews.
5. Pilot independently versioned scientific/growth profiles and save migrations;
   define geographic climate/site and calibration scope. Add perennial seasons,
   environment/health, propagation and harvest in tested increments.
6. Implement a reviewed publication decision bound to exact profile/asset revisions,
   then introduce a tested Godot adapter. Owner data correction alone must not activate
   unfinished gameplay. Existing plants retain their prior behavior until migration.

Do not merge the older botanical branch wholesale into main. This foundation
preserves its research directory while retaining all current main gameplay.
