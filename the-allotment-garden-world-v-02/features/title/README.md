# Seasonal garden title screen

F5 starts `title_screen.tscn`. Four seasonal illustrations preserve the supplied title composition, woman, dog, title and button positions. Spring uses the cleaned original; summer, autumn and winter are image-generated edits of it. The images are regenerated derivatives of the supplied iPad screenshot rather than pixel-exact crops. They remain ready for visual review.

The title defaults to the computer's local clock and meteorological season: spring March–May, summer June–August, autumn September–November, winter December–February. Southern Hemisphere shifts this by six months. Day runs 08:00–18:00; twilight blends 06:00–08:00 and 18:00–20:00; full night is 20:00–06:00. This is a fixed artistic schedule, not calculated local sunrise/sunset. It refreshes every 30 seconds while open. The gear offers automatic/individual season, automatic/day/night and hemisphere settings, saved locally with volume, mute and reduced motion.

Every seasonal image supports a cool moonlit night treatment with readable title/plaques and a warm lantern pool. Local shader motion sways foliage, breathes the dog's chest and flickers the lantern. An extra animated butterfly appears in daylight except winter. Reduced motion stops these animations and hides the extra butterfly. The dog is a restrained 2D effect rather than a rigged animation. Wider displays retain dark green side margins without cropping the art.

Original procedural breeze and soft insects loop quietly, with chimes initially after 14–24 seconds and then 22–46 seconds apart. Winter silences insects; autumn reduces them. No paid recordings or online audio services are used.

The painted Login plaque opens the local saved-profile chooser. Create Account creates a local profile; neither requests passwords or contacts account services. Enter garden goes directly to the playable garden. Return to title in the exploration controls allows switching profiles. The existing onboarding-preview scene is retained separately but no longer required to enter the game.

Validation in Godot 4.6.3: all eight seasonal/day-night combinations rendered under OpenGL Compatibility; seasonal/month/hemisphere/clock assertions, title controls and local-profile entry passed. The project targets Godot 4.7; owner visual/audio approval in 4.7.2 remains pending.

Tests: `tests/verify_title.gd`, `tests/verify_local_profiles.gd`, `tests/verify_profile_entry.gd`. Run profile tests with a fresh isolated XDG_DATA_HOME to avoid using real profiles. See `features/profiles/README.md` for save behavior.

Night glow update: the lantern has a warm halo; bright fountain water/edges catch cyan light; three small flower clusters have jewel-like accents; fourteen sparse drifting lights stay in the planting margins. Winter lights shift to icy blue. These effects fade with night lighting, leaving daytime art unchanged. Reduced motion freezes firefly drift/pulsing while retaining steady light. Soft halos are computed directly in the canvas shader, so Compatibility mode does not require bloom.
