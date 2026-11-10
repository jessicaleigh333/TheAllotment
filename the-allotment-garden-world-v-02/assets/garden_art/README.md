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

The 24 collection entries comprise 52 asset/stage combinations and 156 mesh detail variants. Each instance selects one of three distance ranges (0–18 m, 18–45 m, 45+ m). Repeated instances share cached meshes/materials. Geometry batches by material role, avoiding a node/draw call per petal. Every individual variant is below 40,000 triangles; lower detail never increases triangle count. Scene-wide performance still depends on the device, visible content and shadows; there is no mobile certification claim.

## Use and preview

Open `staging/garden_art_gallery.tscn` and press F6. Select an asset/stage, right-drag to orbit, and use the wheel to zoom. The gallery shows actual metre bounds and near triangle counts. `staging/plant_scale_studio.tscn` shows all seven plants beside metre/human-height references. Start the normal game to see the same collection in the world; Market inspection and placement use the same meshes.

`garden_library.gd` is the single source of shapes, with reusable builders in `mesh_builder.gd`. Plants/Market props are fitted to the explicit dimensions by `features/market/item_model.gd`. Rebuild after a growth-stage transition retains those dimensions. Wind is intentionally subtle; water ripples and candle emission vary over time. Reduced-motion settings freeze these animations.

World collision uses simple authored recipes, separate from detailed visual geometry. Arch and greenhouse entrances remain open. Plant leaves do not obstruct walking. Terrain painting protects bed/building footprints. Placement continues to protect routes and mature spacing. Preview ghosts override batched materials with a translucent green/red shader.

## Validation and status

`tests/verify_garden_art.gd` checks all 52 combinations, shared-resource reuse, UV/normal/vertex/index validity, three LODs, triangle budgets, collision recipes/idempotence and reduced motion. Shop, courtyard, growth, acreage, ground-cover, layout, sidewalk and avatar regressions were run. Graphical renders were inspected with Godot's Compatibility renderer under Mesa software rendering; Godot 4.6.3 was available here, while the owner's editor is 4.7.2.

The collection is implemented and integrated, and ready for owner visual review. Per the project's AGENTS.md, art is not marked final until the owner approves the rendered style. These are softly stylized game models, not a recreation of every painted detail in the supplied UI inspiration images. Future unimplemented design-spec locations/assets are outside this inventory. Plant dormancy, weather-dependent growth and cultivar-specific simulation remain outside this art change.
