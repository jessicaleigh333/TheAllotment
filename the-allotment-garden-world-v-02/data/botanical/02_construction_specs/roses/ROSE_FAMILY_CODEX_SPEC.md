# Construction specification — Rose family, batch 001 + 002
**Stage 2: design instructions for Codex.** Scientific input: `../01_scientific_records/roses/recovered_rose_cultivars.json`. Applies to 18 recovered named cultivars. Do not treat this file as botanical evidence.

## Purpose
One reusable rose behavior component with cultivar override data, rather than 18 hard-coded growth scripts. Keep legacy `rose` and `climbing_rose` shop IDs and saves compatible.

## Required outputs
- Cultivar selector or catalog entries keyed by stable namespaced IDs, e.g. `rose-rosa-mundi`; never overwrite legacy `rose`.
- Modular rose mesh: cane skeleton, foliage clusters, buds, bloom form layers, rose hips where supported by cultivar, deadheads and seasonal appearance.
- Cultivar visual overrides for palette, petal layering, open/semi-double/quartered/rosette/cup form, blossom scale and clustering, plant stature, climbing support interactions and optional fragrance description.
- Phenology model: dormant -> leaf-out -> vegetative -> bud -> bloom -> post-bloom -> seed/hip where applicable -> seasonal dormancy. Keep chronological age and current phenology independent.
- Bloom schedule distinguishes once-blooming vs repeat-blooming when verified. A flower does not bloom continuously for years; flower production happens in cycles.
- Roses grow in actual elapsed time; progress must be saved, and offline processing must be deterministic. Never simulate years in minutes.
- Soil/site and health interfaces: moisture, drainage, sun, pathogen-pressure flags, temperature exposure and pruning history. Build interface first; no unsupported numerical damage formulas.
- Once-blooming Gallica/old-garden roses may need flowering-wood preservation and post-flowering pruning; repeat-flowering shrubs and climbers follow different class-appropriate schedules. Respect individual cultivar verification and climate.
- Climbing roses require training/ties to a support; they do not attach and twine independently. A climber form of a cultivar requires evidence and distinct visual architecture.
- Diary entries and Louise hints for observations, training, buds, pruning, setbacks, flowers, and annual return. Teach uncertainty: insects on leaves do not prove weak plants.

## Data-driven implementation proposal
- `res://data/botanical/01_scientific_records/roses/recovered_rose_cultivars.json`: research layer only.
- `res://data/botanical/02_construction_specs/roses/rose_family.md`: shared build rules (this file).
- Proposed runtime `res://features/plants/rose_profile_adapter.gd` maps reviewed research into versioned gameplay values, without editing scientific source records.
- Proposed `res://features/plants/rose_phenology.gd`: reusable rose state handling.
- Proposed `res://features/plants/rose_visuals.gd`: parameterized mesh/animation. Treat the recovered preview images as concepts only, not accurate game art.
- Proposed `res://features/plants/rose_diagnostics.gd`: observations and hypothesis prompts, not automatic exact diagnoses.
- Proposed `res://tests/verify_rose_library.gd`: ID coverage, source and data sanity.
These paths are **targets**, not claims of existing files.

## Implementation order
1. Read scientific data, validate IDs and map existing `rose` + `climbing_rose` without changing shop entries.
2. Propose parameterized Rosa visual prototypes: one once-flowering shrub, one repeat-flowering shrub, one trained climber.
3. Run Godot tests and compare look/scale in-game; obtain owner visual approval.
4. Add cultivar override profiles in small cohorts of 4–6, differentiating bloom appearance and plant form.
5. Add seasonal behavior with real timestamps, separate from age and using a chosen geographic climate model.
6. Connect care, health, flowering, propagation, harvesting and diary systems only after shared systems have acceptance tests.

## Rose-specific requirements
- Rosa Mundi: striped petals, open golden stamens; compact historic Gallica shrub; once flowering per recovered preview.
- Old Blush: loose blush-pink China rose with repeat flowering.
- Souvenir de la Malmaison: pale layered Bourbon cups; potential rain-related bloom damage is a research hypothesis requiring confirmation, not an automatic loss.
- Gertrude Jekyll: rich pink full rosettes; support a cultivar-approved shrub or trained form.
- Graham Thomas: golden cup flowers; branching, potentially trainable growth.
- Golden Celebration: large golden cupped flowers on arching shrub.
- Charles de Mills: deep purple quartered blooms, once flowering class; not automatically a climber.
- Celsiana: loose, semi-double pink blooms fading paler; open stamens.
- Fantin-Latour: blush double blooms, full petals.
- Louise Odier: bright pink scented cups in repeat-flowering Bourbon class; verify cultivar seasonal details.
- Mary Rose: loose pink double flowering shrub.
- Heritage: shell-pink cupped layered blossoms.
- Munstead Wood: dark crimson to wine-colored cupped blooms.
- The Pilgrim: pale yellow rosettes; shrub versus trained climbing form conditional.
- Abraham Darby: apricot-pink full flowers with pigment changes as blossoms age.
- Jude the Obscure: pale yellow-peach goblet-shaped blooms.
- Reine des Violettes: lilac-purple quartered double rosettes.
- Lady of Shalott: salmon/apricot flowers with contrasting yellow petal undersides.

## Art quality and gameplay guardrails
Color swatches alone are insufficient to distinguish cultivars. Provide leaf/cane structure, overall shape and recognizable bloom silhouette. Avoid generic copy-and-paste 3D roses. Preserve game art direction and scale audits; save screenshots for review.
No automatic flower harvesting for cut roses until harvest workflow is defined. Never assign unverified yield or exact timing. Do not confuse winter dormancy with death.

## Provenance
Class-level pruning references:
- RHS shrub pruning https://www.rhs.org.uk/plants/roses/shrub/pruning-guide
- RHS climbing pruning https://www.rhs.org.uk/plants/roses/climbing/pruning-guide
- Illinois Extension https://extension.illinois.edu/roses/pruning
Scientific records hold original per-cultivar source links; each requires field-level review.
