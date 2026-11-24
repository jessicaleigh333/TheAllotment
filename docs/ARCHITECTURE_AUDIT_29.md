# Architecture audit and regression inventory

Issue [#29](https://github.com/jessicaleigh333/TheAllotment/issues/29). Initial source review of [main at 861f686](https://github.com/jessicaleigh333/TheAllotment/commit/861f686a688e4e45172e2c6e859f94f96860f007). Paths in the architecture map are relative to `the-allotment-garden-world-v-02/` unless identified as repository paths.

## Architecture map

| Area | Entry points and data flow |
| --- | --- |
| Startup and world | `project.godot` opens `features/title/title_screen.tscn`. The title script uses the local profile index and device-wide `title_settings.cfg`. The playable `main.tscn` instantiates `scripts/courtyard_world.gd`, which extends `scripts/world.gd` and configures the player, collision, placement, lighting and vault. F6 on the world is the direct preview. |
| Placement, inventory and plants | `features/market/catalog.gd` supplies stable item IDs. `garden_placement.gd` controls placement and restoration. Market and Backpack share the market UI and persistence. `market_store.gd` validates version-1 `market.json`, including stacks, favorites, placements, growth records and support graph. `plant_growth.gd` uses elapsed UTC time, with 86,400 seconds per growth day. |
| Profiles and recovery | `features/profiles/local_profiles.gd` has an index at `user://profiles/index.json` and scopes saves to `user://profiles/<id>/`. The first profile copies legacy files. `features/vault/local_vault.gd` restores position/camera from version-1 `session.json`, flushes market and landscaping, and rotates verified `vault/latest.zip` and `vault/previous.zip`. Each file is written separately. |
| Environment and data | `main.tscn` creates `features/weather/weather_system.gd`, a deterministic daily forecast keyed by neighborhood seed and UTC day. Courtyard lighting follows that clock and has manual previews. The garden editor stores profile-scoped landscaping under `ground_cover/`. Botanical reference data and the repository's `tools/item_catalog/` catalog pipeline are distinct from the runtime placement state. |
| Tests and build | Godot script-based checks live under `tests/`, including `verify_local_vault.gd`, `verify_local_profiles.gd` and `verify_profile_entry.gd`. The Windows Desktop x86-64 preset exports an external PCK. Repository paths `distribution/` and `.github/workflows/windows-beta.yml` house the launcher and manual Windows build workflow. |

## Risk and regression inventory

| Priority | Risk | Existing evidence and acceptance check |
| --- | --- | --- |
| P0 | Engine and export version drift | The project declares Godot 4.7 Compatibility while the Windows workflow pins 4.6.3. Record fresh import, title/world startup and Windows export with the intended runtime. |
| P0 | Save loss during migration, interruption or update | Dedicated profile and vault checks cover migration/isolation, checkpoint and corrupt-file preservation. Verify interruption between file writes, ZIP rotation and native Windows save continuity across update and rollback with disposable profiles. |
| P1 | Real-time growth diverges from offline growth or previews | Existing growth tests are referenced in the growth documentation. Compare equal elapsed time online/offline, clock rollback, catalog stage transitions, retrieval/replant age and saved vine reconstruction. |
| P1 | Terrain changes break protected routes or saved placement | Compare divergent lawn/cobblestone branches against current world and editor. Exercise nine garden entrances, collisions, area restrictions, protected paths, saved rotations/supports and landscaping reopen. |
| P1 | Harvest or plant health changes break inventory persistence | Establish the current live harvest and care entry points before proposing changes. Verify inventory deltas and save/reopen with stable item IDs. |
| P2 | Reference data and gameplay IDs diverge | Run botanical coverage and catalog export checks before extending IDs. Verify compatibility with legacy names and saved IDs. |

## Open pull requests and order

GitHub listed #1–#16, #18, #22–#27 and #31 open at review. Changed filenames show substantial overlap across the older gameplay PRs. The November integration review identifies the Windows branch as the historical cumulative branch and #16 describes a dependency on #15, itself stacked on #14. Current main already contains the Windows workflow, vault, profile flow and climbing documentation. GitHub comparison confirms `codex/windows-launcher-updater` is 0 ahead and 14 behind current main. Its tip `473e2ab` is the merge base. No gameplay stack port is needed from that tip. Coordinate Windows verification with [#16](https://github.com/jessicaleigh333/TheAllotment/pull/16).

- [#18](https://github.com/jessicaleigh333/TheAllotment/pull/18) changes botanical paths. Compare its remaining delta with the foundation tracked under #20 before porting records or loaders.
- #22–#27 each changed one item concept document. Review individually as design proposals.
- [#31](https://github.com/jessicaleigh333/TheAllotment/pull/31) changes `AGENTS.md` and can be reviewed independently. [#28](https://github.com/jessicaleigh333/TheAllotment/pull/28) is already merged at the pinned baseline, despite the historical backlog entry.
- Verify current main first, then compare branch ancestry and overlapping terrain changes. Review only the remaining gameplay deltas. Gate Windows readiness on native evidence and keep design reviews independent.

## Terrain branch comparisons

| Branch | Ahead / behind main | Remaining review |
| --- | --- | --- |
| `codex/cobblestone-garden-paths` | 3 / 33 | Adds cobblestone script/shader alongside lawn changes and includes a temporary scene and generated editor files. |
| `codex/soft-grass-ground` | 1 / 33 | Changes the same lawn script, both grass shaders, world script and project settings. |

Both diverged from `607ccc3`. Compare the shared lawn files with each other and port only any desired behavior still absent from current main. Verify terrain and interaction regressions on a fresh baseline before integration.

## Verification at this milestone

GitHub resolved the current main SHA and served the inspected source files at that revision. The workspace reports Godot 4.6.3. The local Git checkout is older, and the main fetch has yet to finish. Godot import, runtime tests, full tree inventory, remaining PR ancestry and native Windows checks remain open. Treat earlier PR test results as historical evidence.

## Next priorities

1. Finish getting the pinned tree locally. Inventory existing test and build entry points and record exact commands and results with isolated save directories.
2. Compare remaining PR tips and terrain implementation overlaps. Use the verified Windows branch ancestry to avoid duplicate gameplay work.
3. Use the verified results to order remediation. Prioritize save continuity and the engine/export baseline before gameplay changes.
