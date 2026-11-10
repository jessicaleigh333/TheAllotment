# Witchy fairy night garden

18 original free Decor entries are integrated into the Shop, Backpack, placement, retrieval, local saves, collision and 3D preview system. The collection adds whimsical storybook fantasy alongside the existing French and Roman garden designs, following the owner's explicit request. It is not presented as historical French garden ornament.

## Inventory and real metre scale

| Decoration | Width × height × depth (m) |
|---|---|
| Neon toadstool cluster | 0.9 × 0.7 × 0.9 |
| Fairy mushroom cottage | 1 × 1.1 × 1 |
| Moonlit fairy ring | 2.4 × 0.5 × 2.4 |
| Twilight crystal cluster | 0.8 × 1.2 × 0.8 |
| Crescent lantern post | 0.6 × 1.8 × 0.5 |
| Starlight garden cauldron | 0.9 × 0.85 × 0.85 |
| Witch-hat flower planter | 0.8 × 0.7 × 0.8 |
| Moon spellbook pedestal | 0.7 × 1.2 × 0.65 |
| Crescent moon sculpture | 0.9 × 1.8 × 0.55 |
| Secret fairy door | 0.55 × 0.8 × 0.25 |
| Star-blossom enchanted tree | 2.4 × 3 × 2.4 |
| Garden star mobile | 0.7 × 1.7 × 0.7 |
| Glowing garden sigil stone | 0.65 × 1.9 × 0.65 |
| Fairy lotus lamp | 0.7 × 0.45 × 0.7 |
| Firefly lantern jar | 0.35 × 0.6 × 0.35 |
| Wishing-star fairy well | 1.6 × 1.9 × 1.4 |
| Moon-and-stars garden arch | 2.8 × 3 × 0.8 |
| Witch's potion shelf | 1.1 × 1.6 × 0.5 |

Custom geometry includes closed mushroom stems/caps, cap freckles and gill rims, cottage windows/door/steps/chimney, faceted crystals, curled metalwork, stars/crescents, a hollow cauldron, layered lotus petals, a ribbed firefly lantern, embossed spell pages, invented sigils, bottle shelves, and a bucket/canopy over the wishing well. The sigils are original fantasy ornament. No external mesh, texture or sound asset is introduced; thumbnail artwork is original SVG.

## Use in the game

Open Shop → Decor and search `witchy`, `fairy` or `night` to see the collection. Everything is free and uses existing placement/rotation/save/retrieval controls. Full actual footprint radii reserve space and protect routes. The arch is walk-through; the mushroom ring has an open centre and two entrance gaps. Compatible small ornaments can also be stacked on the Roman pieces using the established support rules. Planting inside the decorative hat planter, entering the tiny cottage, potion crafting, teleporting doors, wish rewards and spell casting are not new gameplay systems in this art change.

Glow follows the existing **UTC garden clock**, the same clock shown by Weather. It fades in during 18:00–20:00, stays on overnight, and fades out during 06:00–08:00. Daylight shows painted/pastel details without night emission, halos or decor lights. The shared day/night driver also changes the world's existing illumination and tints its countryside backdrop; no terrain, grass or path geometry changes.

The lower-right **Garden lighting** button cycles garden clock → day preview → night preview → garden clock. Previews are temporary, and do not advance weather, plant growth, inventory or placement data. Ground-editor lighting sliders remain a manual preview. Select garden-clock mode to resume automatic timing.

For close-up review, open `staging/enchanted_garden_showcase.tscn` and press F6. It browses all 18 items, toggles day/night and assembles a small moon-garden display. The full art gallery also includes the collection.

## Glow, motion and performance

The existing shared day/night driver (`features/garden_editor/day_night.gd`) supplies the new night amount to the shared mesh shader. Luminous material role 13 uses per-vertex colors and gentle slow shimmer. `enchanted_glow.gd` adds one depth-tested, camera-facing soft halo and one shadow-free light proxy per decorated object. Only the six nearest eligible decor lights within 24 m of the camera are enabled; emission and nearby halos remain visible independently of this pool. Halos stop rendering beyond 35 m. Placement previews suppress halos/lights and use the existing green/red ghost material.

This is visible in Godot's Compatibility renderer without relying on unsupported post-process bloom. Forward renderers can also use the driver's environment glow. Reduced motion freezes the cosmetic shimmer and leaf/petal wind. Glows still switch with day/night; functional gate motion remains unaffected.

The full gallery now has 83 entries / 111 asset-stage combinations with three shared mesh variants. Every individual base variant is below 40,000 triangles and lower detail does not increase geometry. Tiny cap freckles/fireflies use inexpensive meshes rather than full-resolution spheres. The existing 500-piece save limit remains; this is not a device-wide performance certification.

## Validation and art status

`tests/verify_enchanted_collection.gd` covers all 18 entries, icons, exact live bounds, full placement footprints, effect nodes/collisions, placement/save restore, garden-clock night/day behavior, manual preview/resume, the six-light limit, suppressed ghost effects, reduced motion, unchanged save data, raised ornaments, family search, avatar passage through the arch/ring gaps and the dedicated gallery. The full shared mesh audit covers all 111 combinations. Market, courtyard, vertical building, weather, ground cover, editor controls and layout regressions are run, alongside import and real Compatibility day/night renders.

The code is tested with Godot 4.6.3 Compatibility/Mesa; the owner's 4.7.2 editor is unavailable here. This collection is implemented and integrated, with visual approval pending under AGENTS.md. Day/night and live-world preview images are supplied for review.
