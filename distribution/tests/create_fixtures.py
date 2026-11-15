from pathlib import Path
import argparse, hashlib, json, sys, zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from publish_release import init_key, package, sign

def main(root):
    root.mkdir(parents=True, exist_ok=True)
    init_key(root/'test-private.pem', root/'test-public.pem')
    init_key(root/'wrong-private.pem', root/'wrong-public.pem')
    game=root/'game';game.mkdir()
    manifests=[]
    for build in [1,2,3,4]:
        (game/'TheAllotment.exe').write_bytes(b'MZ'+b'Windows-test-executable-'+str(build).encode())
        (game/'TheAllotment.pck').write_bytes(b'game pack '+str(build).encode())
        folder=root/str(build)
        manifest=package(game,folder,f'0.3.{build}',build,root/'test-private.pem','Integration test release')
        manifests.append(manifest)
    for kind in ['traversal','symlink','duplicate','oversize']:
        folder=root/kind;folder.mkdir()
        archive=folder/'attack.zip'
        with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
            for p in game.iterdir(): z.write(p,p.name)
            if kind=='traversal': z.writestr('../escaped.txt','escape')
            if kind=='duplicate': z.writestr('theallotment.exe','collision')
            if kind=='symlink':
                info=zipfile.ZipInfo('link.txt');info.create_system=3;info.external_attr=0o120777<<16
                z.writestr(info,'../../saves')
        raw=bytearray(archive.read_bytes())
        if kind=='oversize':
            central=raw.index(b'PK\x01\x02')
            raw[central+24:central+28]=(536870913).to_bytes(4,'little')
            archive.write_bytes(raw)
        manifest=manifests[-1].copy();manifest['sha256']=hashlib.sha256(raw).hexdigest();manifest['size']=len(raw)
        (folder/'update.json').write_bytes(sign(manifest,root/'test-private.pem'))
    print('Generated disposable test fixtures (no production signing key).')
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('directory',type=Path)
    main(parser.parse_args().directory)
