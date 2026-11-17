# Curved Glass Library Conservatory — owner reference / proposed inventory item

- **Request ID:** `curved-glass-library-conservatory-01`
- **Proposed item ID:** `curved_library_conservatory_01` (check collisions before publishing)
- **Category:** Buildings / Conservatories / Garden Library
- **Status:** Draft design for owner review. NOT implemented in Godot, catalog export, or live inventory.
- **Source:** Owner image shared in ChatGPT, 2026-11-17, showing an interior arched glass and timber book-filled reading space. Image has an “AI modified” label. Original image is inspirational, not dimensioned architectural evidence.
- **Structural study:** https://drive.google.com/file/d/1V6mTHTytUC36Xfb4CUoRvVkEdF2KGE9p/view
- **Isolated shop art:** https://drive.google.com/file/d/1NRn9lFS9Zpw9aK-iqmHU5JKTLvP9CkM0/view
- **Inventory spreadsheet:** https://docs.google.com/spreadsheets/d/1XlA0-MiOi2xq8rGziCxw-AQM7CfUrEIdKP_uDteItx4/edit, tabs New Item Requests and Structure Design Specs.

## Essential architecture
- Series of curved timber portal ribs with glass panes spanning a barrel-vaulted roof and upper side walls.
- Large arched end-window set in timber framing.
- Integrated curved book shelving along lateral side(s) and upper roof line. Non-structural book and plant props should be separate reusable instances or mesh modules.
- Timber floor deck or platform. One-level reading area; no stairs or second level.
- Optional recessed daybed with green upholstery, cushion sets, reading bench and planters; classify as distinct furniture/decor components rather than a requirement for the shell.
- Modularity: bent/segmented rib modules, curved pane modules, horizontal glazing mullions, timber base, shelf arcs, window arch, upholstered bench, wood/metal material definitions.
- An open cutaway front in the illustration is **presentation**, not proof that the actual building should have no front exterior wall. A finished 3D design needs appropriate access/door(s) and enclosure definition.

## Proposed gameplay dimensions (not surveyed physical dimensions)
- Overall conceptual footprint: 4.9 m × 3.7 m (16 × 12 ft).
- Target interior height: 3.0 m (10 ft).
- A 6 ft barrel-vault radius is a possible illustration interpretation, **not consistent with all rib/skylight portions**, and must be corrected during modeling.
- For a 12 ft wide half-cylinder, a true semicircle would reach roughly 6 ft above its springline; combine a lower wall section with the curved roof to achieve a 10 ft height. Confirm actual rib curvature and headroom in a consistent 3D cross-section before building.
- The input screenshot does not establish whether this is a standalone structure or an extension of a larger house. Our concept uses a standalone module, subject to owner approval.

## Model handoff
Build with coherent, measured Godot geometry, scale and collision, sensible access path, interior camera movement and performance-conscious glass. Prefer reusable high-quality rib, shelf, glazing and furniture components over a single all-in-one mesh. Source design technical reference and shop art separately; shop art includes decoration and is not structural truth. Do not advertise seating, reading buffs or plant-growing effects as functional until implemented and tested. Do not change the runtime catalog or saved scenes from this design-only PR.

## Review status
This request is a design proposal, not necessarily the final owner's approved model. Requires review before playable publication.
