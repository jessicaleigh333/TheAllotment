# Shared garden collection

This collection replaces the primitive plant/furnishing/building meshes used by the current playable neighborhood and Market. Geometry is original editable procedural source, not external stock art. It uses Godot ArrayMesh surfaces with indexed vertices, normals, UVs and vertex-color palettes. No new texture or model license is required.

## Implemented asset inventory

| Group | Integrated assets | Detail |
|---|---|---|
| Living plants | Sunflower, rose, lavender, hydrangea, cosmos, daisy, basil | Five visual stages each: seed marker, sprout, seedling, young/bud, mature. Species dimensions and real-day timestamps remain in `plant_growth.gd`. |
| Market objects | Bench, rose arch, fountain, lantern, trellis, filled planter, watering can, straw hat | Slats, rolled pot rims, curved lattice/vines, layered flowers, metal hardware, woven material, water surfaces/streams and candle emission. |
| Neighborhood | Broadleaf tree, cypress, hedge, shrub, shed, greenhouse, market stall, raised bed, central planter | Leaf sheets and branched trunks; glazed greenhouse with open entrance and potting bench; shed door hardware/window/gables; striped canopy; soil and bolted timber beds. |
| Existing character | Gardener rig, face morphs, modular outfits/hair/accessories | Existing authored character retained. Importer LOD/shadow mesh generation and avatar regressions verified; this change does not replace the character or claim new character artwork. |
| Existing terrain | Grass, paths, courtyard and 83 ground-cover materials | Working terrain geometry, dimensions and path arrangement retained. Ground-cover obstacle detection supports the new asset footprints. |

The 83 collection entries comprise 111 asset/stage combinations and 333 mesh detail variants (plus shared gate-leaf meshes). Each instance selects one of three distance ranges (0–18 m, 18–45 m, 45+ m). Repeated instances share cached meshes/materials. Geometry batches by material role, avoiding a node/draw call per petal. Every individual variant is below 40,000 triangles; lower detail never increases triangle count. Scene-wide performance still depends on the device, visible content and shadows; there is no mobile certification claim.

## Use and preview

Open `staging/garden_art_gallery.tscn` and press F6. Select an asset/stage, right-drag to orbit, and use the wheel to zoom. The gallery shows actual metre bounds and near triangle counts. `staging/plant_scale_studio.tscn` shows all seven plants beside metre/human-height references. Start the normal game to see the same collection in the world; Market inspection and placement use the same meshes.

`garden_library.gd` is the single source of shapes, with reusable builders in `mesh_builder.gd`. Plants/Market props are fitted to the explicit dimensions by `features/market/item_model.gd`. Rebuild after a growth-stage transition retains those dimensions. Wind is intentionally subtle; water ripples and candle emission vary over time. Reduced-motion settings freeze these animations.

World collision uses simple authored recipes, separate from detailed visual geometry. Arch and greenhouse entrances remain open. Plant leaves do not obstruct walking. Terrain painting protects bed/building footprints. Placement continues to protect routes and mature spacing. Preview ghosts override batched materials with a translucent green/red shader.

## Validation and status

`tests/verify_garden_art.gd` checks all 111 combinations, shared-resource reuse, UV/normal/vertex/index validity, three LODs, triangle budgets, collision recipes/idempotence and reduced motion. Shop, courtyard, growth, acreage, ground-cover, layout, sidewalk and avatar regressions were run. Graphical renders were inspected with Godot's Compatibility renderer under Mesa software rendering; Godot 4.6.3 was available here, while the owner's editor is 4.7.2.

The owner accepted the initial collection as a starting direction. The gates/walls addition is implemented and integrated, and ready for owner visual review. Per the project's AGENTS.md, art is not marked final until the owner approves the rendered style. These are softly stylized game models, not a recreation of every painted detail in the supplied UI inspiration images. Future unimplemented design-spec locations/assets are outside this inventory. Plant dormancy, weather-dependent growth and cultivar-specific simulation remain outside this art change.


## Garden gates and rock walls

Five additional free Decor entries are live in the Shop: wrought-iron double gates on limestone piers (3 × 2 m), timber double gates (2.4 × 1.3 m), capped rock wall (2 × 1.15 m), L corner (2 × 2 m footprint), and end pier (0.6 × 1.35 m). Their original prior model files were not found in the available project; these are matching new implementations, not a claim of recovered historical models. Wall construction uses individually beveled limestone/fieldstone courses, recessed mortar and capstones. The earlier gate/wall priority in the design reference remains the basis.

Open Shop → Decor to place them for free in the courtyard or Garden 01. Move a wall end within 0.55 m of another boundary socket to align the endpoints automatically; R rotates. Oriented boundary footprints allow touching joints while rejecting overlapping walls. Existing grass, paths and protected walking routes remain unchanged. Gates reserve their opening/swing space. Retrieval and local placement saves work through the existing Backpack flow.

Both gate leaves have hinge-mounted collision, open automatically as the gardener approaches, and close after the gardener leaves. A 2.7 m opening trigger, 3 m hold radius and 2-second clear delay avoid repeatedly closing around a passing player. The closed/open state is transient; saved placement, item and rotation restore normally. Gate previews stay stationary during placement. The review gallery has an Open / close gates button for inspecting the hinge motion. Gate opening is a functional navigation action and remains animated with reduced cosmetic motion enabled.

`tests/verify_garden_boundaries.gd` verifies all five Shop entries/icons, exact dimensions, wall joins at three angles, gate swing protection, opening/closing with moving collisions, real avatar passage through both gates, connected placement/overlap rejection and restored saved boundaries. Market and courtyard regressions also pass. Shared builder corrections give chamfered box caps flat outward normals and correct the winding of box/turned surfaces, fixing uneven stone shading. The mesh audit verifies outward box normals.


## French garden variations and structures

22 further free Decor entries add gate/wall variations, open clay/stone vessels, sculptures, a pergola, pavilion, espalier, wall fountain and alcove. See `FRENCH_COLLECTION.md` for the inventory, metre dimensions, inspirations, behavior, limitations and tests. Open `staging/french_garden_showcase.tscn` with F6 for a dedicated close-up review.


## Roman architecture and vertical building

14 free Roman building pieces add modular plinths, shafts, capitals, complete columns, a beam, cornice and pedestal. The Shop now supports snapping onto compatible flat tops, persisted vertical positions, supported beams and dependency-safe retrieval. See `features/market/VERTICAL_BUILDING.md` for controls, dimensions, support rules, limits and validation. Run `staging/roman_building_showcase.tscn` with F6 to browse the pieces and a stacked colonnade.


## Witchy fairy night garden

18 further free Decor entries add magical mushrooms, a fairy cottage/ring/door, crystals, moon lanterns, cauldron, hat planter, spellbook, moon sculpture, enchanted tree, stars, sigil stone, lotus lamp, firefly jar, wishing well, arch and potion shelf. `ENCHANTED_GARDEN.md` describes dimensions, behavior, UTC clock/night previews, Compatibility-safe glow, light budget and tests. Preview with `staging/enchanted_garden_showcase.tscn` (F6).
