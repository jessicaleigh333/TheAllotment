# Master Botanical Registry — review contract

This is a **non-destructive registry** derived from 851 source rows in 14 source files. It preserves original source files and associates records by exact existing ID only. Other matching names are **candidates for human deduplication** and are not silently merged. The master export is **not yet wired to Godot** or Google Sheets.

- Canonical view: `master_botanical_registry.json` (833 distinct IDs).
- Google Sheets import: `master_botanical_review.csv` (833 data rows), with blank owner correction and approval columns.
- Review exceptions: `master_botanical_duplicate_candidates.csv`, including same-ID source overlaps and name-matches needing confirmation.
- Artwork and Godot asset paths are null until matching, real files are present and validated.
- The two November 14 image/library artifacts found earlier are not presumed to be individual cultivar illustrations. Reference art for individual roses must be attached and matched by ID before population.
- Separate identity/biology facts from visual artwork and 3D stage assets. Do not treat a provisional source as verified.
- When using the sheet as an input to Codex: validate ID uniqueness, source row checksums, legal path prefixes, asset existence, per-stage applicability, and approvals; review diffs before updating original JSON or Godot.
- Current statuses are intentionally conservative defaults; no model / art completion is claimed.

## Next integration step
Codex should implement a versioned importer and integrity checks, then update the CSV from registry changes, ideally with controlled two-way changes (Sheet → reviewed PR → GitHub). Never automatically replace source biological data with blank sheet cells.
