# Vintage A-Frame Brick Greenhouse — design handoff for The Allotment

**Request ID:** `vintage-aframe-greenhouse-01`  
**Proposed item ID:** `vintage_aframe_greenhouse_01`  
**Category:** Buildings → Greenhouses → Vintage / Rustic  
**Status:** Draft design record. **No Godot mesh, scene, live shop item, or gameplay implementation.**

## Source and image references
- Owner-supplied screenshot of a vintage greenhouse digital backdrop (Etsy listing), shared in ChatGPT on November 17, 2026. It contains a photo-like interior view, not a measured architectural drawing.
- **Technical/structural artwork:** https://drive.google.com/file/d/1Mn9FZfeBPEKj7WrYQ5Oh6tb5sLZzWUNc/view
- **Separate shop artwork:** https://drive.google.com/file/d/1hnb9ELmD_RBGxskZlFHlwdG8-EG18Pt4/view
- **Owner inventory Sheet:** https://docs.google.com/spreadsheets/d/1XlA0-MiOi2xq8rGziCxw-AQM7CfUrEIdKP_uDteItx4/edit — `New Item Requests` and `Structure Design Specs`.

## Distinguishing design
- Narrow, elongated, symmetrical greenhouse with a very steep **glazed gable/A-frame roof** from eaves to central ridge.
- Heavy weathered timber rafter ribs and closely spaced rectangular glass panes, with timber transoms and long side window walls.
- Low exposed red-brick knee walls running around perimeter below the window band.
- Tall glazed gable-end wall with many panes, two glazed hinged entrance doors; open view to opposite gable.
- Strongly visible black-and-white (or charcoal-and-cream) **checkerboard floor tile**, oriented on the diagonal.
- Weathered/whitewashed or natural brown timber palette; no landscape or background plants in technical drawing.
- The shop illustration contains optional plants, lanterns, chandeliers and furnishings. These should NOT be baked into the structural mesh or counted as existing game behaviors.

## Preliminary game scale — NOT measurements of original image
| Feature | Proposed size |
|---|---|
| Overall external footprint | 3.7 m wide × 6.1 m long (12 × 20 ft) |
| Overall peak height | about 5.5 m / 18 ft |
| Levels | One walkable ground floor, no mezzanine |
| Low brick wall | around 0.9 m / 3 ft high, depending on geometry |
| Roof | Straight symmetrical steep gable; full or near-full glass planes |
| Door | Two glazed timber doors; clear width to be determined with avatar controller |
| Flooring | Black/white tiles, diagonal checkerboard |

**Geometry warning for Codex:** Image labels such as 55–60° roof pitch and 18 ft peak are *independent illustrative estimates* and may not reconcile for a 12 ft width and 3 ft eave height. For a roughly 12 ft span, 3 ft eave and 18 ft peak, simple 2D rise/run would produce arctan(15/6) ≈ 68.2°, not 55–60°. Choose one consistent measured set in 3D and record the resulting pitch; preserve the owner's recognizable steep silhouette. Likewise, the illustrated interior height is not a verified clearance dimension.

## 3D modeling brief
- Reusable modular ribs/glass panel variants on repeat along the length; ridge beam and purlins.
- Brick knee-wall sections, corner bases, timber mullion grid, gable-end transom panels, double door/hardware and tiled-floor module.
- Plan a physically coherent glass shader, transparency sorting, collisions, player movement and floor/platform clearance.
- Windows may have visually openable casements but **no live window ventilation behavior** should be claimed until implemented.
- Preserve a clean modeling geometry separate from optional decorative foliage/lighting used in shop images.
- Use technical image for approximate proportions, shop illustration for appearance. Final 3D/art review needed before publication. Existing save formats and source catalogs remain unchanged by this design-only record.

Potential future uses include greenhouse cultivation, propagation, and garden workroom, but climate behavior and inventory purchasing are NOT implemented by this document.
