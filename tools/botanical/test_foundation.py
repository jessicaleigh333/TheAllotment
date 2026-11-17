import csv
import json
from pathlib import Path
import shutil
import sqlite3
import tempfile
import unittest

from jsonschema import Draft202012Validator, ValidationError

from . import foundation as f


class FoundationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.temp.name)
        cls.build = cls.root / "baseline"
        cls.report = f.build(f.DEFAULT_PROJECT, cls.build)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def database(self):
        return f.open_database(self.build / "botanical.sqlite")

    def project_copy(self, name):
        project = self.root / self._testMethodName / name
        shutil.copytree(f.DEFAULT_PROJECT / "data/botanical", project / "data/botanical")
        (project / "features/market").mkdir(parents=True)
        for file in ("plant_growth.gd", "woody_growth.gd"):
            shutil.copyfile(f.DEFAULT_PROJECT / "features/market" / file, project / "features/market" / file)
        return project

    def mutate(self, relative, operation):
        project = self.project_copy("input")
        path = project / "data/botanical" / relative
        value = json.loads(path.read_text())
        operation(value)
        path.write_text(json.dumps(value))
        return project

    def proposal(self, **overrides):
        with self.database() as db:
            key,revision = db.execute("SELECT record_key,revision FROM source_record WHERE plant_id='apple'").fetchone()
        return {"change_id":"owner-test-1", "record_key":key, "plant_id":"apple",
                "field_path":"/environment/ph_range", "base_revision":revision, "operation":"set",
                "proposed_json":"6.5", "decision":"approved", "reviewer":"Test fixture owner",
                "reviewed_at":"2026-11-17T00:00:00Z", "reason":"Test fixture, not scientific data",
                "evidence_url":"https://example.org/test-only", **overrides}

    def changes_csv(self, name, rows):
        path = self.root / self._testMethodName / name
        path.parent.mkdir(exist_ok=True)
        with path.open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=f.REVIEW_COLUMNS)
            writer.writeheader();writer.writerows(rows)
        return path

    def test_expected_counts_and_foreign_keys(self):
        self.assertEqual(self.report["counts"]["plant"],833)
        self.assertEqual(self.report["counts"]["source_record"],851)
        with self.database() as db:
            self.assertEqual(db.execute("PRAGMA foreign_key_check").fetchall(),[])
            self.assertEqual(db.execute("SELECT count(*) FROM gameplay_binding").fetchone()[0],16)
            self.assertEqual(db.execute("SELECT count(*) FROM gameplay_binding WHERE plant_id IS NULL").fetchone()[0],4)

    def test_source_bytes_roundtrip_and_restore(self):
        destination=self.root/"restored"
        f.restore_sources(self.build/"botanical.sqlite",destination)
        original=f.DEFAULT_PROJECT/"data/botanical"
        with self.database() as db:
            for path,sha,raw in db.execute("SELECT path,sha256,content FROM source_file"):
                self.assertEqual(raw,(original/path).read_bytes())
                self.assertEqual(raw,(destination/path).read_bytes())
                self.assertEqual(sha,f.digest(raw))
        with self.assertRaises(f.IntegrityError):
            f.restore_sources(self.build/"botanical.sqlite",destination)

    def test_all_fields_retain_values_and_types(self):
        with self.database() as db:
            for key,raw in db.execute("SELECT record_key,raw_json FROM source_record"):
                expected={p:(f.canonical(v),f.json_type(v)) for p,v in f.leaves(f.strict_json(raw))}
                actual={p:(v,t) for p,v,t in db.execute("SELECT pointer,value_json,value_type FROM field_value WHERE record_key=?",(key,))}
                self.assertEqual(actual,expected)

    def test_evidence_retains_exact_source_pointer(self):
        with self.database() as db:
            rows=db.execute("SELECT e.record_key,e.pointer,e.url,r.effective_json FROM evidence e JOIN source_record r USING(record_key)").fetchall()
            self.assertGreater(len(rows),800)
            for _,pointer,url,raw in rows:
                self.assertEqual(dict(f.leaves(f.strict_json(raw)))[pointer],url)
            self.assertTrue(db.execute("SELECT e.url FROM evidence e JOIN source_record r USING(record_key) WHERE r.plant_id='apple' AND e.url LIKE '%malus-domestica%'").fetchone())

    def test_name_collisions_not_duplicates(self):
        with self.database() as db:
            for left,right in db.execute("SELECT left_id,right_id FROM duplicate_candidate"):
                self.assertFalse("chandler" in left or "chandler" in right)
                self.assertFalse("heritage" in left or "heritage" in right)
            self.assertEqual(db.execute("SELECT count(*) FROM plant").fetchone()[0],833)
            self.assertEqual(db.execute("SELECT count(*) FROM source_record WHERE plant_id='rose-rosa-mundi'").fetchone()[0],2)

    def test_no_art_or_simulation_approval_inferred(self):
        with self.database() as db:
            self.assertEqual(db.execute("SELECT count(*) FROM asset_binding WHERE verified_exists=1").fetchone()[0],0)
            self.assertEqual(db.execute("SELECT count(*) FROM plant WHERE publication_status='approved'").fetchone()[0],0)
        self.assertEqual(json.loads((self.build/"godot_approved.json").read_text())["records"],[])

    def test_schema_and_deterministic_exports(self):
        schema=json.loads(Path(f.__file__).with_name("bundle.schema.json").read_text())
        Draft202012Validator.check_schema(schema)
        second=self.root/"second"
        f.build(f.DEFAULT_PROJECT,second)
        for name in ("knowledge.json","godot_approved.json"):
            value=json.loads((self.build/name).read_text())
            Draft202012Validator(schema).validate(value)
            with self.assertRaises(ValidationError):
                Draft202012Validator(schema).validate({**value,"schema_version":"9.0.0"})
        a=json.loads((self.build/"manifest.json").read_text())
        b=json.loads((second/"manifest.json").read_text())
        self.assertEqual(a,b)
        for name,sha in a["files"].items():
            self.assertEqual(f.digest((self.build/name).read_bytes()),sha)

    def test_existing_output_and_game_directory_rejected(self):
        with self.assertRaises(f.IntegrityError):
            f.build(f.DEFAULT_PROJECT,self.build)
        with self.assertRaises(f.IntegrityError):
            f.build(f.DEFAULT_PROJECT,f.DEFAULT_PROJECT/"new-runtime-assets")

    def test_duplicate_registry_id_rejected(self):
        project=self.mutate("master_registry/master_botanical_registry.json",lambda d:d["records"].append(d["records"][0]))
        out=project.parent/"out"
        with self.assertRaises(f.IntegrityError):f.build(project,out)
        self.assertFalse(out.exists())

    def test_duplicate_source_row_rejected(self):
        project=self.mutate("botanical_library.json",lambda d:d["entries"].append(d["entries"][0]))
        with self.assertRaises(f.IntegrityError):f.build(project,project.parent/"out")

    def test_unsupported_source_schema_rejected(self):
        project=self.mutate("botanical_library.json",lambda d:d.update(schema_version="2.0"))
        with self.assertRaises(f.IntegrityError):f.build(project,project.parent/"out")

    def test_broken_taxonomy_foreign_key_rejected(self):
        project=self.mutate("01_scientific_records/family_genus_index_batch_002.json",lambda d:d["families"][0]["child_genus_ids"].append("genus_missing"))
        with self.assertRaises(sqlite3.IntegrityError):f.build(project,project.parent/"out")

    def test_taxonomy_self_cycle_rejected(self):
        project=self.mutate("01_scientific_records/family_genus_index_batch_002.json",lambda d:d["families"][0]["child_genus_ids"].append(d["families"][0]["id"]))
        with self.assertRaises(sqlite3.IntegrityError):f.build(project,project.parent/"out")

    def test_source_traversal_rejected(self):
        project=self.mutate("master_registry/master_botanical_registry.json",lambda d:d["records"][0]["source_files"].append("../outside.json"))
        with self.assertRaises(f.IntegrityError):f.build(project,project.parent/"out")

    def test_asset_traversal_rejected(self):
        project=self.mutate("master_registry/master_botanical_registry.json",lambda d:d["records"][0]["artwork"].update(hero_art_path="res://../secret.png"))
        with self.assertRaises(f.IntegrityError):f.build(project,project.parent/"out")

    def test_missing_art_reference_is_reported(self):
        project=self.mutate("master_registry/master_botanical_registry.json",lambda d:d["records"][0]["artwork"].update(hero_art_path="res://assets/unlocated.png"))
        report=f.build(project,project.parent/"out")
        self.assertTrue(any(i["code"]=="missing_asset_file" for i in report["issues"]))

    def test_symlink_rejected(self):
        project=self.project_copy("input")
        (project/"data/botanical/link.json").symlink_to(project/"data/botanical/botanical_library.json")
        with self.assertRaises(f.IntegrityError):f.build(project,project.parent/"out")

    def test_approved_overlay_changes_effective_only(self):
        row=self.proposal()
        csv_path=self.changes_csv("changes.csv",[row])
        overlay=csv_path.with_suffix(".json")
        self.assertEqual(f.review_changes(self.build/"botanical.sqlite",csv_path,overlay),1)
        out=csv_path.parent/"updated"
        f.build(f.DEFAULT_PROJECT,out,overlay)
        with f.open_database(out/"botanical.sqlite") as db:
            raw,effective,revision=db.execute("SELECT raw_json,effective_json,revision FROM source_record WHERE record_key=?",(row["record_key"],)).fetchone()
            self.assertIsNone(json.loads(raw)["environment"]["ph_range"])
            self.assertEqual(json.loads(effective)["environment"]["ph_range"],6.5)
            self.assertNotEqual(revision,row["base_revision"])
            self.assertEqual(db.execute("SELECT count(*) FROM review_change").fetchone()[0],1)
        retry=csv_path.parent/"retry.json"
        self.assertEqual(f.review_changes(out/"botanical.sqlite",csv_path,retry),0)
        self.assertEqual(len(json.loads(retry.read_text())["changes"]),1)

    def test_stale_or_unscoped_approval_rejected(self):
        for override in ({"base_revision":"0"*64},{"reviewer":""},{"plant_id":"missing"},
                         {"evidence_url":"not-a-url"},{"operation":"implicit"},{"decision":"Approved"},
                         {"proposed_json":"NaN"},{"field_path":"/new_field"},{"field_path":"/id"},
                         {"field_path":"/environment/light","proposed_json":"12"}):
            with self.subTest(override=override), self.database() as db:
                with self.assertRaises((f.IntegrityError,ValueError)):
                    f.validate_changes(db,[self.proposal(**override)])

    def test_duplicate_changes_rejected(self):
        with self.database() as db:
            with self.assertRaises(f.IntegrityError):f.validate_changes(db,[self.proposal(),self.proposal()])

    def test_followup_overlay_preserves_change_chain(self):
        first=self.proposal()
        path=self.changes_csv("first.csv",[first]);overlay=path.with_suffix(".json")
        f.review_changes(self.build/"botanical.sqlite",path,overlay)
        out=path.parent/"v2";f.build(f.DEFAULT_PROJECT,out,overlay)
        with f.open_database(out/"botanical.sqlite") as db:
            revision=db.execute("SELECT revision FROM source_record WHERE record_key=?",(first["record_key"],)).fetchone()[0]
        second=self.proposal(change_id="owner-test-2",base_revision=revision,proposed_json="6.8")
        path2=self.changes_csv("second.csv",[second]);overlay2=path2.with_suffix(".json")
        f.review_changes(out/"botanical.sqlite",path2,overlay2)
        out3=path.parent/"v3";f.build(f.DEFAULT_PROJECT,out3,overlay2)
        with f.open_database(out3/"botanical.sqlite") as db:
            self.assertEqual(db.execute("SELECT count(*) FROM review_change").fetchone()[0],2)
            effective=db.execute("SELECT effective_json FROM source_record WHERE record_key=?",(first["record_key"],)).fetchone()[0]
            self.assertEqual(json.loads(effective)["environment"]["ph_range"],6.8)

    def test_future_profile_schema_does_not_require_season_as_age_stage(self):
        schema=json.loads(Path(f.__file__).with_name("profile.schema.json").read_text())
        Draft202012Validator.check_schema(schema)
        profile={"schema_version":"1.0.0","profile_id":"test-only","profile_version":"1",
            "plant_id":"apple","chronological_age_continues":True,"propagation_method":None,"developmental_stages":["juvenile","mature"],
            "size_knots":[],"seasonal_rules":[],"evidence":[],"calibration_basis":None,"capabilities":["identity"]}
        Draft202012Validator(schema).validate(profile)
        with self.assertRaises(ValidationError):
            Draft202012Validator(schema).validate({**profile,"chronological_age_continues":False})
        from .profiles import validate_profile
        self.assertTrue(validate_profile(profile,{"apple"}))
        with self.assertRaises(f.IntegrityError):validate_profile(profile,{"basil"})
        with self.assertRaises(f.IntegrityError):validate_profile({**profile,"capabilities":["size_growth"]},{"apple"})

    def test_profile_age_order_dimensions_and_evidence(self):
        from .profiles import validate_profile
        profile={"schema_version":"1.0.0","profile_id":"synthetic-test-only","profile_version":"1",
            "plant_id":"apple","chronological_age_continues":True,"propagation_method":"test_fixture",
            "developmental_stages":["test"],"size_knots":[],"seasonal_rules":[],"evidence":[],
            "calibration_basis":"Synthetic validation fixture, not botanical research","capabilities":[]}
        knot={"age_days":1,"height_m":1,"width_m":1,"depth_m":1,"basis":"calibrated_estimate","evidence_ids":["missing"]}
        with self.assertRaises(f.IntegrityError):validate_profile({**profile,"size_knots":[knot]},{"apple"})
        profile["evidence"]=[{"evidence_id":"fixture","scope":"test","review_status":"unverified"}]
        knot["evidence_ids"]=["fixture"]
        with self.assertRaises(f.IntegrityError):validate_profile({**profile,"size_knots":[knot,knot]},{"apple"})
        knot["height_m"]=-1
        with self.assertRaises(ValidationError):validate_profile({**profile,"size_knots":[knot]},{"apple"})

    def test_blank_and_rejected_rows_not_deletions(self):
        with self.database() as db:
            self.assertEqual(f.validate_changes(db,[{"decision":""},{"decision":"rejected"}]),[])
            with self.assertRaises(ValueError):f.validate_changes(db,[self.proposal(proposed_json="")])
            values=f.validate_changes(db,[self.proposal(operation="clear",proposed_json="null")])
            self.assertEqual(values[0]["after_json"],"null")

    def test_duplicate_keys_and_nonfinite_not_silently_lost(self):
        for text in ('{"a":1,"a":2}','{"a":NaN}','{"a":Infinity}'):
            with self.assertRaises(f.IntegrityError):f.strict_json(text)

    def test_pointer_and_empty_value_losslessness(self):
        value={"a/b":{"~key":[None,False,0,"",[],{}]}}
        self.assertEqual(list(f.leaves(value)),[("/a~1b/~0key/0",None),("/a~1b/~0key/1",False),
            ("/a~1b/~0key/2",0),("/a~1b/~0key/3",""),("/a~1b/~0key/4",[]),("/a~1b/~0key/5",{})])

    def test_spreadsheet_formula_injection_neutralized(self):
        for value in ("=HYPERLINK(\"bad\")"," +cmd","-1+2","@SUM(A1)"):
            self.assertTrue(f.csv_cell(value).startswith("'"))

    def test_workbook_contains_review_tabs_and_no_formulas(self):
        from .workbook import workbook
        from openpyxl import load_workbook
        out=self.root/"owner.xlsx"
        workbook(self.build,out)
        book=load_workbook(out,read_only=True)
        self.assertTrue({"Plants","Fields","Sources","Assets","Changes","IdentityAssertions"}.issubset(book.sheetnames))
        self.assertEqual(book["Plants"].max_row,834)
        for sheet in book:
            for row in sheet:
                self.assertFalse(any(cell.data_type=="f" for cell in row))
        book.close()


if __name__=="__main__":
    unittest.main()
