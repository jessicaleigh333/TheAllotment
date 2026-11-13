# The Allotment — Codex Handoff & Prioritized Backlog
Updated: 2026-11-13
Status: planning handoff; no gameplay implementation authorized by this document.
Source of decisions: owner discussions during Codex usage pause, 2026-11-12–13.

## Read first and preservation rules
- Follow `AGENTS.md` and `THE_ALLOTMENT_GAME_DESIGN.md`. Preserve approved lush, softly stylized storybook art, French-neighborhood design, existing terrain, grass, stone pathways, scenes, UI and player progress.
- Inspect the **actual current branch, files, scenes, autoloads, plugins, save format, and working builds** before treating any item as missing. Design documentation is not implementation evidence.
- Work in feature branches/PRs; no direct main merges, destructive rewrites, asset replacements, unapproved new costs, or speculative claims of test success.
- Before each change: document dependencies, snapshot known-good release, test relevant existing behavior, explain migration/rollback. Never overwrite sole valid save.
- Prioritize Windows playable build and updater reliability before expanding gameplay. Do not infer the updater is secure or functioning because it was once described as working.

## P0 — FIRST: Codex → ChatGPT development handoff bridge (owner's top priority)
**Goal:** minimize duplicated explanations and Codex usage. Keep using existing Codex Cloud on iPad; publish a concise, authorized handoff to a GitHub location the user's ChatGPT assistant can read. This takes precedence over other backlog tasks because it improves coordination across subsequent work.
- **Feasibility first, no plugin:** verify Codex Cloud can write a handoff to an accessible GitHub branch/location during or at the end of a task. Test with a small sample and verify ChatGPT can retrieve it. Do not assume background processes or minute-by-minute pushes are supported.
- **Conversation context:** capture available owner instructions and Codex replies, decisions, clarifications, and outstanding questions accurately. Preserve speaker labels, sequence, and timestamps where available. Do not claim access to conversations/messages Codex cannot export; do not invent or reconstruct verbatim dialogue.
- **Status report:** current task, recent actions, files changed, tests actually run/results, blockers, next steps, UTC last-updated time, task/session identifier and commit/PR references. Distinguish observed facts from summaries or estimates.
- **Low-token design:** prefer a small structured `CHATGPT_HANDOFF.md` at milestones/end of task; optionally `status.json` and append-only `conversation.jsonl` when supported. Avoid repeated AI summarization, one-minute commit spam, or extra reasoning calls. Evaluate lightweight scripted heartbeat (1–5 minutes) only if the Cloud environment supports it without slowing coding or creating noisy Git history.
- **Privacy/security:** TheAllotment repository is public. **Never publish private conversation transcripts, credentials, personal data, or unpublished sensitive details there.** Use an approved private, access-controlled repository/location for dialogue, verify ChatGPT connector access, and redact secrets. Public repo may contain only a deliberately sanitized status report.
- **Non-disruption:** read-only feasibility check before changes; no game code, updater, release workflow, or default branch changes. Work on an isolated branch/PR and seek approval for external publishing or new credentials. Do not build a separate plugin unless this lightweight approach proves inadequate.
- **Future scope:** apply the same reporting pattern to Scholarship Hunter in its own project after a successful Allotment pilot. A general-purpose ChatGPT Companion plugin/help-desk integration is deferred, not part of the current game implementation.
**Acceptance:** owner can say “Chat, catch up on The Allotment,” and ChatGPT retrieves an up-to-date, authorized handoff with recent conversation context and verifiable development status; clearly display last-update time and acknowledge any lag. Start with end-of-task/milestone reporting, then assess more frequent updates. Owner will share any OpenAI support reply about official Codex Cloud access.

