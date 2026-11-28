# Victorian Lantern Conservatory — Allotment design request

**Request ID:** `victorian-lantern-conservatory-01`  
**Proposed item ID:** `victorian_lantern_conservatory_01`  
**Classification:** Buildings / Greenhouses / Victorian Conservatories  
**Status:** Design draft awaiting final owner review. This is NOT a Godot runtime item, shop listing or validated geometry.

## Provenance and artwork

- User screenshot supplied November 17, 2026: elaborate cream-colored conservatory attached to a stone/timber residence, with high central glass clerestory and projecting lower glass-roof wings. Screenshot is architectural *inspiration*, not a measured source.
- **Structural sheet (Codex reference):** https://drive.google.com/file/d/1O-4PAMjYt_UzLWTRhdDoStsf-nVKi6z8/view
- **Separate shop illustration (player asset concept):** https://drive.google.com/file/d/15I6HCxZpnHc-wSdDoBEG1u4qC4mhNe5M/view
- **Spreadsheet row:** https://docs.google.com/spreadsheets/d/1XlA0-MiOi2xq8rGziCxw-AQM7CfUrEIdKP_uDteItx4/edit — tabs New Item Requests and Structure Design Specs.

**Art fidelity:** Keep central roof lantern higher than lower glazed side wings, large rectangular ground-floor glass panels with pointed/Gothic arch tracery in upper transoms, slender cream-painted mullions, stone/brick base and visible corner posts. This screenshot shows an *attached* conservatory; the standalone 3D shop variant is an intentional adaptation. Do not assume the reference provides a second walkable floor or a usable upstairs level simply because the lantern is tall.

## Game-proposed dimensions (NOT surveyed / verified)
- Footprint: width 7.3 m × depth 4.9 m (24 × 16 ft). Depends on game-lot allowance.
- Overall height: about 7.3 m (24 ft).
- Ground wall height: target ~3.0 m (10 ft) before roof begins.
- Central lantern: extra ~2.4 m (8 ft) clerestory zone; support/transition dimensions must be reconciled so total height stays 7.3 m.
- Side roof slope: initial 35–45 degrees; revise to achieve physically coherent geometry.
- Foundation: ~0.6–0.9 m plinth concept; dimension should be incorporated in total elevation.
- Single ground-level footprint; interior upper lantern is roof volume, not an identified mezzanine.

**Warning:** The structural sketch is concept artwork, not verified architectural CAD. Its panel counts/projections and some labels may conflict; derive consistent orthographic dimensions during 3D modeling. In particular, 10 ft wall + 6 ft side roof + 8 ft lantern = 24 ft only before the foundation or other overlaps—solve actual sectional geometry instead of blindly using additive labels.

## Codex 3D component plan
1. Modular cream-painted slender arched window frames, transoms, Gothic decorative inserts, glass panes and corner posts.
2. Base stone plinth; clear wall base profile; opening for a walkable door.
3. Lower symmetrical sloping glazed roof wings with rafters, gutters and flashings; central raised glazed clerestory including upper vertical glass walls and a smaller cap roof.
4. Join roofs without leaks/artifacts and avoid coplanar z-fighting/transparency sorting issues.
5. Distinct primary wall structural geometry versus decorative tracery; glass shader performance/LOD controls.
6. Interior ground plane, avatar collision and placement footprint. No implied upper-floor navigation.
7. Reuse common roof-pane, window, decorative-arch, stone-base components; make material palette tunable.

Potential future use: greenhouse/conservatory, botanical library or research garden display. **No new climate simulation, crafting, reading buffs or functional purchasing is implemented by this design.** Shop illustration may include nonbinding furniture/planter props. Owner review of actual mesh and dimensions is required before publication. No gameplay code or catalog exports should be changed for the design-only phase.
