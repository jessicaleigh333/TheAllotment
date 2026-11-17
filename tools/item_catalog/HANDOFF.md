# Master item catalog milestone handoff

Base: main `6dddc20` (botanical foundation PR #20 merged). Branch:
`codex/master-item-catalog`. No merge or release is authorized by this report.

## Completed

- Audited 262 definitions: 159 existing shop listings/forms, 84 surface/border
  materials, nine scenery recipes and 10 existing avatar options. No new item
  entitlements, biological identities or finished artwork were invented.
- Captured all evaluated shop dictionaries, dimensions, 228 collision shapes,
  model recipes, material roles, gate/glow controllers, and five reusable gate-leaf
  components. Static repository/resource/glTF scans inventory every source file,
  embedded meshes/materials/animations, functions, references and future requirements.
- Implemented SQLite with foreign keys, acyclic relationships, independent listing
  IDs, shared asset/component bindings, external botanical references and review history.
- Implemented deterministic JSON export, schema validation, safe correction overlays,
  new-request receipts, revision/conflict/type/identity guards and rollback by build.
- Implemented a lazy Godot metadata index and indexed legacy shop source adapter.
  All existing source listing values are preserved. Existing source arrays still
  own live shop/placement fields; metadata edits do not rewrite verified scripts.
- Added guarded adapters for existing acquisition, retrieval, placement start and
  gate operations. Other actual visual components are referenced, and unfinished
  seating/harvest/watering/repair/crafting/sale mechanics remain non-executable contracts.
- Generated an iPad-oriented review workbook, with 159 embedded thumbnails rendered
  from actual SVG/atlas sources. No generated replacement art or binary asset is committed.
- Created and read back a native Google Sheet in the connected user's ChatGPT folder:
  https://docs.google.com/spreadsheets/d/1XlA0-MiOi2xq8rGziCxw-AQM7CfUrEIdKP_uDteItx4/edit

Native workbook has the ten requested subject areas plus audit/reference views,
frozen IDs/headers, filters, protected source warnings and two native dropdown tables
covering 500 proposal rows. All 262 master IDs and template values are checked against
the export. Source links point at existing image files. Google blocked an IMAGE
formula pending a desktop external-fetch permission; the error formula was removed.
No expiring image URLs are left in the workbook. The downloadable XLSX contains all
159 embedded previews; native Sheet source links are verified, but inline thumbnail
rendering in Google Sheets is not claimed. Formatting verification uses API readback;
an authenticated desktop visual-render tool was unavailable.

## Test evidence

- **48 Python tests passed:** 20 item-system tests and 28 botanical regressions.
  Covers full listing/source preservation, domain separation, free shop versus old
  prices, botanical FK coverage, JSON/schema/content hashes, duplicate detection,
  item/category/component cycles, dimensions, asset reuse/paths, contract-only actions,
  stale/identity/economy edit rejection, idempotent overlay chains, explicit clears,
  request receipts, deterministic rebuilds, indexed queries and embedded workbook images.
- **14 Godot suites passed:** item catalog, plant growth, woody growth, market,
  local vault, local profiles, weather, courtyard decorating, real scale, French,
  enchanted, rustic and woodland collections, and garden boundaries.
- Catalog suite verifies all 159 legacy dictionaries after JSON numeric normalization,
  variants/search, defensive copies, malformed data, old-index preservation, unknown
  assets, guarded behavior dispatch and existing save/reload. A 10,000-record metadata
  load plus 10,000 indexed lookups completed in approximately 0.8 seconds locally;
  the test allows five seconds across different machines. No high-detail meshes are
  instantiated by that benchmark.
- Godot source extraction before and after the shop index adapter produced identical
  evaluated listing/mesh metadata. Added collision capture extends the audit; it does
  not modify live collision geometry. Existing engine regressions run with independent
  temporary XDG folders, not player profiles.
- Headless import and actual engine checks use official Godot 4.6.3, matching the
  available runtime; project configuration remains 4.7. New workflow reproduces Python,
  resource import and Godot suites and uploads ignored review artifacts.

No Windows/mobile build or installed-game release is claimed. No owner art approval
is inferred from test success. Existing gardens, geometry, paths, grass, textures,
botanical data, source prices and save formats are preserved.

## Significant findings

- Eight byte-identical SVG groups are reuse candidates; files are retained. A zero
  literal reference count is an unused candidate, not proof that a dynamically loaded
  asset can be deleted.
- The current shop is free despite historical nonzero price fields. Effective prices
  stay zero; sale values/crafting costs are unknown and do not become active.
- Four newer woody profile IDs have no approved botanical mapping across 16 stage
  forms. They remain unresolved; no duplicate botanical registry was created.
- Fountain water is a visual animation; watering cans are decorative; furniture
  names do not prove seating exists. Gate proximity and budgeted day/night glow do exist.
- Six rose-spec paths describe future code, and one HUD path is dynamically formatted.
  These are separate from broken live literal references, of which the final audit
  finds none.
- Raw source snapshot and one runtime bundle are the only committed generated data.
  Each entity occupies one JSON line, so the milestone does not introduce a huge
  prettified duplicate export. SQLite, XLSX, thumbnails, CSVs, logs, editor imports and
  player saves are excluded from the PR.

## Precise continuation work

1. Owner review of current classifications, unverified art statuses, duplicate-icon
   reuse candidates and woody botanical mappings. Preserve old scenery identities.
2. Implement typed new-item/variant publication: request receipt → reviewed definition,
   source/license and physical validation → asset/behavior contracts → tested adapter
   → owner art review → released runtime diff. Do not publish an owner request merely
   because its dropdown says approved.
3. Expand domain schemas only for approved mechanics: vendor/unlock/stock/economy,
   craft recipes, durability, attachment sockets, structural loads, plant/product
   lots, full instance histories and multiplayer ownership. Keep irrelevant fields null.
4. Add live shop UI migration to the master authoring store only after source parity,
   cache invalidation, tombstones/aliases and save-compatibility policies are reviewed.
   This milestone uses an index/metadata adapter, not a wholesale source replacement.
5. Connect reviewed botanical simulation/profile releases and harvested products by
   authoritative IDs; introduce atomic/idempotent inventory operations and stateful
   plant retrieval before health/harvest/lineage mechanics are activated.
6. Add actual model-preview renders and revision-bound art approvals, targeted device
   budgets, localization/accessibility, and full native Sheet thumbnails if Google
   permission/import facilities permit. Current source links and embedded workbook
   previews do not claim final 3D art quality.

No further approval blocks review of this milestone. Activating prices or any new
player mechanic, resolving consequential scientific identity conflicts, or changing
established art/design requires review before that future work affects gameplay.

Architecture, table definitions, diagrams and how-to procedures: README.md,
schema.sql, behaviors.json, bundle.schema.json and the generated audit/SQLite views.
