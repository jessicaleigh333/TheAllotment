# November 2026 integration review — The Allotment

Status: **REVIEW ONLY — DO NOT MERGE TO main UNTIL CHECKS PASS**.

## Safe baseline
- Working integration branch: `integration/nov-2026-game-review`
- Based on `codex/windows-launcher-updater` at `473e2ab0130b7abe72c477f539ca0451c5eb1538`.
- `main` remains unchanged.
- The Windows-launcher branch is 17 commits ahead of `main`, zero behind. The earlier 15 checked feature branches are ancestors of this branch, so **do not merge those feature branches one by one**.
- The branch contains game features and the Windows USB/updater implementation. Presence of tests and notes is not proof of successful end-to-end Windows validation.

## Unresolved divergent work — do NOT assume included
- `codex/cobblestone-garden-paths`: diverged; adds `scripts/cobble_paths.gd` and `shaders/cobblestone.gdshader` plus lawn assets and scene changes. Compare implementation with the integration branch and deliberately port any missing desired functionality; avoid merging generated `.godot/` caches or temporary `.tmp` files.
- `codex/soft-grass-ground`: diverged; adds `scripts/lawn.gd`, `shaders/grass_blades.gdshader` and `shaders/lawn.gdshader`. Some work overlaps with the cobblestone branch; inspect together, not as blind merges.
- `docs/codex-backlog-nov-2026`: diverged; includes `docs/CODEX_BACKLOG_2026-11-13.md`; bring forward the useful documentation separately if not already represented.
- `download/updated-garden-preview`: ancestor of newest Windows branch; no separate merge required.

## Release and integration gate
- [ ] Compare cobblestone and lawn work against the latest garden; port only missing intended features.
- [ ] Review and include any useful standalone Codex backlog documentation.
- [ ] Review tracked Godot generated/editor cache files and remove from future source control where safe; keep project assets and UID references that are genuinely required.
- [ ] Run fresh Godot import, parse and gameplay checks on the *combined* integration branch.
- [ ] Exercise real-time growth, saves/vault/profile migrations, market/inventory, and garden interactions together.
- [ ] Run the Windows launcher/updater test and Windows export/smoke test. The workflow is manually dispatched (`workflow_dispatch`) and requires a privately configured `ALLOTMENT_UPDATE_SIGNING_KEY`; do not disclose or commit signing keys.
- [ ] Check GitHub Actions results, installer/offline-first start, update/rollback behavior, and playable Windows build.
- [ ] Review changed files and any merge conflicts, then obtain owner approval before merging to `main`.
- [ ] After merge, pull `main` in GitHub Desktop, back up local game saves, and verify the desktop Godot project/game build.

## Process going forward
Codex should start each new feature branch from the current approved integration/main baseline, commit/push, report exact branch + SHA + test commands/results, and open a draft PR. Preserve branch history and save evidence; do not claim an update reached the installed game until rebuilt/released and verified.

This document is a tracking and handoff checklist, **not** test evidence or an approval to release.

## Master world catalog milestone — 2026-11-17

Dedicated branch `codex/master-item-catalog`, based on main `6dddc20`, audits 262
existing shop/surface/scenery/avatar definitions without merging or releasing.
SQLite, shared asset/behavior references, botanical ID links, revision-checked review
overlays, native Google Sheets review and a compatible Godot source-index/metadata
adapter are implemented. Live acquisition remains free and save formats are unchanged.
Forty-eight Python tests and fourteen isolated Godot suites passed locally; owner art
review, scientific identity decisions and future mechanic publication remain distinct.
See `tools/item_catalog/HANDOFF.md` for exact scope, evidence, workbook link and remaining
work, and `tools/item_catalog/README.md` for the architecture and reproduction workflow.
