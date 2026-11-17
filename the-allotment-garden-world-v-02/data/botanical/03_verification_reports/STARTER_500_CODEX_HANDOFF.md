# Botanical starter catalog — 500-record Codex handoff

**Status:** Research intake and visual prototyping reference, not scientific simulation approval.
**Branch:** `feature/botanical-knowledge-library-v1`
**Date:** 2026-11-16

## Canonical files

Read `01_scientific_records/starter_named_varieties_batch_001.json` through `starter_named_varieties_batch_009.json` (nine files). Combined catalog: **500 records**, **100 groups** and **500 unique IDs**. Batch counts: **60, 50, 50, 70, 70, 50, 50, 50, 50**.

These are separate from the existing botanical scientific records, the legacy 12 live plant IDs, and the recovered 18 rose cultivar profiles. Do not add these figures indiscriminately because cross-catalog taxonomic overlap is possible.

## For Codex: implementation contract

1. Build a read-only import/normalization layer for these nine starter files. Preserve original records and IDs verbatim, expose a stable catalog lookup and report malformed or repeated IDs. Do not overwrite the legacy live `botanical_library.json` or alter existing save IDs.
2. Treat `category`, `parent_taxon` / `scientific_parent` / `parent_scientific_name`, `family`, `growth_habit`, `visual_markers`, and the other descriptive fields as provisional. The nine batches have evolving schemas; normalize them into a shared model with explicitly optional properties and source-file provenance.
3. Use descriptive traits to guide **prototype visual variety** and broad growth archetypes only. Do not silently translate descriptions into quantitative days-to-maturity, chilling units, hardiness zones, water thresholds, yield rates, toxicology, native/invasive status, pollination certainty or cultivar disease resistance.
4. Preserve the distinction between species, horticultural groups, selections, nursery trade names, seed strains/mixes, hybrids and named cultivars. Some starter names are species/types or mixes rather than distinct registered cultivars. Resolve formal botanical/cultivar identity only after checking credible sources.
5. Do not generate 500 bespoke Godot scripts. Prefer reusable plant-archetype components and trait-based visuals, with overrides for genuinely different growth forms, fruits, foliage, flowers, lifecycles and harvesting.
6. Link every future construction specification to a stable starter record ID and to its own scientifically reviewed record when available. A starter record is **not** approval for a scientifically faithful simulation.
7. Test JSON parsing, missing-field resilience, stable ID retrieval, catalog group filtering, legacy save compatibility and deterministic outcomes for any modeled behavior. Report commands, results, failures, changed files, screenshots if rendering was actually inspected, and known limitations. Never claim a screenshot or runnable build without executing it.
8. Keep this handoff separate from the botanical scientific-record layer and the construction-specification layer, following `CODEX_CONSTRUCTION_CONTRACT.md`.

## Research follow-through

Perform field-specific identity and plant-care reviews in stages. Attach trustworthy sources for each reviewed claim and keep unknown quantitative fields null. Prioritize cultivars that will actually enter gameplay. Local toxicity and invasiveness rules require jurisdiction checks. The starter catalog alone is sufficient to plan variety and prototype geometry, not to deliver the promised realistic botanical mechanics.

## Verification scope

The nine GitHub files were fetched and parsed during catalog creation; counts, ID uniqueness, and presence of basic visual markers were checked: **500 entries, 500 unique IDs, zero duplicate IDs, zero missing basic visual markers, 100 recorded groups**. This **does not** mean taxonomic correctness or game-engine integration was validated.
