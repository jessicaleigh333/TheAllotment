# Broad botanical intake verification — 2026-11-16

## Completed technical checks
- 273 provisional entries; 202 genera; 69 families. All entries have distinct internal IDs.
- Every entry links to a genus; every genus links to a family in the saved index.
- No legacy growth IDs modified. No new playable item IDs created.
- Found and documented shared-species overlap `Cucurbita pepo` with the previous batch. Additional shared-species crop forms (beet/chard; celery/celeriac; Brassica crop types) must be normalized before applying cultivar-level traits.
- JSON files were read back from the feature branch and parsed successfully; their index relationships were checked.

## Not yet completed
- No individual botanical names or traits have been cross-checked against Kew one by one; Kew is a **planned authoritative review source**, not 273 field citations.
- No source-by-source proof for biology, growth rates, regional invasive status or toxicity; nulls are intentional.
- No Godot runtime, build, asset or gameplay integration tests.
- No new plant varieties or art models have been created for the game in this batch.

## Recommended review priorities
Food crop use-types (Capsicum, Brassica, Cucurbita), orchard fruit and nut species, flowers, native ecological gardens, woody ornamentals, climbers, wetland species, grasses, then houseplants. Prioritize safety, invasiveness, accepted taxonomy, cultivar differentiation, sources and numerical physiology.

## Authoritative taxonomy starting points
- https://www.kew.org/science/collections-and-resources/data-and-digital/names-and-taxonomy
- https://powo.science.kew.org/about
- https://powo.science.kew.org/about-wcvp

## Release constraint
These files are a first-pass **index** for future high-quality plant records, not an existing verified growable database. No direct live game usage before review and proper code/test integrations.
