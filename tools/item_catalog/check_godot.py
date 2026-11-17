"""Run isolated Godot checks; detect assertion failures even when Godot does not exit."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
from .catalog import PROJECT,ROOT

SUITES=["verify_item_catalog","verify_plant_growth","verify_woody_growth","verify_market","verify_local_vault",
        "verify_local_profiles","verify_weather","verify_courtyard_decor","verify_real_scale","verify_french_collection",
        "verify_enchanted_collection","verify_rustic_collection","verify_woodland_collection","verify_garden_boundaries"]


def run(out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True);failures=[]
    if not (PROJECT/"features/market/item_atlas.png.import").is_file() or not (PROJECT/".godot/imported").is_dir():
        with tempfile.TemporaryDirectory(prefix="allotment-import-") as temp:
            base=Path(temp)
            for path in (base/"data",base/"config",base/"cache"):path.mkdir()
            env=dict(os.environ,XDG_DATA_HOME=str(base/"data"),XDG_CONFIG_HOME=str(base/"config"),XDG_CACHE_HOME=str(base/"cache"))
            log=out/"resource_import.log"
            with log.open("w") as file:
                result=subprocess.run(["godot","--headless","--path",str(PROJECT),"--editor","--import","--quit"],
                    env=env,stdout=file,stderr=subprocess.STDOUT,timeout=120)
            if result.returncode!=0 or "SCRIPT ERROR" in log.read_text():return ["resource_import"]
            print("resource_import PASS",flush=True)
    for name in SUITES:
        with tempfile.TemporaryDirectory(prefix="allotment-catalog-") as temp:
            base=Path(temp)
            for path in (base/"data",base/"config",base/"cache"):path.mkdir()
            env=dict(os.environ,XDG_DATA_HOME=str(base/"data"),XDG_CONFIG_HOME=str(base/"config"),XDG_CACHE_HOME=str(base/"cache"))
            log=out/(name+".log")
            with log.open("w") as file:
                try:
                    result=subprocess.run(["godot","--headless","--path",str(PROJECT),"--script","res://tests/"+name+".gd"],
                        env=env,stdout=file,stderr=subprocess.STDOUT,timeout=60)
                    code=result.returncode
                except subprocess.TimeoutExpired:code=-1
            text=log.read_text()
            passed=code==0 and "SCRIPT ERROR" not in text and "PASS" in text
            print(name,"PASS" if passed else "FAIL",flush=True)
            if not passed:failures.append(name)
    return failures


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--out",type=Path,required=True)
    args=parser.parse_args();raise SystemExit(bool(run(args.out)))
