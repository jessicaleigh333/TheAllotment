# Windows release verification

[Issue #30](https://github.com/jessicaleigh333/TheAllotment/issues/30) uses [PR #16](https://github.com/jessicaleigh333/TheAllotment/pull/16)'s existing launcher, installer and updater. The PR tip `473e2ab` is an ancestor of the tested main `861f686`. Both existing projects were exercised in a detached checkout with Godot 4.6.3 official on Linux. All saves, install roots, keys and archives generated for testing were disposable. Production release files were not produced or published.

## Observed results

| Check | Result |
| --- | --- |
| Launcher protocol suite | PASS, exit 0. Disposable signed fixtures cover archive validation, initial offline media, upgrade, rollback, downgrade refusal, installation locks, interruption/tamper recovery, save sentinel preservation and the running-game guard. A malformed-input fixture emitted a Unicode warning. |
| Launcher HTTP suite | PASS, exit 0. Local server covered first install, upgrade, 404, truncated download, cancellation, installed-game preservation and running-game protection. |
| Game and launcher Windows-preset resource packs | PASS, both exported and booted with Linux Godot. The game printed its existing ObjectDB warning on shutdown. Local SHA-256 values below identify these test packs. |
| Exported game saves and gameplay | PASS on the PCK. External regression scripts verified profile creation and re-entry, profile separation, vault ZIP rotation and corrupt-file preservation, placement/reload, and climbing growth and reconstruction. |
| Live distribution | The configured public `releases/latest/download/update.json` returned HTTP 404. No current release manifest, matching archive, or production artifact checksum could be read back. |
| Full Windows build and install | **Open.** The Linux runner lacks a native Windows runtime. The official Windows template range request redirected to a host that returned HTTP 501 through this environment. The official download service returned 403. Release credentials and publisher material were not used. |
| Windows Actions execution | **Unverified.** GitHub's API endpoint for workflow history was inaccessible from this shell. The existing workflow is manual, and its build step uses the owner's private repository secret. |

Test pack SHA-256:

- Game `20024a3ac11bb81cb0942001f541b79c343d576d2ac2fa381410e0319b0d8ac1`
- Launcher `b1a9c902bc72b5c0fdf50c650ad2b0fe7fc9920c211889f632621cb20df502b1`

## Reproduce fixture and export checks

Run from a clean copy of main. Requires Godot 4.6.3 and the Python dependencies in `distribution/requirements-publisher.txt`. Use a free local port and independent XDG directories for each process run that writes saves.

```sh
work="$(mktemp -d)"
isolated() {
    run="$work/$1"
    shift
    mkdir -p "$run/data" "$run/config" "$run/cache"
    XDG_DATA_HOME="$run/data" XDG_CONFIG_HOME="$run/config" XDG_CACHE_HOME="$run/cache" "$@"
}
game="$PWD/the-allotment-garden-world-v-02"
launcher="$PWD/distribution/launcher"
python distribution/tests/create_fixtures.py "$work/fixtures"
isolated protocol godot --headless --path "$launcher" --script res://tests/test_protocol.gd -- "$work/fixtures"
python distribution/tests/http_fixture_server.py "$work/fixtures" 18763 &
fixture_server=$!
trap 'kill "$fixture_server" 2>/dev/null || true' EXIT
isolated http godot --headless --path "$launcher" --script res://tests/test_download.gd -- "$work/fixtures" http://127.0.0.1:18763
isolated import godot --headless --path "$game" --editor --import --quit
isolated packs godot --headless --path "$game" --export-pack 'Windows Desktop' "$work/TheAllotment.pck"
isolated packs godot --headless --path "$launcher" --export-pack 'Windows Desktop' "$work/TheAllotmentLauncher.pck"
(
    cd "$work"
    isolated game-smoke godot --headless --main-pack "$work/TheAllotment.pck" --quit-after 60
    isolated launcher-smoke godot --headless --main-pack "$work/TheAllotmentLauncher.pck" --quit-after 60
    for test in verify_profile_entry verify_local_vault verify_climbing_vines; do
        isolated "$test" godot --headless --main-pack "$work/TheAllotment.pck" --script "$game/tests/$test.gd"
    done
)
```

Confirm both exit status and PASS output for scripted checks. Game pack exports exclude the test scripts, which are loaded from the separate source checkout. No installer screenshots were captured because the native launcher flow remains unverified.

## Native release acceptance for #30

1. Use the existing **Windows garden beta** workflow on the agreed source revision, or run the existing `build_distribution.py` with official 4.6.3 templates in a disposable checkout. The build rewrites export presets in its working copy. Leave `draft_release` off for verification. Use the owner-configured key only in the approved release environment. A production build needs the key matching the pinned public key.
2. Record workflow run, source SHA, artifact filenames and ZIP hashes. Read the USB ZIP back, confirm its launcher executable and sidecar, verify the starter manifest with the pinned public key and verify the signed ZIP and file hashes. Record the version and build numbers of two signed packages before testing.
3. In a clean Windows user account or VM, disconnect network, extract the starter ZIP and launch from a directory containing spaces. Verify Play garden, create a disposable named profile, place an item and climbing plant, edit ground cover, save, close and reopen. Record profile ID, visible placement, growth stage and vault inventory.
4. Apply a higher signed build while the game is closed. Exercise online download, cancellation/interruption, blocked activation with a running game, and an offline media upgrade from a separately restored VM fixture. Confirm the same copied save opens after update and after selecting **Use previous version**. Check that rollback restores game code while the save and elapsed time retain player progress. Preserve an untouched backup of the test profile for byte comparison before game launch.
5. Verify the public channel only after owner-approved publication. Fetch the public manifest and its named archive, match the signed hashes against the tested package and verify updater behavior from an older build. Until then the public-channel gate stays open.

Keep the game identity `The Allotment - Garden World v0.2`, the Windows game data root `%APPDATA%\Godot\app_userdata\The Allotment - Garden World v0.2\` and the separate launcher data root stable. Fixture success does not establish compatibility of future save schema changes with rollback.
