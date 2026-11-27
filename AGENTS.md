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

## Permanent real-life growth and scale rule
- Owner instruction, 2026-11-16: build every future living plant with its own real-world growth stages and metre-scale dimensions. Every future object must use realistic physical scale.
- New plant profiles need scientific/cultivar identity, named visual phases, real elapsed-day age knots, height/width/depth curves, mature clearance, source URLs, and a clear distinction between referenced facts and calibrated estimates. Do not silently substitute accelerated growth or a generic adult mesh scaled through all stages.
- Run all-profile growth/scale tests and the new-profile data contract before presenting additions as implemented. Count distinct plant profiles honestly; mesh detail variants and stages are not species. Preserve existing saves and mature scenery while extending living versions. See features/market/REAL_LIFE_GROWTH.md within the game project.

## Development reporting

- Read `docs/ai-handoff/LATEST.md` and `docs/ai-handoff/BACKLOG.md` when resuming work.
- Record material milestones using `docs/ai-handoff/HANDOFF_GUIDE.md` and publish the records with the task's branch and pull request. Use reviewed development summaries in the public repository.
- Maintain `docs/ai-handoff/AGENT_REGISTRY.md` for actual delegated agents and their assignments, deliverables, status and verification. Update it alongside milestone reports, preserve history, and explicitly disclose unavailable agent information rather than guessing.

## Backlog execution

- When the owner asks to work the backlog, fetch current main, read the generated backlog and inspect open GitHub issues and pull requests. Use matching issues as actionable task briefs; live PR status supersedes stale milestone status. Do not edit generated reports manually.
- Start with architecture audit issue #29, then coordinate Windows verification issue #30 with existing PR #16, unless a newer owner direction or documented dependency changes the order. Check for existing work before starting; use separate focused branches and link the issue in each PR.
- For machine-routed assignments, use the claim commands in the handoff guide. For existing work PRs, coordinate with the current owner. Record a milestone and report blockers and actual checks. Keep issues open until acceptance criteria are verified and review is complete. Update the agent registry and generated backlog through the existing milestone process. Do not automatically merge or make destructive changes.
- This queue supplies work to active sessions; it does not launch agents automatically.
