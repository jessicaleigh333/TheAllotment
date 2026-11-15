"""Cross-platform Godot export and USB/CD distribution packaging."""
from __future__ import annotations
import argparse, os, shutil, subprocess, zipfile
from pathlib import Path
from publish_release import package

def run(command):
    subprocess.run([str(x) for x in command], check=True)

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--godot', default='godot')
    p.add_argument('--game-project', type=Path, required=True)
    p.add_argument('--distribution', type=Path, default=Path(__file__).resolve().parents[1])
    p.add_argument('--templates', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--key', type=Path, required=True)
    p.add_argument('--version', required=True)
    p.add_argument('--build', type=int, required=True)
    p.add_argument('--notes', default='Garden beta update')
    args = p.parse_args()
    from cryptography.hazmat.primitives import serialization
    key = serialization.load_pem_private_key(args.key.read_bytes(), password=None)
    expected_public = key.public_key().public_bytes(serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)
    pinned = serialization.load_pem_public_key((args.distribution / 'launcher/release-public.pem').read_bytes())
    if expected_public != pinned.public_bytes(serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo):
        raise ValueError('This private key does not match the public key pinned in the launcher')
    root = args.distribution.resolve()
    output = args.out.resolve()
    exported = output / 'exported-game'
    player = output / 'The Allotment'
    assets = output / 'release-assets'
    for folder in [exported, player, assets]: folder.mkdir(parents=True, exist_ok=True)
    # Do not rewrite app name/user data settings: existing gardens must carry forward.
    template = (args.templates / 'windows_release_x86_64.exe').resolve()
    if not template.is_file(): raise ValueError('Official Windows release template is missing')
    for project in [args.game_project, root / 'launcher']:
        preset = project / 'export_presets.cfg'
        text = f'''[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter="*.json,*.cfg,*.pem,*.txt,*.glb,*.png,*.svg,*.wav"
exclude_filter="tests/*,staging/*,*.md,private/*,export_presets.cfg"
export_path=""
script_export_mode=2
[preset.0.options]
custom_template/release="{template.as_posix()}"
binary_format/architecture="x86_64"
binary_format/embed_pck=false
codesign/enable=false
application/modify_resources=false
debug/export_console_wrapper=0
'''
        if project.resolve() == (root / 'launcher').resolve():
            text = text.replace('exclude_filter="tests/*,staging/*,*.md,private/*,export_presets.cfg"', 'exclude_filter="tests/*,*.md,export_presets.cfg"')
        preset.write_text(text)
        run([args.godot, '--headless', '--editor', '--path', project, '--import'])
        target = exported / 'TheAllotment.exe' if project == args.game_project else player / 'The Allotment Launcher.exe'
        run([args.godot, '--headless', '--path', project, '--export-release', 'Windows Desktop', target])
    credits = args.game_project / 'CREDITS.md'
    if credits.exists(): shutil.copy2(credits, exported / 'Game-Credits.md')
    licenses = args.game_project / 'assets/third_party/licenses'
    if licenses.exists(): shutil.copytree(licenses, exported / 'licenses', dirs_exist_ok=True)
    engine_license = root / 'GODOT-LICENSE.txt'
    if engine_license.exists():
        shutil.copy2(engine_license, exported / 'Godot-License.txt')
        shutil.copy2(engine_license, player / 'Godot-License.txt')
    manifest = package(exported, assets, args.version, args.build, args.key, args.notes)
    shutil.copy2(assets / f'TheAllotment-Windows-{args.version}.zip', player / 'starter-game.zip')
    shutil.copy2(assets / 'update.json', player / 'starter-update.json')
    shutil.copy2(root / 'PLAYER_README.txt', player / 'START HERE.txt')
    with zipfile.ZipFile(output / 'The_Allotment_Windows_USB.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for path in sorted(player.rglob('*')):
            if path.is_file(): z.write(path, path.relative_to(output))
    print('Windows game, launcher, signed update assets and USB ZIP built.', flush=True)
if __name__ == '__main__': main()
