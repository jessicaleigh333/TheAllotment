# Botanical Library → Codex Construction Contract (v1)
Status: implementation specification; additive to existing botanical_library.json; no live behavior implied until integrated and tested.

## Two linked products
1. Botanical truth record: species/cultivar identification, physiology, ecology, reference URLs and verification confidence. Unknowns remain null.
2. Build contract: Codex converts *reviewed* facts into scripts, persistent state, visuals, actions, feedback, rewards and automated tests. Gameplay interpretations are separately labeled and adjustable.

## Required per-plant implementation layers
- **Identity and scope**: species/hybrid/cultivar, alternate common names, region, provenance, stable shop ID. Never apply a cultivar property to all roses or apples.
- **World model**: scale in metres, plant architecture, seasonal meshes/materials, stage transitions, flowers/fruits and animation requirements. Describe where assets are placeholders.
- **Time model**: 1 real-world day = 1 elapsed day, including offline time; climate/hemisphere/local calendar and winter dormancy are separate from age. No accelerated harvests. Stage thresholds are adjustable assumptions, not facts.
- **Inputs**: sunlight/daylength, temperature, soil moisture, drainage, soil texture, pH, nutrients, competition, frost, pruning, pollination and pests; do not simulate unknown data as verified numbers.
- **State**: permanent plant ID, cultivar, location, propagation type, chronological age, physiological development stage, seasonal phenology, biomass/size, health factors, reserves, damage, reproductive structures, cumulative yield, dead/alive/dormant. Persist through saves and offline updates; include migrations for old files.
- **Outputs and mechanics**: growth, wilt, leaf color, bud/flower/fruit, mature yield, seed viability, senescence, recovery, perennial continuation; item inventory transactions and shop economic balance. For trees, multiyear juvenile phases and cumulative harvest must be supported.
- **Diagnostic teaching**: evidence-based observation prompts and a *differential diagnosis*, not a guaranteed one-cause popup. Healthy plants may host insects. Natural annual senescence and dormancy are not necessarily failures. Record player observations and discoveries in searchable Garden Diary.
- **Reward guardrails**: reward observation, maintenance, growth stages, flowering, successful harvest and learning. Never reward intentionally killing plants or encourage exploit loops. Yearly orchard harvests can be economically meaningful without artificially shortening time.
- **Local ecology & safety**: invasiveness by region, pollinator/host relationships, toxicity, seed dispersal, and cold-hardiness; environmental suitability should not overwrite documented facts.
- **Evidence**: attach field-level source, URL, accessed/reviewed date, confidence and applicability (species/cultivar/region). If evidence insufficient, leave unimplemented or explicitly mark as game balance.
- **Acceptance tests**: JSON schema valid, every live plant shop ID mapped, no duplicated stable IDs, deterministic elapsed-time and save migration tests, correct annual/perennial/dormancy behavior, environmental limit tests, harvest inventory consistency, no false-certain pest diagnosis, no reward-for-killing, performance with many plants.

## Codex delivery checklist per species
For every species added:
1. Create/update botanical record, citations and uncertainties.
2. Write a short **species gameplay specification**: mechanics, input values and units, architecture/phenology animation needs, soil and climate responses, harvest/proliferation, interactions, alerts and diary entries.
3. Map record fields to Godot resources/scripts with precise paths; supply schema version/migration plan.
4. Implement changes on a feature branch; never overwrite another in-flight branch without review.
5. Add deterministic unit/integration tests, check offline time, run headless Godot project validation, and inspect in-game visuals/screenshots when environment permits.
6. Report precise paths, commit, test commands/outcomes, screenshots, unverified claims and known limitations to shared development reporting, including decisions and owner–Codex dialogue where available and approved.
7. Open PR for review; do not claim a fact, feature, or test was verified when it was not.

## Example: apple tree
Botanical source: cultivar/rootstock, chill and heat requirements, compatible pollination partners, juvenility, fruit size/number, alternate bearing, disease susceptibilities and seasonal bud phases.
Godot design: saved tree-age in years; separate chill accumulation, spring bloom, pollination, fruit set, fruit growth, autumn leaf senescence, winter rest; compatible cultivar pollination checks; persistent yearly harvest counts and inventory; optional pruning effects grounded in horticulture.
Art: bare winter form, buds, leaf-out, blossoms, developing fruit, ripe fruit, autumn colors. Show absence of bloom on juvenile trees without declaring a disease.
Tests: no apples before supported fruiting age; no fruit without necessary pollination if cultivar requires it; realistic season check; save/offline continuity; no double harvest; year-on-year produce sale with no game-clock compression.
All numbers must be cultivar- and site-calibrated later; don't invent thresholds.

## Architectural boundaries
- botanical_library.json is read-only scientific/educational data.
- New gameplay config should be separate (e.g., `data/botanical/gameplay_profiles/`), keyed by stable botanical IDs and versioned.
- Existing `features/market/plant_growth.gd` remains authoritative until migration and tests approve replacement. No automatic behavior change from adding a library record.
- Preserve current shop IDs, seed aliases, saves and existing game assets.
- Maintain user-selected real-time growth and owner approval for visual changes.
