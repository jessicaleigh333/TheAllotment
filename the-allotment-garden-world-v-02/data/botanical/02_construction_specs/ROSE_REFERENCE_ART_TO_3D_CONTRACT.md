# Rose reference artwork → 3D construction contract

**Status:** Design contract only. Reference images are NOT yet attached or verified.

## Records and storage
- Match all references to the rose's existing stable botanical `id`. Never infer cultivar identification from an image.
- Store reference image files under `res://data/botanical/art_reference/roses/<rose-id>/` or an equivalent tracked, accessible project asset directory.
- Each rose record may have `visual_references` with `hero_art_path`, `thumbnail_art_path`, `stage_art_paths`, `art_origin`, `art_status`, `art_review_notes`, `art_last_updated`, and `reference_asset_hash`. Empty paths remain null until an original image is present.
- Keep the existing botanical and 3D stage asset schema intact; link reference art separately from actual model assets (`stage_model_id`, `stage_render_path`).

## Codex asset creation
1. Load the real source illustration using a validated repository-relative path; do not generate a substitute silently.
2. Cross-check cultivar identity, petal count/form, inflorescence, habit, foliage and growth stages against reviewed botanical data. Flag disagreements rather than treating image art as scientific evidence.
3. Reuse family base geometry, rigs, materials and animations by reference when botanically appropriate; create cultivar overrides for unique features. Avoid replacing rose cultivars with mere recolors when their morphology differs.
4. Keep image reference, asset source paths, and rendered 3D previews alongside each cultivar record for owner QA.
5. Do not mark a model or art reference as approved until inspected. Missing artwork stays explicitly 'missing', not fabricated.
6. Include basic size/proportion tests, missing-path checks and reference-to-asset traceability in validation.

## Review spreadsheet columns
`Rose record ID`, `Hero art URL/path`, `Art thumbnail URL/path`, `Reference art status`, `Reference art notes`, `3D model family ID`, `Stage asset IDs`, `3D preview paths`, `3D review status`, `Owner corrections`.

Note: Google Sheets IMAGE formulas require a reachable image URL. Repository-relative asset paths alone do not display image thumbnails inside Sheets. Do not assert an image is attached until the referenced file is actually present.
