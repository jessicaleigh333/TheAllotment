# Botanical knowledge library — v1
This is the canonical **research/knowledge data layer** for all 12 existing plant IDs in `features/market/plant_growth.gd`. It is **not yet the live growth engine**. It is intentionally additive and does not alter old saved games or the current real-time timer.

## Data contract
- `botanical_library.json` contains an `entries` array keyed by stable `id` matching the current shop and growth IDs. The existing seed packet IDs `sunflower_seeds` and `basil_seeds` resolve via the preexisting growth code, not as separate biological species.
- `identity` holds verified naming scope; cultivar is **null** until known.
- `biology` describes life cycle, propagation and broad flowering season.
- `environment` stores broad requirements and explicit nulls for values not yet justified. Never replace nulls with invented numbers; use documented ranges tagged to cultivar/region/source.
- `health` holds risk tags, **not** automatic diagnoses. Observing insects alone is insufficient to prove a plant was weak, and some herbivory occurs on healthy plants.
- `management` stores practical care. Yield is null until a documented plant-specific model exists.
- `gameplay.legacy_growth_stage_days` reproduces existing real-day values without claiming they are biological constants. Actual growing phases depend on propagule type and environmental conditions.
- `louise` provides short teaching prompts, separate from scientific claims.
- `evidence` supplies starting references for checking assumptions and future citation per field; its review status is deliberately not "verified".

## Next integrations for Codex
1. Create a small Godot `BotanicalLibrary` loader that reads JSON, validates all IDs, rejects duplicate IDs, and provides `get_species(id)` with an empty result for unknown IDs.
2. Compare IDs with `plant_growth.gd` and catalogue species. Keep decorative assets outside botanical simulation. Add regression coverage for all 12.
3. Extend fields with source-specific evidence objects and reviewed date **before** changing physical simulation.
4. Introduce independently persisted plant states: site moisture/drainage, season/dormancy, damage/recovery, bloom stage, seed/fruit set, viable harvest and propagation. Make offline updates deterministic, bounded and save-compatible.
5. Add a plant diary entry on natural life-cycle completion, stress or pest observation, with investigation options rather than a magical automatic diagnosis.
6. Create cultivar-specific templates for all future plants; regional invasive or toxicity checks should reference actual location.
7. Calculate mature width/height from cultivar profiles; legacy render meshes are placeholders and should not define botanical maximums.
8. Validate with academic extension resources and local regional guidance before claiming climate, soil pH, cultivar susceptibility or yield ranges as facts.

## Research starting points
University extension information (Maryland, Minnesota, Oregon State, Missouri), RHS horticultural profiles, and local extension guidance. Entries contain URLs to source leads. Avoid automatically inheriting whole-species traits from one cultivar profile. All 12 entries remain in **initial reference mapping** state until reviewed field-by-field.

## Safety and philosophy
Reward correct observation, careful site choice and sustained care, not deliberate mortality. Annual senescence and perennial dormancy are not automatically plant murder. Separate insects that feed on plants, insects that pollinate them, and diseases caused by pathogens. Do not promise eradication, guaranteed recovery or exact harvest amounts.
