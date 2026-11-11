"""Owner-only signed release builder. Private keys never enter player packages."""
from __future__ import annotations
import argparse, base64, hashlib, json, os, re, zipfile
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

APP = 'the-allotment-windows'
REPO = 'jessicaleigh333/TheAllotment'

def init_key(private: Path, public: Path) -> None:
    if private.exists() or public.exists():
        raise ValueError('Refusing to overwrite an existing release key')
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    private.parent.mkdir(parents=True, exist_ok=True)
    with private.open('xb') as f:
        f.write(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
    private.chmod(0o600)
    public.parent.mkdir(parents=True, exist_ok=True)
    public.write_bytes(key.public_key().public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo))

def sign(manifest: dict, private: Path) -> bytes:
    key = serialization.load_pem_private_key(private.read_bytes(), password=None)
    if not isinstance(key, rsa.RSAPrivateKey) or key.key_size != 2048:
        raise ValueError('Expected a 2048-bit RSA release key')
    raw = json.dumps(manifest, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode()
    signature = key.sign(raw, padding.PKCS1v15(), hashes.SHA256())
    return json.dumps({'payload': base64.b64encode(raw).decode(), 'signature': base64.b64encode(signature).decode()}, separators=(',', ':')).encode()

def package(game: Path, output: Path, version: str, build: int, private: Path, notes: str = '') -> dict:
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+(?:-[a-z0-9.-]+)?', version) or len(version) > 40 or not 1 <= build <= 2147483647:
        raise ValueError('Use a semantic version and a positive, increasing build number')
    if len(notes) > 2000:
        raise ValueError('Release notes exceed 2000 characters')
    required = [game / 'TheAllotment.exe', game / 'TheAllotment.pck']
    if not all(p.is_file() and not p.is_symlink() for p in required):
        raise ValueError('The exported Windows EXE and PCK are required')
    if required[0].read_bytes()[:2] != b'MZ':
        raise ValueError('The game executable is not a Windows PE file')
    files = required + [p for p in sorted(game.rglob('*')) if p.is_file() and p not in required and (p.suffix.lower() in ('.txt', '.md') or p.parent.name == 'licenses')]
    if any(p.is_symlink() for p in files) or len(files) > 128:
        raise ValueError('Unsupported release files')
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f'TheAllotment-Windows-{version}.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for p in files:
            z.write(p, p.relative_to(game).as_posix())
    inventory = {p.relative_to(game).as_posix(): {'size': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in files}
    manifest = {'schema': 1, 'app_id': APP, 'platform': 'windows-x86_64', 'version': version, 'build': build,
                'entrypoint': 'TheAllotment.exe', 'url': f'https://github.com/{REPO}/releases/download/windows-v{version}-b{build}/{archive.name}',
                'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'size': archive.stat().st_size,
                'unpacked_size': sum(x['size'] for x in inventory.values()), 'files': inventory, 'notes': notes}
    if manifest['size'] > 536870912 or manifest['unpacked_size'] > 2147483648:
        raise ValueError('Release exceeds launcher limits')
    envelope = sign(manifest, private)
    (output / 'update.json').write_bytes(envelope)
    (output / 'release-info.json').write_text(json.dumps({'tag': f'windows-v{version}-b{build}', 'archive': archive.name, 'version': version, 'build': build}, indent=2))
    return manifest

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    init = sub.add_parser('init-key')
    init.add_argument('--private', type=Path, required=True)
    init.add_argument('--public', type=Path, required=True)
    make = sub.add_parser('package')
    make.add_argument('--game', type=Path, required=True)
    make.add_argument('--out', type=Path, required=True)
    make.add_argument('--version', required=True)
    make.add_argument('--build', type=int, required=True)
    make.add_argument('--key', type=Path, required=True)
    make.add_argument('--notes', default='')
    args = parser.parse_args()
    if args.command == 'init-key':
        init_key(args.private, args.public)
        print('Release key created. Keep the private file in the owner-only publisher kit.')
    else:
        result = package(args.game, args.out, args.version, args.build, args.key, args.notes)
        print(json.dumps({'version': result['version'], 'build': result['build'], 'bytes': result['size']}))
if __name__ == '__main__':
    main()
