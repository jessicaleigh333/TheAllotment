# Greenhouse Atrium (Multi-Level) — approved structure concept

**Catalog request ID:** `greenhouse-atrium-multilevel-01`  
**Proposed stable item ID (subject to ID conflict validation):** `greenhouse_atrium_multilevel_01`  
**Category:** Buildings / Greenhouses / Conservatories  
**Owner direction:** Concept approved for inclusion in The Allotment on November 17, 2026.  
**Publication status:** SPECIFICATION / REQUEST ONLY — NOT a released shop item, mesh, Godot scene, or functional building.  
**Source:** Owner-selected greenhouse-atrium Pinterest screenshot and assistant architectural study in the project conversation, November 17, 2026. **Approved architectural illustration:** https://drive.google.com/file/d/1DZNbQ0QDnBeG1KiBKojYmnmJx7-4at1G/view?usp=drivesdk (owner's Google Drive; access may require permission). The image is **not committed as a Godot asset**; do not invent `res://` references. The item also appears on the Google Sheets **New Item Requests** tab, row 3.

## Visual design

A walk-through, two-level conservatory/greenhouse atrium with a **rectangular footprint**, steep glazed **gable roof**, fine-paned **dark forest-green framing**, and **cream-colored lower masonry/plaster arcaded walls**. Include a generously open center atrium, an accessible side staircase, a partial second-level mezzanine/walkway, and a safety railing. Prioritize structural silhouette, assembly and spatial organization; **no decorative foliage or background scenery** is needed in the modeling reference.

### Preliminary design dimensions (design targets, not measurements from reference)

| Property | Initial target |
|---|---|
| Footprint | 7.32 m (24 ft) wide × 10.97 m (36 ft) long |
| Overall height | ~7.32 m (24 ft), **requires roof/mezzanine geometry check** |
| First-level clearance | ~3.05 m (10 ft), tentative |
| Upper-level clearance | **To be solved**: upper walkable/mezzanine height and roof pitch must fit within the overall height |
| Roof | Symmetrical glazed gable, target pitch ~30°, subject to fit check |
| Floor count | Ground floor + partial upper mezzanine, open to below |
| Entrance | Walkable glazed entrance; accessible entrance width to be established against avatar collision/navigation |

Do **not** interpret the concept drawing as dimensionally certified. Before implementation, produce consistent plan, front/side elevations, section and stair calculations (headroom, landings, railing, collision, player camera clearance).

## Reusable components to model

- Structural foundation/base perimeter and dark green vertical post modules
- Modular glass-wall frames and pane grids; glazed gable end-wall modules
- Gabled roof beams, rafters and translucent/transparent glass sections
- Ground-level cream arched wall bay modules, arcades and door openings
- Glazed door unit, frame, hinges/threshold and access-clearance geometry
- Mezzanine platform, load-bearing columns, railing, stair flights and landings
- Optional structural-only visibility mode (frame without glass), **development preview only**
- Reusable material palette: painted dark green metal/wood, clear or lightly blue-tinted glass, warm cream plaster/masonry, muted stone/tile flooring

## Intended behavior contracts (not yet implemented)

- Enclosed/walkable two-level structure with correct avatar and camera navigation
- Collision and placement footprint; ground anchoring and slope/foundation restrictions
- Door interaction only where supported by an existing compatible controller
- Indoor greenhouse environment eventually able to influence temperature, humidity, radiation and ventilation through the planned scientific simulation engine
- Placement in eligible garden lots; height/boundary constraints; no guarantee existing lots can accommodate this footprint

**Do not** mark greenhouse climate control, ventilation, real-world growing effects, staircase navigation or new shop acquisition as implemented merely because a schema/contract exists.

## Publication workflow / safety

1. Retain this document as the source design record until typed new-item publication exists. Current master catalog derives its 262 entries from existing evaluated source definitions; manually appending an item to `catalog.v1.json` would break the rebuild contract.
2. Record the request in the Google Sheet's **New Item Requests** review tab; keep source definitions unchanged until implementation.
3. Validate stable ID uniqueness and classify as a new building, not a botanical plant or a decorative existing scenery recipe.
4. Build approved modular Godot geometry, interactions, dimension checks and visual previews on a feature branch.
5. Implement validated item authoring/publication, then generate SQLite + JSON with tested source/asset lineage and add it to a legitimate shop category if approved.
6. Run Godot import, collision/navigation/placement regression, catalog integrity and save compatibility tests before proposing a merge.
7. Do not set an in-game purchase price or claim this is playable until the economy and shop handling are explicitly decided.

## Ownership / artwork

The architectural concept and its composition were expressly approved by the project owner. **That is not approval of any future implementation mesh or final texture quality**; require separate visual review for the finished 3D object.

## Shop presentation artwork (supplemental)

**Illustrated shop concept:** https://drive.google.com/file/d/1g_Zs4gDImxincf0lOs4e31z3sqVebs6T/view

This illustration is intended for the eventual shop listing and aesthetic inspiration. **Use the original clean architectural illustration above as the primary geometry reference.** The shop illustration introduces decorative elements and a modified roof composition; those variations are not new owner-approved structural requirements. Any promotional claims about year-round growing, temperature control, or increased growing space describe **future intended gameplay**, not presently implemented mechanics.