## P0 — Windows build, distribution and updater recovery
**Goal:** reliably install and play on another Windows PC (including daughter's PC), and update safely.
- Locate and diagnose broken/expired download link, export pipeline, packaged Godot runtime, install path, game vault/save path and existing auto-updater. Distinguish link hosting failure from updater failure.
- Provide repeatable Windows export, versioned artifact, release manifest, download/installation instructions, error messages, fallback/manual install, rollback and recovery.
- Audit update trust: HTTPS, authenticated signed manifest/packages or equivalent robust authenticity verification, hash verification, safe extraction/path validation, no executable from untrusted source, atomic replacement, retry/recovery, rollback. Avoid embedded secrets.
- Clarify what Codex can publish automatically vs what requires explicit release approval. Don't silently push updates to players.
**Acceptance:** fresh Windows install launches; upgrade from older build preserves saves; interrupted/tampered update fails safely; old release recoverable; download link actually verified.

## P0 — Non-destructive architecture, security and test audit
**First deliverable:** written inventory and prioritized risks before any refactor.
- Map scene/script/autoload dependencies, Godot version, render/update loops, simulation clock, weather, plant data, UI, save/load, catalog, diary, plugins and release workflow.
- Document existing protections and missing tests. Inspect performance for large gardens and avoid per-frame full plant simulations.
- Establish regression checks: Godot headless import/parse, startup, scene navigation, world visuals, plant state, harvesting/inventory, diary, Louise, save/load, updater.
- Validate external input and paths, privacy-safe bug reporting, secrets/dependency scanning, release signing approach, crash handling.
- Require known-good checkpoints, isolated PRs, change-impact review, smoke tests and rollback plan. Tests only count if executed.
**Acceptance:** audit with evidence, risk ranking, no unintended changes to gameplay.

## P1 — Plant health and survival model (scientifically grounded)
- Reconcile any existing prototype with current implementation. Do not replace functioning mechanics blindly.
- Per-plant identity/species/cultivar, location/bed, stage, age, accumulated thermal time where supported, size, vigor, health/stress factors, soil moisture exposure, light, nutrient/root constraints, frost/heat exposure, disease/pest status, flowering, fruit, seed, dormancy, senescence and mortality.
- Species-specific parameter sets and sources (university extension, peer-reviewed horticulture, authoritative botanic institutions); distinguish measured values from gameplay assumptions. Review units and regional applicability. No universal arbitrary percent growth.
- Differentiate annual/biennial/perennial, bulb, woody plant, dormant vs dead; drought, waterlogging, freeze, heat, recovery and irreversible loss. Account for seedling sensitivity.
- Visual inspection advice must match actual simulation state and be explainable via Growing Guide/Louise.
**Acceptance:** reproducible test cases for well-watered vs dry vs waterlogged, cold, dormant, dead, recovery, seedling and species variation.

## P1 — FULL REALISM: real-time clock and offline catch-up (owner-approved)
**Non-negotiable design decision:** 1 real-world hour = 1 in-game hour; time continues while app closed. No artificial watering, pause, immortality, or guaranteed recovery during absence. Death is allowed. Distinguish biological consequences from software failures.
- One simulation engine for online and offline, with deterministic/replayable inputs and consistent results. Save last *committed* simulation UTC timestamp, timezone/calendar rules, weather RNG seeds/history and version.
- On reopening, compute elapsed time; reconstruct or replay weather/environment chronologically; update soil/water, plant physiology, phenology, disease, reproduction, ripeness/overripeness, dropped fruit, decay, death and possible seed persistence/germination.
- Suggested cadence: visual effects per frame, environmental integration hourly or finer if justified, daily biological milestones; event-driven watering/harvesting. Cadence must be validated, not blindly fixed. Use bounded chunks and responsive progress for long absences, never discard days for speed.
- Handle DST/timezone changes, backward/implausible clock changes with clear warning and safe recovery (don't silently simulate bogus time); offline-only device clocks are not tamperproof. Record uncertain causes honestly.
- Checkpoint before catch-up; transaction/atomic commit after validated chunks; idempotent resume after crash, no double growth. Preserve previous save and migrate old schemas.
- Automatically write dated events to Garden Diary; return report summarizes growth, harvest readiness, losses and causes.
**Acceptance:** 1/7/14/60-day offline scenarios; offline vs uninterrupted online equivalence for identical conditions; crashes during catch-up; clock changes; no duplicate event entries; old save loads.

## P1 — Environment, seasons, weather and soil
- Seasonal daylight/temperature, rainfall, irrigation, evaporation, drainage, waterlogging, soil moisture and temperature. Share environment calculations by zone/bed while retaining per-plant effects.
- Region/climate and weather-source selection must honor existing game design; do not assume real-world live weather API or location without owner approval. Offline weather must be reproducible and available without network.
- Frost, hardiness, dormancy, spring emergence, overwintering, fruit drop, natural seed set and volunteer seedlings as appropriate.
- Scientific review with explicit sources, confidence and limitations.
**Acceptance:** wet/dry/frost/seasonal scenarios and consistent offline replay.

## P1 — Harvesting, inventory and persistence
- Harvest eligibility, yield/quality, ripening windows, overripening/spoilage, seed collection and realistic consequences of missed harvests.
- Connect garden interactions to backpack/inventory, stack counts, cottage storage, selling/using items and catalog; honor existing permissions (visitors may help with care only where allowed; owner-only planting/harvest/pruning per design).
- Transactional item transfer: no duplicate or lost items on save, crashes or repeated actions.
- Test upgrades and backwards compatibility before shipping.
**Acceptance:** plant -> harvest -> inventory -> storage/use/sell -> save/reload roundtrip.

## P2 — SQLite botanical knowledge library
- Evaluate existing data storage first. Proposed offline, searchable SQLite **reference catalog**, distinct from transactional player save data unless a deliberate migration is approved.
- Long-term goal: ~10,000 researched species/varieties, built in verified batches; don't imply the database already contains 10k.
- Schema: stable IDs, scientific/common names, synonyms, plant type, climate/hardiness, growth/soil/light/water, propagation, germination, harvest, disease risks, safety notes where relevant, source URL/citation, review date, confidence, provenance and version.
- Search by keyword, name, synonyms, category, owned-only and filters; indexes, schema migrations, Godot/Windows packaging and performance tests.
- Keep botanical facts separate from balancing and from individual saved plants. Avoid copyrighted bulk scraping and unsupported scientific assertions.
**Acceptance:** offline search, data validation, duplicate/synonym tests, reliable packaging and update migration.

## P2 — Louise's gardening knowledge and help
- Preserve existing Louise scenes, voice/personality, dialogue and visual style.
- Answer both gardening questions and *how to play* questions, grounded in catalog and current plant state when available; distinguish real horticulture from game-specific mechanics.
- Provide practical care advice, diagnose common symptoms with uncertainty, explain water, soil, seasons, harvest, and what happened while away.
- Design fallback for unknown questions; no unsupported promises of fully open-ended AI without explicit approved backend/privacy/cost architecture.
**Acceptance:** representative question suite, accurate sourced guidance, graceful unknowns and no regression in existing dialogue.

## P2 — Growing Guide and How to Play
- Growing Guide: searchable species care, requirements, growth stages, problems, propagation, seasonal guidance, sources; deep-link from plant inspection and Louise.
- How to Play: first-time orientation, movement/camera, planting, watering, plant inspection, harvest, inventory, diary, offline progression, social/visitor permissions and save/update behavior.
- Integrate with existing menus rather than duplicate screens. Keep readable and accessible.
**Acceptance:** new player can complete core garden loop without outside instructions.

## P2 — Garden Diary, calendar and keyword search
- Diary is **also a calendar**, with dated player notes and automatic plant/weather/harvest/death events, historical timeline, searchable keywords and filtering.
- Persist entries across updates, maintain correct dates/time zones, link to plant IDs where possible; do not lose entries if plant dies or is removed.
- Design return-from-absence summary with factual event chronology and plant-specific causes, no fabricated certainty.
- Support useful long-term history and backups; don't assume cloud sync.
**Acceptance:** create/edit/search entries, browse calendar, offline event catch-up, reopen and old-save migration.

## P3 — Quality, scale, playtesting and later platforms
- Profile 100/1,000/5,000+ plants; avoid per-frame biology; chunk catch-up; test memory, UI responsiveness and loading.
- Windows first. Other Windows testers should receive independent installs with independent local saves and explicit updater release policy.
- Later assess browser/iPad, console certification, controller support, platform approvals, achievements, accessibility and licensing **as separate feasibility work**, not as current build promises.
- Bug-report button: evaluate opt-in privacy-safe reports routed to developer triage/GitHub issue workflow; do not assume direct unrestricted Codex task creation or upload private save data.
- Preserve peaceful gardening, realistic learning, established art direction, and no real-money requirement. Avoid speculative monetization.

## Execution order and handoff protocol
1. **First: handoff bridge feasibility and minimal pilot** on isolated branch/private storage as appropriate; verify ChatGPT can retrieve the report and dialogue safely. Do not spend Codex usage on a full plugin.
2. **Audit only:** inventory actual repository and current build/updater; report what exists, what's missing and severity.
3. Fix Windows delivery/updater and establish reliable build + recovery checkpoint.
4. Add baseline regression tests, save protections, migration strategy.
5. Integrate shared time/environment/plant simulation, then full offline catch-up in small PRs.
6. Integrate harvest/inventory and diary event stream.
7. Expand sourced SQLite catalog, Louise and help content in staged batches.
8. Performance, playtesting and release hardening.

For each PR report: existing functionality preserved; files touched; reason; tests actually run and results; save migration implications; manual steps to verify; screenshots when visual; rollback procedure; open risks. No automatic merge to main.
