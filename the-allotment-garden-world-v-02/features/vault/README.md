# Local garden save vault

Use **Save garden · Local vault** at the top of the playable garden, or **Settings → Save garden now**. A visible status confirms success or explains a failure. The game also checkpoints every 60 seconds, on focus loss, before Return to title and on a normal window close. If closing fails to save, the player may return to the garden or explicitly quit anyway.

The existing title Login chooses a local saved profile; Create Account creates a local profile only. There are no account services, passwords, subscriptions, multiplayer or server connections. Saves stay on the computer running the game. GitHub/source downloads do not synchronize player saves. Settings → Open my save folder opens the active local folder.

## Saved progress

- Plants, initial/observed real ages, placed decorations and rotations, supported vertical assemblies, Backpack contents and favorites use the existing atomic `market.json` store.
- Completed landscaping strokes and undo/redo operations now save immediately. The vault saves an in-progress completed stroke too, and restores landscaping on garden entry without requiring the editor to be opened.
- Avatar appearance keeps its existing saved appearance file.
- `session.json` adds the last player position, facing and walking-camera view. Reopening resumes on foot; temporary placement/overview cameras do not become the walking camera.
- Vine geometry is reconstructed from saved plants and structures. Offline plant age is calculated on reopening from actual elapsed seconds, never from the game lighting clock.

Named profiles use `user://profiles/<random-id>/`; the legacy unprofiled garden uses `user://`. The first named profile copies legacy appearance, market, landscaping, session and existing vault backups without deleting the originals. Device-wide title sound/calendar preferences retain their existing separate config file.

## Backups and errors

Each successful checkpoint creates and reads back a ZIP snapshot of market, session, existing avatar appearance and landscaping JSON. `vault/latest.zip` is the newest verified backup and `vault/previous.zip` is the prior one. Rotation occurs only after validating the new archive's contents. Copy the entire active save folder somewhere else for an additional personal backup; deleting a local profile folder also deletes its vault. These are ordinary local files, not an encrypted credential vault or cloud backup. Backup import/restore controls and device synchronization are not implemented.

Profile, market and session validation prevent damaged files from being silently replaced by defaults. A failed landscaping load blocks vault saves so its file is preserved. Each data file uses a temporary file/rename; a complete checkpoint is not a cross-file database transaction. If the archive cannot be written, status explicitly says progress was saved but backup failed. Existing corrupt files require repair from a valid backup; the game does not silently restore over them.

`tests/verify_local_vault.gd` checks manual and timed saves, ZIP contents and rotation, last-position/market/landscaping restoration, Settings controls, malformed session/market/landscaping preservation and isolated profiles. Tests run with fresh XDG data directories; personal progress is never part of the project ZIP or source commit.
