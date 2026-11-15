# The Allotment Windows launcher and update machine

The launcher installs a signed starter game from a USB/CD/download folder into the player's own Windows account, then checks the public release channel on startup and every 30 idle minutes. Automatic downloading/installing is enabled by default and can be disabled. Updates wait while the garden is open. Play works offline; no Godot, Python, account, administrator privileges or subscription is required on the player's computer.

This assignment adds distribution infrastructure; it does not alter the game world, garden save identity, real-time growth or local vault schemas. The game retains the exact application name `The Allotment - Garden World v0.2` so existing Godot-editor gardens can continue on the same Windows account. The launcher has a separate user-data folder.

## Player handoff

Give players only **The_Allotment_Windows_USB.zip**, or its extracted `The Allotment` folder. Keep the executable, launcher PCK, starter ZIP and starter signed description together. Start `The Allotment Launcher.exe`, then choose Play garden. Initial installation and signed newer starter copies can install offline; a CD remains read-only and later versions install on the computer. The first package is approximately 100 MB compressed, below a standard CD's capacity. Allow about 1 GB of working space for installs/updates.

The Windows executables are not Microsoft/Authenticode signed. The update payloads do have a separate pinned release signature; that protects the updater but does not establish Windows publisher reputation. A wider public release should receive a Windows desktop beta check. The launcher itself does not self-replace; future launcher/key changes require distributing a new launcher package.

## Online channel and owner publishing

`launcher/channel.json` points to the public repository's latest published release asset:

`https://github.com/jessicaleigh333/TheAllotment/releases/latest/download/update.json`

The source repository is public. The current branch/PR does **not** publish a live release. Until an owner-approved release containing `update.json` and its matching game ZIP is published, the launcher reports that the channel is unavailable and keeps playing the included version offline. Do not embed a GitHub password or token in the launcher. Future public game binaries are downloadable by anyone with their URLs; this channel is not access control.

Each payload has an application/platform ID, semantic version, monotonically increasing build number, exact archive size/hash, uncompressed total, entrypoint, notes and every file's size/hash. The exact JSON bytes are signed with RSA-2048 PKCS#1 v1.5 / SHA-256. The public key is pinned into the launcher; the **private key is only in the owner's separate publisher kit**, excluded from source/player archives. Retain that kit privately: it authorizes future game releases. The update-file signature is independent of commercial Windows certificate signing.

For a new release, export from the latest approved source and run:

```
python -m pip install -r distribution/requirements-publisher.txt
python distribution/tools/build_distribution.py --godot <godot-executable> --game-project the-allotment-garden-world-v-02 --templates <official-runtime-folder> --out <output-folder> --key <owner-private-key-file> --version 0.3.1 --build 2
```

Use the exact key matching `launcher/release-public.pem`; the build refuses a mismatch. Official Godot 4.6.3 Windows templates are required for this reproducible build. The script exports both game and launcher, copies credits/licenses, signs the update and prepares the USB package. It does not publish anything. Upload the game ZIP and `update.json` together to the tag named in `release-info.json`, review the draft, then publish it as the latest release. Higher build numbers are required even for corrective releases. Never replace an already-issued release with different bytes under the same build number.

The optional `.github/workflows/windows-beta.yml` automates Windows tests, exports and artifact uploads after it is merged into the repository's default branch. Add the private PEM to the repository secret `ALLOTMENT_UPDATE_SIGNING_KEY`, then use Actions → Windows garden beta → Run workflow. Its optional release step creates a **draft only**, requiring owner review before publication. Do not store the private key in repository files. This workflow was prepared here but has not been executed on GitHub/Windows in this session.

## Installation, recovery and save preservation

- Only HTTPS release URLs from the configured public repository are accepted. No device/account credentials travel with update checks. Godot's TLS verification remains enabled.
- Signed descriptions and downloaded bytes are bounded. Archive hash, every file hash/size, central directory, duplicate/case-colliding paths, absolute/traversal/drive/device paths, symbolic links, encryption, multidisk/ZIP64 layouts and oversized contents are checked before activation.
- Each new game installs in a fresh random version folder. Existing executable/PCK files are never overwritten in place. An atomic pointer selects the active version after readback verification. A previous pointer recovers interrupted/corrupt activation. A process lock serializes installs; stale locks can recover after the old process exits.
- The launcher remembers the game process across restarts and checks Windows process existence using the system task list. Download/install controls stay blocked while that process runs. One launcher window owns a session lock. Closing the launcher does not forcibly close the garden.
- Use previous version switches game code only; it does not overwrite or roll back garden saves. The highest received build remains recorded, so a rolled-back version is not immediately reinstalled from the same feed. Keep future game-save migrations compatible with any offered rollback.
- New releases retain the active and previous game folders. Older owned, signed version folders are pruned after successful activation. Download cancellation/failure preserves the active pointer. Garden/profile/vault data is never inside these version folders and is never copied, deleted, sent or restored by the updater.
- Game saves: `%APPDATA%\Godot\app_userdata\The Allotment - Garden World v0.2\`. Launcher installs/settings: `%APPDATA%\The Allotment Launcher\`.

## Validation

`tests/create_fixtures.py` makes disposable test keys/archives; it never uses the production private key. `launcher/tests/test_protocol.gd` verifies valid/invalid signatures, hashes, safe archive handling, first install, higher builds, rollback, downgrade refusal, concurrent locks, interrupted pointer/tampered-install recovery, unchanged garden-save sentinels, offline controls and live-game guards. `launcher/tests/test_download.gd` uses the local-only `tests/http_fixture_server.py` for real HTTP first install/upgrade, HTTP 404, truncated response, cancellation and game-running protection. HTTP is substituted only by the test harness; production release URLs remain HTTPS.

The actual signed starter ZIP is read back and installed by the launcher in the graphical preview. The Windows game/launcher are exported using official runtimes; PE headers and complete package inventories are checked. The exported game PCK is tested with the matching Godot editor/runtime for profile creation, world loading, placement, climbing plants, vault save/reopen and unchanged save identity. An official Linux release runtime checks normal sidecar-pack startup. These are not a claim of a native Windows desktop test: this environment has no Windows runtime, and Wine installation was unavailable because the package helper/sudo are absent. The supplied Windows CI job and the owner's desktop beta remain the native verification route.
