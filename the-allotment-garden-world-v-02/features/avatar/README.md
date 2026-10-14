# Garden character and avatar workshop

The cozy gardener is a real rigged 3D asset integrated into `main.tscn`, with idle and walking animations, saved appearance and physical movement. The nine-garden neighborhood and existing editor/weather systems are preserved.

## Preview

Open `main.tscn` in Godot 4.6+ and press F6. WASD/arrows stroll, Shift walks faster, right-drag or Q/E turns the camera, wheel zooms, R resets the camera, and Tab switches to the neighborhood overview. The character remains where you left it while viewing the map. Menus and the garden editor pause movement. All nine entrances are visitable; entering does not claim a plot or grant editing rights.

Open `features/avatar/screen.tscn` and press F6 for the standalone workshop. Main-menu access is deliberately deferred. Scroll the sidebar to see all options. Change appearance, use the turntable or walking preview, then select **Save and use this look** followed by **Enter the garden**. The game loads the saved appearance on entry; unsaved changes remain a preview.

## Working appearance options

- Four hairstyles: long waves, bob, braids and bun.
- Layered sage overdress and ivory underskirt with corset lacing, lace edging and botanical embroidery, or waistcoat/trousers; optional hat, hat flowers, satchel, apron and freckles.
- Romantic sculpted face/almond eyes, tapered wavy hair, raised hat flowers, leather wrist wraps, garden belt/pouch, pendant and tall lace-up boots. Leather calf and toe sections follow separate rig joints.
- Eleven full color pickers: skin, hair, eyes, brows/lashes, lips, outfit, blouse/apron, straw hat, ribbons, leather/boots and flowers.
- Three garden-inspired presets; height/build scaling and initial face width/length, nose and eye morphs.
- Independent dyed materials with shared texture maps, live 3D preview, idle/walk animation, original-look reset and versioned local save.
- Texture polish for linen, raised botanical embroidery, hair, leather, straw, skin and eyes. Slimmer arms/sleeves and a rounder, warmer storybook face.
- A fitted sunhat with rounded crown, curved solid brim/finished edge and flowers attached to the ribbon; hat and flower visibility/colors remain customizable.

## Architecture

`appearance.gd` supplies defaults, validation and atomic JSON persistence at `user://avatar/appearance.json`. Invalid or unsupported saves fall back safely. `garden_player.tscn` is a CharacterBody3D with height/build-adjusted capsule; `garden_player.gd` handles camera-relative movement. `world_collisions.gd` installs separate collision children under existing terrain, paving, hedges and structure meshes without replacing them. `scripts/courtyard_world.gd` manages player spawning and walking/overview camera modes.

`assets/characters/gardener/gardener_visual.tscn` wraps the imported rigged GLB. Mesh names select modular hair/clothing/accessories; named material roles enable recoloring; imported shape keys implement the initial face controls. Shared PNG detail/normal maps preserve linen, raised embroidery, hair, worn leather and straw while recoloring. Painted complexion masks and iris fibres follow the chosen skin/eye tints. `skin.gdshader`, `iris.gdshader`, `fabric.gdshader`, `hair.gdshader`, `leather.gdshader` and `straw.gdshader` provide independent per-character dye parameters. The shader cache shares immutable textures, not material instances. Surface overrides are explicitly released before mesh teardown to avoid deferred renderer callbacks to freed material resources. New modular parts must be registered in `gardener_visual.gd`, and new saved options in the schema/UI.

## Remaining work

This is the first appearance library, not complete customization of every detail. Further body types, facial expressions, additional hairstyles, clothing/accessories, animation polish, production topology/LOD, camera obstruction handling, touch/gamepad controls and authoritative multiplayer synchronization remain future work. Current collisions approximate structures with simple shapes; vegetation can be walked through. Movement does not implement accounts, ownership or claiming. The character has been refined toward the supplied romantic gardener reference, but remains a procedural 3D prototype. The requested first texture and soft face polish pass is implemented; final sculpt/animation refinements and production art approval remain ahead. Artwork is ready for visual review, not final art approval.

See [TESTING.md](TESTING.md) for checks and [asset source notes](../../assets/characters/gardener/README.md) for editable authoring files.

## Free resources and credits

The current pass adapts a CC0 MakeHuman anatomical head, Microsoft/Khronos CC0 woven-cloth detail and Poly Haven CC0 sunrise lighting. The original raw assets, primary license declarations, exact checksums and ready-to-copy game credits are preserved in the root CREDITS.md and assets/third_party/manifest.json. Face/nose/eye controls operate on the continuous head and fitted parts together. The avatar remains a developing art asset; broader wardrobe/expression libraries and production optimization are still planned.
