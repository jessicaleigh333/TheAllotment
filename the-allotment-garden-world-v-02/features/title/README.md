# Garden title screen

The project now starts at `title_screen.tscn`. The user-supplied garden screenshot was cleaned with image generation to remove the surrounding iPad interface; the resulting illustration retains the composition and painted button labels but is a regenerated derivative, not a pixel-exact crop.

Localized shader motion gently sways the canopy/foreground flowers and breathes the dog chest. Warm lantern illumination flickers. A small extra butterfly flutters across the open sky. These are restrained 2D effects; the dog is not a rigged character animation. The original illustration remains unmodified at runtime.

Login and Create Account have keyboard-focusable hit areas aligned to the painted plaques. Both continue the existing preview terms/neighborhood flow: authentication services remain unimplemented. Back to title dismisses that flow. The gear opens sound volume, mute, and reduced motion, saved locally. Reduced motion stops the shader movement and hides the extra butterfly. The illustration fits without cropping or stretching; wider displays have dark green side margins.

Breeze, insects and soft chimes are original procedural audio synthesized in `garden_ambience.gd`. Breeze/insects loop quietly. Chimes first occur after 14–24 seconds, then 22–46 seconds apart. Mute and volume zero silence the title ambience. Audio nodes are freed when the title scene exits. No paid assets or remote audio services are needed.

Preview: F5, or F6 on this scene. Test the gear, both account plaques, Back to title, and continue into the garden. Visual and audio approval is pending, especially on the owner's Godot 4.7.2 device.

Validation: Godot 4.6.3 import, title interaction/ambience assertions and a real OpenGL Compatibility screenshot using software rendering. `tests/verify_title.gd` exercises controls, sound settings, reduced motion and welcome flow. Preview screenshot is captured separately rather than shipped as a runtime asset.
