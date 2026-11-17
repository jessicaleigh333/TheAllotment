import copy
import csv
import json
from pathlib import Path
import sqlite3
import tempfile
import time
import unittest

from jsonschema import Draft202012Validator,ValidationError
from tools.botanical.foundation import IntegrityError,canonical,digest,strict_json
from . import catalog as c


class ItemTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory();cls.root=Path(cls.temp.name)
        cls.out=cls.root/"baseline";cls.report=c.build(cls.out)
        cls.bundle=strict_json((cls.out/"catalog.v1.json").read_text())
        cls.snapshot=strict_json((c.HERE/"source_snapshot.json").read_text())

    @classmethod
    def tearDownClass(cls):cls.temp.cleanup()

    def db(self):
        source=sqlite3.connect(self.out/"items.sqlite");db=sqlite3.connect(":memory:");source.backup(db);source.close()
        db.execute("PRAGMA foreign_keys=ON");return db

    def bad_snapshot(self,mutation):
        snapshot=copy.deepcopy(self.snapshot);mutation(snapshot)
        path=self.root/(self._testMethodName+".json");path.write_text(json.dumps(snapshot))
        return path

    def proposal(self,**extra):
        item=next(r for r in self.bundle["items"] if r["item_id"]=="bench")
        return {"change_id":"test-change","item_id":"bench","base_revision":item["revision"],
            "operation":"set","field":"owner_notes","proposed_json":'"Review fixture only"',"decision":"approved",
            "reviewer":"Test owner","reviewed_at":"2026-11-17T00:00:00Z","reason":"Test fixture",**extra}

    def test_complete_existing_catalog_and_distinct_domains(self):
        self.assertEqual(self.report["domains"],{"shop":159,"surface":84,"scenery":9,"avatar_option":10})
        ids=[r["item_id"] for r in self.bundle["items"]];self.assertEqual(len(ids),len(set(ids)))
        self.assertIn("tree",ids);self.assertIn("scenery:tree",ids)
        with self.db() as db:
            self.assertEqual(db.execute("SELECT count(*) FROM listing").fetchone()[0],159)
            self.assertEqual(db.execute("SELECT count(*) FROM external_id WHERE domain='surface'").fetchone()[0],84)

    def test_every_evaluated_shop_value_preserved(self):
        actual={r["item_id"]:r for r in self.bundle["items"]}
        for original in self.snapshot["shop"]:
            item=actual[original["id"]]
            self.assertEqual(item["legacy_shop_data"],original["resolved"])
            with self.db() as db:
                raw=db.execute("SELECT definition_json FROM item WHERE item_id=?",(original["id"],)).fetchone()[0]
                self.assertEqual(strict_json(raw)["original_source_record"],original["original"])
            self.assertEqual(item["physical"]["dimensions_m"],original["dimensions_m"])

    def test_free_shop_historical_prices_and_no_sale(self):
        with self.db() as db:
            self.assertEqual(db.execute("SELECT count(*) FROM listing WHERE effective_price!=0 OR sale_value IS NOT NULL").fetchone()[0],0)
            self.assertEqual(db.execute("SELECT source_price FROM listing WHERE item_id='bench'").fetchone()[0],180)
            self.assertEqual(db.execute("SELECT stack_limit FROM listing WHERE item_id='bench'").fetchone()[0],999)

    def test_botanical_authority_referenced_not_duplicated(self):
        with self.db() as db:
            self.assertEqual(db.execute("SELECT count(*) FROM botanical_reference").fetchone()[0],833)
            self.assertEqual(db.execute("SELECT count(*) FROM botanical_link WHERE plant_id IS NULL").fetchone()[0],16)
            self.assertEqual(db.execute("SELECT plant_id FROM botanical_link WHERE item_id='sunflower_seeds'").fetchone()[0],"sunflower")
            self.assertEqual(db.execute("SELECT plant_id FROM botanical_link WHERE item_id='sunflower@seed'").fetchone()[0],"sunflower")

    def test_schema_integrity_and_content_hash(self):
        schema=strict_json((c.HERE/"bundle.schema.json").read_text());Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema).validate(self.bundle)
        with self.assertRaises(ValidationError):Draft202012Validator(schema).validate({**self.bundle,"schema_version":"2"})
        self.assertEqual(self.bundle["content_hash"],digest(canonical({k:v for k,v in self.bundle.items() if k!="content_hash"})))
        with self.db() as db:self.assertEqual(db.execute("PRAGMA foreign_key_check").fetchall(),[])

    def test_missing_foreign_key_rejected(self):
        with self.db() as db:
            with self.assertRaises(sqlite3.IntegrityError):db.execute("INSERT INTO item_behavior VALUES('bench','unknown','{}')")
            with self.assertRaises(sqlite3.IntegrityError):db.execute("INSERT INTO item_asset VALUES('bench','unknown','model','{}')")

    def test_parent_cycles_rejected(self):
        with self.db() as db:
            db.execute("UPDATE item SET parent_id='sunflower@seed' WHERE item_id='sunflower'")
            with self.assertRaises(IntegrityError):c.validate(db)

    def test_category_and_component_cycles_rejected(self):
        with self.db() as db:
            db.execute("UPDATE category SET parent_id=category_id WHERE category_id='shop'")
            with self.assertRaises(IntegrityError):c.validate(db)
        with self.db() as db:
            db.execute("INSERT INTO asset_component VALUES('recipe:bench','recipe:bench','test')")
            with self.assertRaises(IntegrityError):c.validate(db)

    def test_request_receipt_does_not_create_item(self):
        source=self.root/"requests.csv";out=self.root/"requests.json"
        row={key:"" for key in c.REQUEST_COLUMNS}
        row.update(request_id="test-request",proposed_name="Future bench",related_item_id="bench",decision="draft")
        with source.open("w",newline="") as file:
            writer=csv.DictWriter(file,fieldnames=c.REQUEST_COLUMNS);writer.writeheader();writer.writerow(row)
        self.assertEqual(c.requests(self.out/"items.sqlite",source,out),1)
        self.assertIn("request_receipt_only",strict_json(out.read_text())["status"])
        with self.db() as db:self.assertEqual(db.execute("SELECT count(*) FROM item").fetchone()[0],262)

    def test_invalid_dimensions_rejected(self):
        with self.db() as db:
            db.execute("UPDATE physical SET dimensions_json='[-1,1,1]' WHERE item_id='bench'")
            with self.assertRaises(IntegrityError):c.validate(db)

    def test_duplicate_bad_schema_ids_and_categories_rejected(self):
        for label,operation in (
            ("duplicate",lambda s:s["shop"].append(s["shop"][0])),
            ("version",lambda s:s.update(schema_version="9")),
            ("mismatch",lambda s:s["shop"][0]["resolved"].update(id="wrong")),
            ("category",lambda s:s["shop"][0]["resolved"].update(category="InventedCategory"))):
            with self.subTest(label=label):
                path=self.bad_snapshot(operation)
                with self.assertRaises((IntegrityError,sqlite3.IntegrityError)):c.build(self.root/label,snapshot_path=path)

    def test_asset_reuse_and_paths(self):
        with self.db() as db:
            self.assertEqual(db.execute("SELECT asset_id FROM item_asset WHERE item_id='rose' AND role='primary_model'").fetchone(),
                db.execute("SELECT asset_id FROM item_asset WHERE item_id='rose@seed' AND role='primary_model'").fetchone())
            self.assertGreater(db.execute("SELECT count(*) FROM asset_component").fetchone()[0],250)
            self.assertGreater(db.execute("SELECT count(*) FROM issue WHERE code='identical_asset_bytes'").fetchone()[0],0)
            self.assertEqual(db.execute("SELECT count(*) FROM issue WHERE code='missing_literal_reference'").fetchone()[0],0)
            for path, in db.execute("SELECT path FROM asset"):
                self.assertTrue((c.PROJECT/path).is_file(),path)

    def test_behaviors_do_not_claim_unfinished_mechanics(self):
        with self.db() as db:
            for bid in ("plant.water","plant.harvest","furniture.sit","item.sell","item.repair","item.craft"):
                self.assertEqual(db.execute("SELECT status FROM behavior WHERE behavior_id=?",(bid,)).fetchone()[0],"contract_only")
                self.assertEqual(db.execute("SELECT count(*) FROM item_behavior WHERE behavior_id=?",(bid,)).fetchone()[0],0)
            self.assertEqual(db.execute("SELECT count(*) FROM item_behavior WHERE item_id='watering_can' AND behavior_id='plant.water'").fetchone()[0],0)

    def test_duplicate_conflict_stale_identity_economy_guards(self):
        with self.db() as db:
            for override in ({"base_revision":"0"*64},{"field":"item_id"},{"field":"price"},{"field":"physical"},
                {"field":"asset_bindings"},{"reviewer":""},{"operation":""},{"decision":"Approved"},{"reviewed_at":"2026-99-99T00:00:00Z"}):
                with self.subTest(override=override),self.assertRaises((IntegrityError,ValueError)):
                    c.validate_changes(db,[self.proposal(**override)])
            with self.assertRaises(IntegrityError):c.validate_changes(db,[self.proposal(),self.proposal()])

    def test_review_overlay_retry_chain_and_reversible_values(self):
        with self.db() as db:
            first=self.proposal();accepted=c.validate_changes(db,[first]);c.apply_changes(db,accepted)
            self.assertEqual(c.validate_changes(db,[first]),[])
            self.assertEqual(db.execute("SELECT before_json FROM change_history").fetchone()[0],'""')
            rev=db.execute("SELECT revision FROM item WHERE item_id='bench'").fetchone()[0]
            second=self.proposal(change_id="second",base_revision=rev,proposed_json='"Next note"')
            c.apply_changes(db,c.validate_changes(db,[second]));self.assertEqual(len(c.history(db)),2)
            # Metadata correction must not alter live shop source dictionaries.
            definition=strict_json(db.execute("SELECT definition_json FROM item WHERE item_id='bench'").fetchone()[0])
            self.assertEqual(definition["legacy_shop_data"]["name"],"Garden bench")

    def test_clear_and_blank_semantics(self):
        with self.db() as db:
            self.assertEqual(c.validate_changes(db,[{"decision":""},{"decision":"draft"}]),[])
            with self.assertRaises((IntegrityError,ValueError)):c.validate_changes(db,[self.proposal(proposed_json="")])
            with self.assertRaises(IntegrityError):c.validate_changes(db,[self.proposal(field="name",operation="clear",proposed_json="null")])
            self.assertEqual(c.validate_changes(db,[self.proposal(operation="clear",proposed_json="null")])[0]["proposed_json"],"null")

    def test_full_rebuild_deterministic(self):
        second=self.root/"deterministic";c.build(second)
        self.assertEqual((self.out/"catalog.v1.json").read_bytes(),(second/"catalog.v1.json").read_bytes())
        self.assertEqual((self.out/"manifest.json").read_bytes(),(second/"manifest.json").read_bytes())

    def test_output_cannot_overwrite_inputs(self):
        with self.assertRaises(IntegrityError):c.build(self.out)
        with self.assertRaises(IntegrityError):c.build(c.PROJECT/"data/items/unsafe")

    def test_sql_index_scale(self):
        start=time.monotonic()
        with self.db() as db:
            for i in range(10000):
                db.execute("SELECT item_id FROM item WHERE item_id=?",("bench" if i%2 else "not_found",)).fetchone()
        self.assertLess(time.monotonic()-start,3,"10,000 indexed lookups should not scan the catalog")

    def test_workbook_and_actual_thumbnails(self):
        from .workbook import create
        from openpyxl import load_workbook
        path=self.root/"review.xlsx";create(self.out,path)
        book=load_workbook(path)
        self.assertEqual(book["Master Item Catalog"].max_row,263)
        self.assertEqual(book["Artwork Review"].max_row,160)
        self.assertEqual(len(book["Artwork Review"]._images),159)
        self.assertEqual(book["Master Item Catalog"].freeze_panes,"C2")
        self.assertIn("Owner Corrections",book.sheetnames);self.assertIn("New Item Requests",book.sheetnames)
        for sheet in book:
            for row in sheet:
                self.assertFalse(any(cell.data_type=="f" for cell in row))
        book.close()


if __name__=="__main__":unittest.main()
