# French garden collection

22 new free Decor entries are integrated into the existing Shop, Backpack, placement/retrieval, save system and 3D gallery. The designs are original interpretations of French garden traditions, not reconstructions of particular historical objects. Existing collection, terrain, stone paths, grass and verified acreage remain intact.

## Inventory and metre dimensions

Dimensions below are width × height × depth. Model bounds are fitted and tested at these actual world dimensions, independently of distance detail.

| Family | Item | Metres |
|---|---|---|
| Gates / walls | Château scroll gates | 3 × 2.4 × 0.6 |
| | Potager lattice gates | 2.4 × 1.5 × 0.4 |
| | Formal limestone wall | 2 × 1.2 × 0.45 |
| | Rustic fieldstone wall | 2 × 1.15 × 0.5 |
| | Ivy-covered garden wall | 2 × 1.4 × 0.6 |
| | Stone balustrade | 2 × 0.95 × 0.45 |
| Pots / planters | Garland terracotta jar | 0.8 × 1 × 0.8 |
| | Fluted clay bowl | 0.8 × 0.4 × 0.8 |
| | Olive-glazed pot | 0.65 × 0.85 × 0.65 |
| | Classical stone urn | 0.85 × 1.15 × 0.85 |
| | Carved stone trough | 1.5 × 0.5 × 0.65 |
| | Rosette stone planter | 0.75 × 0.75 × 0.75 |
| Sculptures | Carved dove | 0.65 × 1.15 × 0.65 |
| | Botanical relief stele | 0.8 × 1.5 × 0.55 |
| | Garden muse bust | 0.75 × 1.7 × 0.6 |
| | Bronze armillary sphere | 1 × 1.85 × 1 |
| | Stone sundial | 0.8 × 1.2 × 0.8 |
| Structures | Climbing-vine pergola | 4 × 2.9 × 3 |
| | Iron garden pavilion | 4 × 3.6 × 4 |
| | Potager espalier screen | 2.8 × 2.3 × 0.6 |
| | Rosette wall fountain | 1.6 × 2.2 × 1 |
| | Stone garden alcove | 3 × 2.8 × 1.3 |

## Design references

- Villandry's ornamental kitchen-garden vocabulary informs the open lattice gates and trained espalier: https://www.chateauvillandry.fr/
- Giverny's planted garden compositions inform green-painted supports and climbing vines: https://fondation-monet.com/
- Versailles's formal garden vocabulary informs the urn, balustrade, classical bust, armillary and stone alcove: https://en.chateauversailles.fr/discover/estate/gardens
- Anduze pottery traditions inform the garlanded clay jar, rolled lip and medallions. The item is original game geometry, not a reproduction or an endorsement by any pottery maker.
- Country-garden masonry informs the varied rounded fieldstones and ivy softening the wall.

The named precedents describe the design direction. They are not claims that these exact objects exist at those sites, nor a claim of a new historical survey. All source geometry and vector thumbnail artwork are original; no external model/texture assets were introduced.

## Use

Shop → Decor contains all additions. Search names, family names (`pots`, `sculptures`, `structures`, `gates`) or inspiration words such as `pottery` or `Villandry`. Each detail panel names its inspiration. Inspect 3D, add to the Backpack or place immediately for free. Rotate with R; compatible wall/gate ends use the existing endpoint snapping. Existing route protection and gate swing clearance apply. The two new gate variants automatically open and close using the established proximity system.

For close-up review, open `staging/french_garden_showcase.tscn` and press F6. Choose among the 22 additions, right-drag to orbit and use the wheel to zoom. Gate entries have an Open / close gates control. The broader `garden_art_gallery.tscn` also includes them.

Pots have modeled open interiors and are decorative placeable objects. Planting directly into a purchased pot is not a new mechanic in this change. Sculpture and sundial/armillary are decorative; the sundial does not calculate solar time. Espalier foliage/fruit and structure vines are fixed decor rather than harvestable or growing plants. Wall fountain water moves; reduced cosmetic motion freezes the water and leaves. Gate opening remains a functional navigation action.

## Implementation and verification

`french_collection.gd` holds the 22 catalog definitions, metre dimensions, original mesh recipes, gate/boundary aliases and collision recipes. Shared library integration reuses the existing three distance-detail variants and cached materials/meshes. Glazed ceramic uses a distinct lower-roughness material. Architectural collisions follow the fitted Geometry transform so posts align with visible models and entrances remain clear. Sculpture/pot collisions are simple proxies; leaves have no collision.

The total gallery now has 51 entries / 79 asset-stage combinations. Every base mesh variant stays below 40,000 triangles and lower detail does not increase the triangle count. The gate variants also reuse separate hinge meshes. No device-wide performance certification is claimed.

`tests/verify_french_collection.gd` checks all new free catalog entries/icons, exact live bounds, collision/idempotence, gate opening/closing, actual avatar passage through both gates and open structures, boundary compatibility, placement and saved restoration of all 22 pieces, inspiration/family search and the dedicated showcase. The shared mesh audit checks normals, UVs, indices, materials, resource sharing and LOD budgets across all 79 combinations. Market, courtyard, original gate/wall and plant growth regressions are also run, plus import and graphical preview checks.

Godot 4.6.3 Compatibility/Mesa is available here; the owner's Godot 4.7.2 installation was not run. The owner accepted the prior style as a starting direction; new French collection art is ready for visual approval rather than assumed final under AGENTS.md.
