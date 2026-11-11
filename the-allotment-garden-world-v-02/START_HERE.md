# Open the updated game in Godot

1. Extract the ZIP into a NEW folder so it is easy to distinguish from older copies.
2. In Godot Project Manager choose Import, select this folder's project.godot, then Import & Edit. Wait for the first import to finish.
3. In the editor's FileSystem panel double-click main.tscn and press F6 (Run Current Scene) to enter the garden directly.

For the avatar workshop, open features/avatar/screen.tscn and press F6 instead. It remains separate from the main menu.

F5 runs the welcome-flow preview: select Find a neighborhood or use the demo code BLOOM-0001 to enter the game.

The editor viewport may look empty: the neighborhood, character and interfaces are created when the scene runs. Workspace changes do not automatically update a separate copy on your computer. Two identical titles in Project Manager can point to different folders; import this newly extracted folder for this version.

Controls: WASD/arrows stroll; Shift faster; right-drag or Q/E camera; mouse wheel zoom; Tab neighborhood overview.

This update contains the revised hat, slimmer sleeves/arms, shared texture maps, continuous sculpted face, improved hair fitting and natural image-based lighting. Gameplay and appearance tests pass in Godot 4.6.3. Final character artwork is still under visual review.

Free-resource sources, verified licenses and ready-to-copy credits: CREDITS.md. Technical preview and tests: features/avatar/README.md and TESTING.md. No Blender installation or internet connection is required to play; the rigged GLB and textures are included.

## Detailed 3D garden collection

The Market and neighborhood now share the detailed plant, furniture and building library. For a close-up review, open `staging/garden_art_gallery.tscn` and press F6. See `assets/garden_art/README.md` for the full inventory, collisions, LODs and validation. Owner visual approval is pending.

Garden gates and rock walls: Shop → Decor has five free boundary pieces. Walls snap at their ends; R rotates. Walk toward either gate to open it automatically. The 3D review gallery also has an Open / close gates button.

French garden collection: 22 new free pieces are under Shop → Decor. Search `pots`, `sculptures`, `structures` or `Villandry`, or open `staging/french_garden_showcase.tscn` and press F6 to browse them up close.

Roman columns / vertical building: search `Roman` in Shop → Decor. Place a plinth, then point at its top to stack compatible column parts. Stack mode starts on for Roman pieces; T toggles it. R rotates; View ↑ / ↓ adjusts the camera. Upper pieces must be removed before their supports. Open `staging/roman_building_showcase.tscn` with F6 for a full stacked example.

Witchy fairy night garden: search `witchy` or `fairy` in Shop → Decor for 18 free pieces. They glow automatically at night. The lower-right Garden lighting button cycles clock/day preview/night preview. Open `staging/enchanted_garden_showcase.tscn` with F6 for day/night close-ups.

Campsite inspiration collection: Shop → Decor → search `Campsite` for 13 new rustic pieces based on the shared board screenshots. Includes woven willow planters, twig gates/arbors, a quilt rack and garden game displays. Run `staging/rustic_garden_showcase.tscn` with F6 for close-ups.

Woodland gathering collection: Shop → Decor → search `Woodland` for log benches, stump stools, tables, lantern picnic setting, work stations, a walkable deck/balance trail and decorative swing/seesaw. Items are free. Sitting and riding are not connected. Open `staging/woodland_gathering_showcase.tscn` with F6 to review; art approval is pending.

Local save vault: click **Save garden · Local vault** at the top of the game, or open Settings → Save garden now. The game also autosaves every minute, on focus loss and when returning to title/closing normally. Choose your saved local profile on the title screen to continue. Settings → Open my save folder shows your progress files and the two vault backups. Saves stay on the computer where you play; no online account is needed.

Climbing plants: search **Climbing vines** in Shop → Plants. Choose seeds, seedlings, young or mature plants. Plant within 85 cm of a suitable trellis, arbor, pergola, post or column; the placement hint identifies a nearby support. All planted growth uses real elapsed time, including offline time. Mature perennial establishment takes months or years; mature shop plants can start already climbing. Preview new art in `staging/climbing_vine_showcase.tscn` (F6).

Windows USB/CD edition: the separate The_Allotment_Windows_USB.zip contains a launcher and signed starter game; players do not need Godot. Keep its files together and open The Allotment Launcher.exe. It checks for verified updates while idle, supports offline play and a previous game version, and keeps the existing local-vault save location. The public update channel starts serving updates after the first reviewed release is published. Owner publishing/build instructions are in distribution/README.md in the source repository.
