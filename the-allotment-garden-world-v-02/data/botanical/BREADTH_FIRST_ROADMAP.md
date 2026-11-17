# Botanical data expansion: breadth first, depth in stages

## File roles
- `01_scientific_records/taxonomic_skeleton_batch_002.json`: 273 provisional crop-type/species/hybrid intake entries. **Not** verified taxonomic identities or gameplay data.
- `01_scientific_records/family_genus_index_batch_002.json`: 69 family and 202 genus groupings connecting the 273 entries.
- `01_scientific_records/mixed_garden_batch_001.json`: 30 earlier initial trait-bearing records. Maintain stable existing IDs.
- `01_scientific_records/roses/recovered_rose_cultivars.json`: 18 rose cultivar research intake records.
- `01_scientific_records/cultivar_template.json`: canonical blank detail template for later individual cultivars.
- `02_construction_specs/`: separate build instructions; no auto-generation of art from unchecked facts.
- `03_verification_reports/`: audit trail and implementation status.

## Inheritance model: a database relationship, not blanket biological inheritance
family -> genus -> species (or botanical hybrid) -> horticultural group/type -> named cultivar -> individual planted specimen. Scientific taxonomic groups and horticultural categories are different entities. Two market names may share an identical botanical species; do not count them as separate biological species. Use explicit `same_taxon_as` or stable taxon identifiers when de-duplicating. A species has traits common to it, while a cultivar can override habits, physical dimensions, flowering schedule, yield, cold response, seed fertility and pruning requirements with documented evidence. Individual specimens additionally retain site conditions, age and observed health.

## Data governance and source review
1. Audit accepted scientific names via Kew Plants of the World Online / WCVP. Kew describes these resources as actively curated, and names can change; store date, source link, taxon status, synonym and accepted name.
2. Separate species-level traits from horticultural cultivar descriptions. Use land-grant extension resources, RHS, botanical gardens, germplasm databases and peer-reviewed studies for individual traits, according to scope.
3. Populate verified data field by field, with evidence and confidence; unknown values remain null. Every numeric datum must specify units, environment, uncertainty and applicable taxon or cultivar.
4. Review invasive status, restrictions, toxicity and suitability by region and context before player guidance; some featured plants are unsafe or invasive in particular regions.
5. In a later independent phase, produce reusable Codex specs for vegetables, orchard trees, roses, annuals, perennial flowers, vines, woody shrubs, grasses, aquatics and houseplants. Test in Godot before enabling catalog entries.
6. Maintain 1:1 real-time growth and save compatibility; never convert scientific guesses into gameplay constants without explicit owner-approved assumptions.

## Data-cleaning tasks before deeper import
- `Cucurbita pepo` appears as zucchini in the 30-record batch and pumpkin in the breadth intake: multiple crop forms of one species; link these explicitly before deduplicating or assigning cultivar traits.
- `Beta vulgaris` appears as beetroot and chard and `Apium graveolens` appears as celery and celeriac: distinct use types within a shared species. Link as crop forms, not separate species.
- `Brassica oleracea` and `Brassica rapa` crop types (cabbage, turnips, Chinese cabbage, kale) need cultivar-group hierarchy.
- Thyme, basil, rose, hydrangea, apple and strawberry records already have varying levels of existing detail; when enriching do not remove these.
- Taxonomic names containing ×, variety qualifiers, or horticultural group labels need normalized ranks/accepted-name checks.
- Some categories mix economic uses with taxonomy (e.g., ‘fruit trees’ include nuts); preserve a many-to-many category index, separate from biological family.
- There may be crop names that are synonyms of another accepted plant name. Never silently remove records; redirect legacy IDs after review.

## Delivery gates
A plant becomes Codex-build-ready only when: identity resolved, trait evidence per needed mechanic, safety and region review completed, a construction spec authored, and owner-approved assumptions defined. Otherwise it stays a discoverable research skeleton only.
