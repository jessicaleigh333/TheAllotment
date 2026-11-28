# Glass-Roof Lookout Fire Tower — approved inventory design request

**Proposed item ID:** `lookout_fire_tower_glass_01`  
**Review request ID:** `lookout-fire-tower-glass-01`  
**Item type:** Buildings → Lookouts / Greenhouse-style observation towers  
**Stage:** Owner-approved design request only. No Godot scene, 3D mesh, runtime shop listing, gameplay behavior, or catalog export added.

## Artwork and provenance

- **Original source:** Owner-supplied screenshot of Thorny Mountain Fire Tower, shared November 17, 2026. It is used as inspiration, not as a verified architectural plan.
- **Primary technical drawing (Codex modeling):** https://drive.google.com/file/d/18j8O0lyuz1wBFXisNfjnHbm47Uy0kJNn/view
- **Separate shop illustration:** https://drive.google.com/file/d/1F0Bm6Rp4sPOih5MSjX2WN2WR9iK_as-o/view
- **Owner's inventory Sheet:** https://docs.google.com/spreadsheets/d/1XlA0-MiOi2xq8rGziCxw-AQM7CfUrEIdKP_uDteItx4/edit — tabs **New Item Requests** and **Structure Design Specs**

The **clear-glass pyramid roof** is the owner's explicit revision and overrides the opaque roof in the original photo. The shop image is a marketing illustration; do not treat decorative items, plants or furniture in it as required geometry.

## Proposed game dimensions — NOT measured real-world dimensions

| Feature | Proposed size |
| --- | --- |
| Overall height | approximately 18.3 m / 60 ft |
| Base leg footprint | approximately 6.1 m × 6.1 m / 20 × 20 ft |
| Upper wraparound deck | approximately 7.3 m × 7.3 m / 24 × 24 ft |
| Enclosed lookout cabin | approximately 4.9 m × 4.9 m / 16 × 16 ft |
| Roof | Clear-glass pyramidal/hipped roof with dark metal mullions; roof pitch to be designed consistently |
| Stairways | Exterior flights interrupted by protected landings, with safe railings |
| Approximate levels | Ground supports, intermediate platforms, upper deck and enclosed cabin |

The conceptual drawing's floor plans and dimension labels are indicative, not dimensionally certified. Do not assume load-bearing suitability, building-code compliance or an exact real-world height. Refine stair riser counts and headroom, entrance widths, slope of stairs, roof structure and load path for logical visual consistency within game constraints.

## Modeling notes

- Four tapering timber/steel-framed corner supports with X-bracing and bolted connector plates; foundations on concrete pads
- Open lattice tower with cross-braced support elevations and a sequence of stairs and landings
- Square elevated cabin with multi-pane windows on all sides, door accessing wraparound deck
- Clear glazed pyramidal roof, distinct dark mullion frame, realistic transparency and reflections
- Wood-plank deck with exposed timber rails, wire infill mesh, posts, stair guards and landing guards
- Coordinate stairs and doors with avatar navigation/collision; confirm footprint against plot boundaries
- Organize reusable stair segments, braces, deck sections, glass panes, door, roof segments, railings and materials as shared components
- No landscape, background props, unrelated plants or shop interface in structural reference
- Optional decorative add-ons such as lanterns and planter boxes may be separate variants; avoid coupling them to primary structure

## Gameplay status

Potential future uses: lookout and scenic viewpoint, garden observation, retreat, walkable interior. These are **concept intentions**, not implemented interactions. Do not turn on greenhouse temperature regulation, money prices, or arbitrary new player capabilities based on this document.

Codex owns model construction, Godot implementation, asset validation, collision, performance and tests. This design record is not a runnable item. Build in a separate implementation PR, preserve existing data and saves, and request owner approval of the modeled result.
