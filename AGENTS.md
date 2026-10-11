# Codex Instructions — The Allotment

## Read first
- Read `THE_ALLOTMENT_GAME_DESIGN.md` before proposing or implementing gameplay, world, environment or asset work.
- Treat it as a **design specification**, not as evidence that features are already implemented.
- Inspect the actual repository layout, Godot version, scene structure and current code before making assumptions.
- If a request conflicts with the design document or existing implementation, explain the conflict and propose a safe path.

## Protect the project
- Do not delete, overwrite or substantially refactor working content without explicit authorization.
- Prefer a separate feature branch and a pull request for each independently reviewable assignment. Do not merge into `main` automatically.
- Keep changes focused; avoid unrelated modifications.
- Never commit secrets, access tokens, local machine details or personal information.
- Preserve existing scenes, especially the working world, grass and stone pathway, unless the task explicitly calls for modifications.
- Check for pre-existing assets before creating duplicates.

## 3D assets and game systems
- Target the project's actual Godot version and conventions; verify rather than guess.
- Favor reusable, modular 3D scenes with clear naming, organized asset directories, realistic relative scale, sensible pivots, collision and efficient materials.
- Maintain the approved softly stylized, lush storybook look.
- French-neighborhood assets should reference authentic French landscape precedents described in the design document.
- Large grottos, ruins and monumental features are permitted; preserve useful planting space and navigation.
- Do not claim a 3D asset has been integrated into the game merely because a mesh or example exists.
- For procedural terrain or plot features, preserve deterministic saved-seed behavior when implementing or modifying it.

## Verification and handoff
- Run applicable Godot import/headless parse checks or project tests when available; report any checks you could not run.
- Provide a short handoff: what changed, files/scenes added or edited, how to preview in Godot, test results, and remaining issues.
- Include screenshots or a preview scene when feasible; request visual approval before considering art assets final.
- Ask a focused question when a missing decision would materially affect the work.
- Never silently alter established design decisions; propose edits to the design document for owner review.
