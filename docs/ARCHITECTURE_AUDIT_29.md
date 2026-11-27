# Architecture audit and regression inventory

Issue [#29](https://github.com/jessicaleigh333/TheAllotment/issues/29). Source and runtime audit of [main at 861f686](https://github.com/jessicaleigh333/TheAllotment/commit/861f686a688e4e45172e2c6e859f94f96860f007). Paths in the architecture map are relative to `the-allotment-garden-world-v-02/` unless identified as repository paths.

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

## Remote branch inventory

Fetched all 35 named heads and matched the 24 open PR heads. Counts show commits unique to the branch and to `main`, respectively. Paths are the branch-side diff from the merge base. The snapshot predates the publication of this report.

| Branch | Tip | PR | Ahead / behind | Paths |
| --- | --- | --- | --- | --- |
| `codex/29-architecture-audit` | `5960c84` | [#32](https://github.com/jessicaleigh333/TheAllotment/pull/32) | 4 / 0 | 11 |
| `codex/ai-handoff` | `2b052db` | — | 0 / 1 | 0 |
| `codex/animated-garden-title` | `881b79b` | [#2](https://github.com/jessicaleigh333/TheAllotment/pull/2) | 0 / 28 | 0 |
| `codex/botanical-database-foundation` | `dff9542` | — | 0 / 9 | 0 |
| `codex/cobblestone-garden-paths` | `d5e3ea8` | — | 3 / 33 | 22 |
| `codex/detailed-garden-assets` | `4188beb` | [#8](https://github.com/jessicaleigh333/TheAllotment/pull/8) | 0 / 22 | 0 |
| `codex/free-inner-circle-decorating` | `921df05` | [#6](https://github.com/jessicaleigh333/TheAllotment/pull/6) | 0 / 24 | 0 |
| `codex/french-garden-structures-collection` | `c8ab5d2` | [#10](https://github.com/jessicaleigh333/TheAllotment/pull/10) | 0 / 20 | 0 |
| `codex/garden-gates-rock-walls` | `bb64cd1` | [#9](https://github.com/jessicaleigh333/TheAllotment/pull/9) | 0 / 21 | 0 |
| `codex/garden-market-backpack` | `e689c57` | [#5](https://github.com/jessicaleigh333/TheAllotment/pull/5) | 0 / 25 | 0 |
| `codex/master-item-catalog` | `e5138bc` | — | 0 / 7 | 0 |
| `codex/real-time-plant-growth-scale` | `6b92fb5` | [#7](https://github.com/jessicaleigh333/TheAllotment/pull/7) | 0 / 23 | 0 |
| `codex/real-time-vines-local-vault` | `5fd6128` | [#15](https://github.com/jessicaleigh333/TheAllotment/pull/15) | 0 / 15 | 0 |
| `codex/roman-columns-vertical-building` | `f18afb4` | [#11](https://github.com/jessicaleigh333/TheAllotment/pull/11) | 0 / 19 | 0 |
| `codex/rustic-board-inspired-gardens` | `6494256` | [#13](https://github.com/jessicaleigh333/TheAllotment/pull/13) | 0 / 17 | 0 |
| `codex/seasonal-title-local-profiles` | `204b269` | [#3](https://github.com/jessicaleigh333/TheAllotment/pull/3) | 0 / 27 | 0 |
| `codex/sidewalk-ramps-plant-catalog` | `3e25092` | [#1](https://github.com/jessicaleigh333/TheAllotment/pull/1) | 0 / 29 | 0 |
| `codex/soft-grass-ground` | `1eebec6` | — | 1 / 33 | 9 |
| `codex/title-night-glow` | `d259460` | [#4](https://github.com/jessicaleigh333/TheAllotment/pull/4) | 0 / 26 | 0 |
| `codex/windows-launcher-updater` | `473e2ab` | [#16](https://github.com/jessicaleigh333/TheAllotment/pull/16) | 0 / 14 | 0 |
| `codex/witchy-fairy-night-garden` | `f0bfe64` | [#12](https://github.com/jessicaleigh333/TheAllotment/pull/12) | 0 / 18 | 0 |
| `codex/woodland-gathering-play-scenery` | `52cb1ca` | [#14](https://github.com/jessicaleigh333/TheAllotment/pull/14) | 0 / 16 | 0 |
| `codex/woody-real-life-growth` | `a1dff5d` | — | 0 / 11 | 0 |
| `docs/backlog-dispatch` | `741e6f5` | [#31](https://github.com/jessicaleigh333/TheAllotment/pull/31) | 1 / 0 | 1 |
| `docs/codex-backlog-nov-2026` | `2d05b7d` | — | 2 / 31 | 1 |
| `download/updated-garden-preview` | `22411ec` | — | 0 / 30 | 0 |
| `feature/botanical-knowledge-library-v1` | `e871372` | [#18](https://github.com/jessicaleigh333/TheAllotment/pull/18) | 33 / 12 | 33 |
| `feature/curved-library-conservatory-design` | `3f5061f` | [#24](https://github.com/jessicaleigh333/TheAllotment/pull/24) | 1 / 6 | 1 |
| `feature/greenhouse-atrium-concept` | `16356ff` | [#22](https://github.com/jessicaleigh333/TheAllotment/pull/22) | 3 / 6 | 1 |
| `feature/lookout-fire-tower-design` | `b2912cf` | [#23](https://github.com/jessicaleigh333/TheAllotment/pull/23) | 1 / 6 | 1 |
| `feature/victorian-glass-rotunda-design` | `d486c58` | [#26](https://github.com/jessicaleigh333/TheAllotment/pull/26) | 1 / 6 | 1 |
| `feature/victorian-lantern-conservatory-design` | `5b39d69` | [#25](https://github.com/jessicaleigh333/TheAllotment/pull/25) | 1 / 6 | 1 |
| `feature/vintage-aframe-brick-greenhouse-design` | `a548203` | [#27](https://github.com/jessicaleigh333/TheAllotment/pull/27) | 1 / 6 | 1 |
| `integration/nov-2026-game-review` | `7e3e6c4` | — | 0 / 13 | 0 |
| `main` | `861f686` | — | 0 / 0 | 0 |

## Conflicts, dependencies and integration order

1. **Keep `861f686` as the baseline.** PRs #1–#16, the November integration branch and the preview branch all have tips reachable from main. The cumulative Windows tip includes #15's climbing/vault work and earlier gameplay. GitHub still lists those PRs open. Verify or administratively reconcile them individually. The Windows verification in #30 should start from current main with #16 as the implementation reference. The master catalog (#21), botanical foundation (#20), and handoff (#28) are already included.
2. **Review reporting changes independently.** #32 and #31 individually merge cleanly against the pinned main. #31 introduces a human-readable dispatch procedure. An issue comment does not arbitrate concurrent claims, and the backlog does not expose structured issue IDs and dependency states for every dispatchable item. The #31 review requests a machine-readable queue, one-winner claiming and concurrent-claim verification before unattended use. The divergent November backlog branch is reference material for the current handoff, with one documentation path and no textual conflict.
3. **Verify Windows before shipping.** Keep the application name, profile IDs, vault schema and launcher data root stable. Run native Windows install and update tests with a disposable copied profile. Check both an update and rollback can reopen the same profile, including supported placements and elapsed plant growth. Keep build/key configuration, artifact integrity and the public channel as distinct release gates.
4. **Prototype terrain on main.** The lawn commit `1eebec6` is shared ancestry, so do not apply both branches. Lawn conflicts in `scripts/world.gd`; cobblestone additionally conflicts in `main.tscn` and five deleted editor cache paths. Cobblestone uses a fixed approximately 78 m grid with lanes at ±11 m, while the current courtyard uses nine radial paths to the gardens. Its stone mesh/material are candidates for reuse after owner visual approval. Use current courtyard transforms and placement surfaces, preserve the nine entrances, and exclude the old temporary scene and editor cache. Baseline main tracks zero `.godot/` or `.tmp` paths. Godot generated some previously untracked `.import` and `.uid` sidecars locally.
5. **Review #18 as supplemental data.** Git can merge its tip cleanly, but the 33 added paths include a separate `data/botanical/botanical_library.gd` and generated master registry/review exports. Its old loader and starter records coexist with the merged `data/botanical/library/` data and tools. Compare IDs, duplicate candidates, provenance and owner approval before importing records via the current foundation. No live recipe, catalog ID or save should be rewritten in a bulk import.
6. **Review #22–#27 in parallel.** Each changes a distinct concept document and merges cleanly against main. Track dimensions, model approval, collision and playable placement separately. None adds a playable structure at its audited tip.

Conflict checks used `git merge-tree --write-tree --name-only --no-messages origin/main <ref>`. A clean merge checks Git's ability to combine trees. Runtime and data compatibility still require the checks above.

## Godot baseline

Official Godot **4.6.3.stable.official.7d41c59c4**, Linux, detached main at `861f686`. Every run used separate empty `XDG_DATA_HOME`, `XDG_CONFIG_HOME` and `XDG_CACHE_HOME`; no player files were read or modified. Run the following from the repository root. Give each test its own directory.

```sh
isolated="$(mktemp -d)"
export XDG_DATA_HOME="$isolated/data" XDG_CONFIG_HOME="$isolated/config" XDG_CACHE_HOME="$isolated/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
game=the-allotment-garden-world-v-02
godot --headless --path "$game" --editor --import --quit
godot --headless --path "$game" --quit-after 60
timeout 150 godot --headless --path "$game" --script res://tests/verify_local_vault.gd
```

| Check | Result |
| --- | --- |
| Fresh editor import | Exit 0. No script parse errors found. Editor TCP listener failed in the sandbox, and the HDR importer ignored optional metadata. |
| Title startup for 60 frames | Exit 0 with an ObjectDB cleanup warning. |
| 24 headless game scripts in `tests/` | PASS, each exit 0 with its own PASS marker. Avatar, climbing vines, courtyard decor, editor interaction, enchanted collection, French collection, garden art, garden boundaries, ground cover, item catalog, layouts, local profiles, local vault, market, plant growth, profile entry, real scale, rustic collection, sidewalk, title, vertical building, weather, woodland collection and woody growth. |
| `ui/verify_hud.gd` | **FAIL** at line 35. The fixture expects non-weather destinations to be Labels, while Settings now instantiates a VBoxContainer with vault controls. The assertion prevented the script from reaching its normal quit. The dedicated profile, vault and weather checks passed separately. Update the HUD regression to assert the intended concrete destinations and Escape behavior in a focused follow-up. |
| `tests/verify_ground_cover_rendering.gd` | Requires an OpenGL display. See graphical evidence status in the milestone. |
| Python handoff, item catalog and botanical foundation | PASS, 50 tests. Initial run had one missing CairoSVG error. Rerun with CairoSVG available passed all 50. Command: `python -m unittest tools.ai_handoff.test_handoff tools.item_catalog.test_catalog tools.botanical.test_foundation`. |
| Godot 4.7 and native Windows | Separate verification under #30 for Windows. No 4.7 executable was used. |

## Gameplay priorities

1. **Offline growth and save recovery.** Existing timestamp growth, age-preserving replanting and vault rotation pass isolated regressions. Add an end-to-end close/reopen scenario covering elapsed time, simulated interruption between market, landscaping and session writes, and rollback reads before introducing new persistent mechanics.
2. **Harvest-to-backpack.** The live catalog, plant growth, placement and Backpack are usable. The audited runtime has no connected harvest action. Start with one existing edible profile, persist harvest availability and inventory changes together, and verify repeat prevention, reopen and recovery.
3. **Plant care and environment.** The deterministic forecast and day/night loop already exist. The watering can is listed as decoration. Prototype opt-in watering and a small soil-moisture model on a single growing profile, then measure online/offline equivalence before adding seasonal stress or broader survival rules. Surface these mechanics through the guide only after the behavior is playable.
