# Storybook countryside backdrop

`storybook_countryside.png` is generated illustrated background art, integrated for visual review. Run the main project with F5 to preview it behind the live 3D neighborhood.

`ui/world_backdrop.tscn` uses a non-interactive TextureRect on CanvasLayer -10. It fills the window with aspect-preserving cover scaling. `courtyard_world.gd` sets the environment to BG_CANVAS and includes layers up to -1 behind the 3D map. The HUD stays above the map. The separate asset staging scene retains its plain background.

This is a static decorative illustration, with clouds, a warm sky, countryside hills, a cottage and flowers. It does not add interactive terrain or alter garden acreage. Art status: integrated, ready for owner review.
