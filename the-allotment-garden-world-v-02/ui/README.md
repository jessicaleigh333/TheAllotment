# Game screen interface

Open `project.godot` and press F6 on `main.tscn`, or F5 to run the project. For a UI-only preview, run `ui/game_hud.tscn` with F6. The HUD overlays the permanent circular-courtyard neighborhood. The original grid is available separately in `staging/asset_staging.tscn` for asset reviews.

Left, top to bottom: Help / Louise, Settings, Garden Editor, Shop, Inventory, Journal.
Right, top to bottom: Weather, World Map, Friends, Messages, Events, Challenges.

Every button opens `features/<id>/screen.tscn`. Replace that scene with a Control-based feature screen as the feature is built. Each folder has a README and a placeholder scene. `game_hud.gd` emits `destination_opened(id)` for future integrations. Escape and Return to garden close the panel. Camera movement pauses while a panel is open. Tab/Enter can navigate buttons.

Weather now uses the shared neighborhood simulation and opens a working five-day forecast module; see `features/weather/README.md`. Social services, commerce and seasonal systems remain unconnected. Notification dots are omitted until actual unread/event state exists. Icons now use detailed generated transparent PNG artwork in `icons/storybook_icons.png`, a 4×3 atlas. `game_hud.gd` selects each cell with an AtlasTexture; the original SVG prototypes remain available. The world map uses a compass rose. The illustration's castle, avatar and dog are not part of this UI assignment. Visual art approval is still pending.

The HUD uses a 1280×720 canvas that scales with the window. Standalone 64px icons have 76px interaction targets and consistent spacing; button hover/focus adds a subtle highlight. Feature panels use a warm parchment background.

Validation with Godot 4.6.3: SVG import and main-scene startup passed after explicitly typing the existing world ground color variable. Run the navigation smoke check with:

```
godot --headless --path . --script res://ui/verify_hud.gd
```

The check opens all 12 destinations, verifies their screen instances, camera blocking and Escape dismissal. The running game was captured using a virtual Xorg display and software rendering; screenshot: `/workspace/previews/allotment-game-screen.png`. Detailed icon art is ready for owner review.
