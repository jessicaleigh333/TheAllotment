"""Lossless, offline botanical build. Python 3.10+, standard library only."""
from __future__ import annotations

import argparse
import csv
from datetime import datetime
import hashlib
import itertools
import json
import math
from pathlib import Path, PurePosixPath
import re
import shutil
import sqlite3
import tempfile
from urllib.parse import urlparse

VERSION = "1.0.0"
SUPPORTED_SOURCE_VERSIONS = {"1.0", "1.0.0"}
DEFAULT_PROJECT = Path(__file__).resolve().parents[2] / "the-allotment-garden-world-v-02"
REVIEW_COLUMNS = ["change_id", "record_key", "plant_id", "field_path", "base_revision",
                  "operation", "proposed_json", "decision", "reviewer", "reviewed_at", "reason", "evidence_url"]


class IntegrityError(ValueError):
    pass


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False)


def digest(value):
    return hashlib.sha256(value if isinstance(value, bytes) else value.encode("utf-8")).hexdigest()


def strict_json(text):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise IntegrityError(f"Repeated JSON object key: {key}")
            result[key] = value
        return result
    def invalid(value):
        raise IntegrityError(f"Non-finite JSON value: {value}")
    return json.loads(text, object_pairs_hook=unique, parse_constant=invalid)


def escape(part):
    return str(part).replace("~", "~0").replace("/", "~1")


def leaves(value, pointer=""):
    """Include nulls, false, zero and empty containers; RFC 6901 pointers."""
    if isinstance(value, dict) and value:
        for key, item in value.items():
            yield from leaves(item, pointer + "/" + escape(key))
    elif isinstance(value, list) and value:
        for index, item in enumerate(value):
            yield from leaves(item, pointer + "/" + str(index))
    else:
        yield pointer, value


def json_type(value):
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, (float, int)):
        if not math.isfinite(value):
            raise IntegrityError("Non-finite number")
        return "number"
    return {str: "string", list: "array", dict: "object"}[type(value)]


def safe_relative(path):
    if not isinstance(path, str) or not path or "\\" in path or "\x00" in path:
        raise IntegrityError(f"Unsafe relative path: {path!r}")
    parts = path.split("/")
    if any(p in ("", ".", "..") for p in parts) or PurePosixPath(path).is_absolute() or ":" in path:
        raise IntegrityError(f"Unsafe relative path: {path!r}")
    return path


def checked_file(root, path):
    path = safe_relative(path)
    target = (root / path).resolve()
    if not target.is_relative_to(root.resolve()):
        raise IntegrityError(f"Path escapes input root: {path}")
    return target


def read_documents(root):
    docs, files = {}, {}
    for file in sorted(root.rglob("*")):
        if file.is_symlink():
            raise IntegrityError(f"Symlink input not allowed: {file}")
        if not file.is_file():
            continue
        path = file.relative_to(root).as_posix()
        safe_relative(path)
        files[path] = file.read_bytes()
        if file.suffix == ".json":
            value = strict_json(files[path].decode("utf-8"))
            if not isinstance(value, dict) or value.get("schema_version") not in SUPPORTED_SOURCE_VERSIONS:
                raise IntegrityError(f"Unsupported source schema: {path}")
            docs[path] = value
    registry = docs.get("master_registry/master_botanical_registry.json", {})
    if not isinstance(registry.get("records"), list):
        raise IntegrityError("Missing master registry")
    return docs, files


def collections(docs):
    """Explicit adapters: never treat a template or generated index as plant rows."""
    for path, doc in docs.items():
        if path in ("botanical_library.json", "rose_cultivar_register.json") or (
            path.startswith("01_scientific_records/") and
            Path(path).name not in ("cultivar_template.json", "family_genus_index_batch_002.json")
        ):
            key = "entries" if "entries" in doc else "records"
            rows = doc.get(key)
            if not isinstance(rows, list):
                raise IntegrityError(f"Unknown collection shape: {path}")
            declared = doc.get("record_count", doc.get("count", doc.get("taxon_count")))
            if declared is not None and declared != len(rows):
                raise IntegrityError(f"Declared row count mismatch: {path}")
            seen = set()
            for index, row in enumerate(rows):
                if not isinstance(row, dict) or not isinstance(row.get("id"), str) or not row["id"]:
                    raise IntegrityError(f"Missing record ID in {path}/{index}")
                if row["id"] in seen:
                    raise IntegrityError(f"Duplicate ID within source {path}: {row['id']}")
                seen.add(row["id"])
                yield path, f"/{key}/{index}", row


def issue(db, code, detail, plant_id=None, severity="warning"):
    key = digest(canonical([code, detail, plant_id]))
    db.execute("INSERT OR IGNORE INTO issue VALUES(?,?,?,?,?)", (key, severity, code, plant_id, detail))


def insert_fields(db, key, value):
    for pointer, item in leaves(value):
        db.execute("INSERT INTO field_value VALUES(?,?,?,?)", (key, pointer, canonical(item), json_type(item)))


def extract_evidence(db, key, value, pointer=""):
    if isinstance(value, dict):
        for name, item in value.items():
            extract_evidence(db, key, item, pointer + "/" + escape(name))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            extract_evidence(db, key, item, pointer + "/" + str(index))
    elif isinstance(value, str) and re.match(r"^https?://", value):
        # Keep a complete evidence context; a URL is a research lead, never verification.
        db.execute("INSERT INTO evidence(evidence_id,record_key,pointer,url,context_json) VALUES(?,?,?,?,?)",
                   (digest(key + pointer), key, pointer, value, canonical(get_context(db, key))))


def get_context(db, key):
    return strict_json(db.execute("SELECT effective_json FROM source_record WHERE record_key=?", (key,)).fetchone()[0])


def taxonomy(db, docs):
    path = "01_scientific_records/family_genus_index_batch_002.json"
    index = docs[path]
    if len(index["families"]) != index["family_count"] or len(index["genera"]) != index["genus_count"]:
        raise IntegrityError("Family/genus index count mismatch")
    for group, rank in (("families", "family"), ("genera", "genus")):
        for i, item in enumerate(index[group]):
            db.execute("INSERT INTO taxon_node VALUES(?,?,?,?,?,?)", (item["id"], item["name"], rank, path,
                       f"/{group}/{i}", "source_reported_unverified"))
    # Species/type nodes preserve exact existing handles; unresolved ranks stay unresolved.
    for i, record in enumerate(docs["01_scientific_records/taxonomic_skeleton_batch_002.json"]["records"]):
        db.execute("INSERT INTO taxon_node VALUES(?,?,?,?,?,?)", (record["id"], record["scientific_name"],
                   record.get("rank_hint", "unresolved"), "01_scientific_records/taxonomic_skeleton_batch_002.json",
                   "/records/" + str(i),
                   "source_reported_unverified"))
    for group, child_key in (("families", "child_genus_ids"), ("genera", "child_taxon_ids")):
        for i, parent in enumerate(index[group]):
            for j, child in enumerate(parent[child_key]):
                db.execute("INSERT INTO taxon_edge VALUES(?,?,?,?,?)", (parent["id"], child, path,
                           f"/{group}/{i}/{child_key}/{j}", "source_reported_unverified"))
    # Reject cycles regardless of source-reported scientific confidence.
    cycle = db.execute("""WITH RECURSIVE walk(a,b) AS (
        SELECT parent_id,child_id FROM taxon_edge UNION
        SELECT walk.a,taxon_edge.child_id FROM walk JOIN taxon_edge ON walk.b=taxon_edge.parent_id
        ) SELECT a FROM walk WHERE a=b LIMIT 1""").fetchone()
    if cycle:
        raise IntegrityError("Taxonomy contains a cycle")


def identity_scope(record):
    identity = record.get("identity", {})
    parent = record.get("parent_taxon")
    if isinstance(parent, dict):
        parent = parent.get("scientific_name")
    scientific = (identity.get("scientific_name") or record.get("scientific_name_or_cultivar") or
                  record.get("scientific_name") or record.get("parent_scientific_name") or
                  record.get("scientific_parent") or parent)
    selection = record.get("cultivar_or_selection") or record.get("cultivar_name") or identity.get("cultivar")
    # Starter batches often have only a display label; preserve it in the identity scope.
    if record.get("id", "").startswith("starter_"):
        selection = selection or next((record.get(k) for k in ("name", "common_name", "display_name") if record.get(k)), None)
    return scientific, selection


def identity_assertions(db):
    names={}
    for node,label in db.execute("SELECT node_id,label FROM taxon_node"):
        names.setdefault(label,[]).append(node)
    for key,pid,raw in db.execute("SELECT record_key,plant_id,effective_json FROM source_record").fetchall():
        row=strict_json(raw)
        for pointer,value in leaves(row):
            field=pointer.rsplit("/",1)[-1]
            if field not in ("family","genus","scientific_name","parent_scientific_name","scientific_parent",
                             "scientific_name_or_cultivar","cultivar_name","cultivar_or_selection","parent_taxon"):
                continue
            if not isinstance(value,str) or not value:
                continue
            matches=names.get(value,[])
            target=matches[0] if len(matches)==1 else None
            relation={"family":"family_label","genus":"genus_label","cultivar_name":"cultivar_label",
                      "cultivar_or_selection":"selection_label"}.get(field,"scientific_identity_label")
            db.execute("INSERT INTO identity_assertion VALUES(?,?,?,?,?,?,?,?)",(
                digest(key+pointer),pid,key,pointer,relation,value,target,"source_reported_unverified"))


def duplicate_candidates(db):
    buckets = {}
    for key, pid, raw in db.execute("SELECT record_key,plant_id,effective_json FROM source_record ORDER BY record_key"):
        record = strict_json(raw)
        scientific, selection = identity_scope(record)
        if scientific and isinstance(scientific, str):
            # Exact source identity scope; never merge and never infer an accepted taxon.
            scope = canonical([" ".join(scientific.casefold().split()),
                               " ".join(str(selection).casefold().split()) if selection else None])
            buckets.setdefault(scope, set()).add(pid)
    for scope, ids in sorted(buckets.items()):
        for left, right in itertools.combinations(sorted(ids), 2):
            db.execute("INSERT INTO duplicate_candidate VALUES(?,?,?,?,?,?)",
                       (digest(canonical([left,right,scope])),left,right,"matching_source_scientific_scope",
                        scope,"needs_identity_review"))
    for pid, count in db.execute("SELECT plant_id,count(*) FROM source_record GROUP BY plant_id HAVING count(*)>1"):
        issue(db, "same_id_multiple_sources", f"{count} independent source rows retained", pid)


ASSET_ROLES = ("original_illustration", "field_guide", "shop_thumbnail", "icon", "construction_reference",
               "base_model", "stage_model", "stage_preview", "animation", "material", "editable_source")


def assets(db, project, plant):
    pid = plant["plant_id"]
    art = plant.get("artwork", {})
    visual = plant.get("visual_3d", {})
    entries = [("original_illustration", None, art.get("hero_art_path"), "/artwork/hero_art_path"),
               ("shop_thumbnail", None, art.get("thumbnail_art_path"), "/artwork/thumbnail_art_path")]
    for role in ASSET_ROLES:
        if role not in ("original_illustration", "shop_thumbnail"):
            entries.append((role, None, None, "/visual_3d" if role in ("base_model", "stage_model", "stage_preview") else "/artwork"))
    for stage, path in art.get("stage_art_paths", {}).items():
        entries.append(("construction_reference", stage, path, "/artwork/stage_art_paths/"+escape(stage)))
    for stage, value in visual.get("stage_assets", {}).items():
        if isinstance(value, str):
            entries.append(("stage_model", stage, value, "/visual_3d/stage_assets/"+escape(stage)))
        elif isinstance(value, dict):
            entries.extend([(role, stage, value.get(field), "/visual_3d/stage_assets/"+escape(stage)+"/"+field)
                            for role,field in (("stage_model","stage_model_path"),("stage_preview","stage_render_path"))])
    for role, stage, path, pointer in entries:
        exists = False
        if path:
            try:
                if not isinstance(path, str):
                    raise IntegrityError("Asset path must be a string")
                relative = path[6:] if path.startswith("res://") else path
                exists = checked_file(project, relative).is_file()
                if not exists:
                    issue(db, "missing_asset_file", path, pid)
            except IntegrityError as error:
                raise IntegrityError(f"{pid}: {error}") from error
        db.execute("INSERT INTO asset_binding VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",
                   (digest(canonical([pid,role,stage,pointer])),pid,role,stage,path,
                    visual.get("model_family_id"),visual.get("base_model_id"),None,None,None,pointer,
                    "present_unreviewed" if exists else "missing",int(exists)))
    if not any(entry[2] for entry in entries):
        issue(db, "unlinked_art_and_models", "No actual registry artwork/model paths; November 14 rose images unverified", pid)


def parse_live_profiles(project):
    path = project / "features/market/plant_growth.gd"
    woody = project / "features/market/woody_growth.gd"
    if not path.is_file() or not woody.is_file():
        raise IntegrityError("Latest-main growth files required for compatibility audit")
    growth_text, woody_text = path.read_text(), woody.read_text()
    keys = re.findall(r'"([a-z_]+)"\s*:\s*(?:Woody\.PROFILES|\{)', growth_text.split("static func",1)[0])
    # Audit source strings, never evaluate GDScript or change runtime profiles.
    result = {}
    for key in keys:
        source = woody_text if f'"{key}":Woody.PROFILES' in growth_text else growth_text
        match = re.search(r'"'+re.escape(key)+r'"\s*:\s*(\{[^\n]+\})',source)
        result[key] = {"source_text": match[1] if match else "Woody.PROFILES reference", "basis":"unchanged_live_source"}
    if not result:
        raise IntegrityError("No live profiles found; update explicit audit adapter")
    return result


def validate_changes(db, rows):
    accepted, seen, locations = [], set(), set()
    historical = {r["change_id"]:r for r in previous_changes(db)}
    for row in rows:
        if row.get("decision") not in ("", "draft", "rejected", "approved"):
            raise IntegrityError("Unknown review decision")
        if row.get("decision") != "approved":
            continue
        if any(not str(row.get(k," ")).strip() for k in REVIEW_COLUMNS if k != "proposed_json"):
            raise IntegrityError("Approved change missing required review metadata")
        cid, key, pointer = row["change_id"],row["record_key"],row["field_path"]
        row={**row,"proposed_json":canonical(strict_json(row["proposed_json"]))}
        if cid in seen or (key,pointer) in locations:
            raise IntegrityError("Duplicate change ID or competing field edits")
        seen.add(cid); locations.add((key,pointer))
        if cid in historical:
            if any(row[k] != historical[cid][k] for k in REVIEW_COLUMNS):
                raise IntegrityError("Existing change ID reused with different content")
            continue
        record = db.execute("SELECT plant_id,effective_json,revision FROM source_record WHERE record_key=?",(key,)).fetchone()
        if not record or row["plant_id"] != record[0] or row["base_revision"] != record[2]:
            raise IntegrityError(f"Unknown record or stale base revision: {cid}")
        fields = dict(leaves(strict_json(record[1])))
        if pointer not in fields or pointer == "/id" or pointer.startswith(("/identity/", "/parent_taxon/")) or pointer in (
            "/scientific_name", "/scientific_name_or_cultivar", "/cultivar_name", "/parent_species_id", "/parent_taxon",
            "/parent_scientific_name", "/scientific_parent", "/family", "/genus", "/cultivar_or_selection"):
            raise IntegrityError("New fields and identity edits require a separate schema/identity review")
        if row["operation"] == "clear":
            if row["proposed_json"] != "null":
                raise IntegrityError("Clear requires explicit JSON null")
            value = None
        elif row["operation"] == "set":
            value = strict_json(row["proposed_json"])
            if fields[pointer] is not None and json_type(value) != json_type(fields[pointer]):
                raise IntegrityError("Type change requires schema review")
        else:
            raise IntegrityError("Only explicit set/clear operations are supported")
        if isinstance(value,(dict,list)) and value:
            raise IntegrityError("Container replacement requires structured schema review")
        if urlparse(row["evidence_url"]).scheme not in ("https","http") or not urlparse(row["evidence_url"]).netloc:
            raise IntegrityError("Evidence URL required")
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z",row["reviewed_at"]):
            raise IntegrityError("Review time must use UTC YYYY-MM-DDTHH:MM:SSZ")
        datetime.strptime(row["reviewed_at"],"%Y-%m-%dT%H:%M:%SZ")
        accepted.append({**{k:row[k] for k in REVIEW_COLUMNS}, "before_json":canonical(fields[pointer]), "after_json":canonical(value)})
    return sorted(accepted,key=lambda r:r["change_id"])


def previous_changes(db):
    cursor=db.execute("""SELECT c.change_id,c.record_key,r.plant_id,c.pointer,c.base_revision,c.operation,
        c.after_json,'approved',c.reviewer,c.reviewed_at,c.reason,c.evidence_url,c.before_json,c.after_json
        FROM review_change c JOIN source_record r USING(record_key) ORDER BY c.rowid""")
    return [dict(zip(REVIEW_COLUMNS+["before_json","after_json"],row)) for row in cursor]


def apply_changes(db, changes):
    for change in changes:
        key,pointer=change["record_key"],change["field_path"]
        value = get_context(db,key)
        parts = [p.replace("~1","/").replace("~0","~") for p in pointer[1:].split("/")]
        current = value
        for part in parts[:-1]:
            current = current[int(part)] if isinstance(current,list) else current[part]
        current[int(parts[-1]) if isinstance(current,list) else parts[-1]] = strict_json(change["after_json"])
        db.execute("UPDATE source_record SET effective_json=?,revision=? WHERE record_key=?",(canonical(value),digest(canonical(value)),key))
        db.execute("INSERT INTO review_change VALUES(?,?,?,?,?,?,?,?,?,?,?)",tuple(change[k] for k in (
            "change_id","record_key","field_path","operation","before_json","after_json","base_revision",
            "reviewer","reviewed_at","reason","evidence_url")))


def csv_cell(value):
    value = "" if value is None else str(value)
    # Preserve raw strings elsewhere; spreadsheet text must not execute formulas.
    return "'"+value if value.lstrip().startswith(("=","+","-","@")) else value


def write_csv(path, columns, rows):
    with path.open("w",newline="",encoding="utf-8") as stream:
        writer=csv.writer(stream);writer.writerow(columns)
        for row in rows:
            writer.writerow([csv_cell(value) for value in row])


def write_json(path, value):
    path.write_text(json.dumps(value,ensure_ascii=False,sort_keys=True,indent=2,allow_nan=False)+"\n",encoding="utf-8")


def export_build(db, out, input_hash):
    changes_hash=digest(canonical(list(db.execute("SELECT * FROM review_change ORDER BY change_id"))))
    content_hash=digest(canonical([input_hash,changes_hash]))
    tool_hash=digest(canonical({p.name:digest(p.read_bytes()) for p in sorted(Path(__file__).parent.iterdir())
                               if p.suffix in (".py",".sql",".json")}))
    db.execute("INSERT INTO metadata VALUES('content_hash',?)",(content_hash,))
    review = out/"sheets";review.mkdir()
    queries = {
        "Plants": "SELECT plant_id,identity_status,publication_status,registry_json FROM plant ORDER BY plant_id",
        "Fields": "SELECT r.plant_id,f.record_key,f.pointer,f.value_type,f.value_json,r.revision FROM field_value f JOIN source_record r USING(record_key) ORDER BY r.plant_id,f.record_key,f.pointer",
        "Sources": "SELECT e.evidence_id,r.plant_id,e.record_key,e.pointer,e.url,e.scope,e.review_status,e.context_json FROM evidence e JOIN source_record r USING(record_key) ORDER BY e.evidence_id",
        "Taxonomy": "SELECT * FROM taxon_node ORDER BY node_id",
        "TaxonomyLinks": "SELECT * FROM taxon_edge ORDER BY parent_id,child_id",
        "Relationships": "SELECT * FROM record_relationship ORDER BY from_id,to_id,relation,record_key,pointer",
        "IdentityAssertions": "SELECT * FROM identity_assertion ORDER BY assertion_id",
        "Assets": "SELECT * FROM asset_binding ORDER BY binding_id",
        "GameplayBindings": "SELECT * FROM gameplay_binding ORDER BY legacy_id",
        "DuplicateCandidates": "SELECT * FROM duplicate_candidate ORDER BY candidate_id",
        "Issues": "SELECT * FROM issue ORDER BY issue_id",
        "Workflow": "SELECT plant_id,json_extract(registry_json,'$.review.botanical') AS botanical_review,json_extract(registry_json,'$.review.artwork') AS artwork_review,json_extract(registry_json,'$.review.model_3d') AS model_review,json_extract(registry_json,'$.review.gameplay') AS registry_gameplay_review,publication_status FROM plant ORDER BY plant_id",
    }
    field_query="SELECT r.plant_id,f.record_key,f.pointer,f.value_type,f.value_json,r.revision FROM field_value f JOIN source_record r USING(record_key) "
    for name,pattern in (("GrowingRequirements",("environment","site","soil","light","sun","water")),
                         ("LifeStages",("biology","physiology","life_cycle","flower","dorman","growth","harvest","propagat")),
                         ("HealthAndEcology",("health","ecology","pest","disease","pollinat","risk"))):
        queries[name]=field_query+"WHERE "+" OR ".join("f.pointer LIKE '%"+p+"%'" for p in pattern)+" ORDER BY r.plant_id,f.record_key,f.pointer"
    for name,query in queries.items():
        cursor=db.execute(query)
        write_csv(review/(name+".csv"),[c[0] for c in cursor.description],cursor)
    write_csv(review/"Changes.csv",REVIEW_COLUMNS,[])
    records=[]
    for pid,registry,status in db.execute("SELECT plant_id,registry_json,publication_status FROM plant ORDER BY plant_id"):
        raw_records=[{"record_key":key,"source_path":path,"source_pointer":pointer,"base_revision":revision,
                      "original":strict_json(raw),"effective":strict_json(effective)}
                     for key,path,pointer,revision,raw,effective in db.execute(
                         "SELECT record_key,source_path,pointer,revision,raw_json,effective_json FROM source_record WHERE plant_id=? ORDER BY record_key",(pid,))]
        records.append({"plant_id":pid,"publication_status":status,"registry":strict_json(registry),"source_records":raw_records})
    write_json(out/"knowledge.json",{"schema_version":VERSION,"input_hash":input_hash,"content_hash":content_hash,"records":records,
                                   "purpose":"research_only_not_live_gameplay"})
    # Conservative publication gate: no research intake is implicitly approved.
    write_json(out/"godot_approved.json",{"schema_version":VERSION,"input_hash":input_hash,"content_hash":content_hash,
                                         "records":[r for r in records if r["publication_status"]=="approved"]})
    counts={table:db.execute("SELECT count(*) FROM "+table).fetchone()[0] for table in (
        "plant","source_record","field_value","evidence","taxon_node","taxon_edge","identity_assertion","duplicate_candidate","asset_binding","review_change")}
    issues=[dict(zip(("severity","code","plant_id","detail"),row)) for row in db.execute(
        "SELECT severity,code,plant_id,detail FROM issue ORDER BY issue_id")]
    write_json(out/"integrity_report.json",{"schema_version":VERSION,"counts":counts,"issues":issues,
        "scientific_verification_performed":False,"live_gameplay_modified":False})
    outputs={p.relative_to(out).as_posix():digest(p.read_bytes()) for p in sorted(out.rglob("*"))
             if p.is_file() and not p.name.startswith("botanical.sqlite")}
    write_json(out/"manifest.json",{"schema_version":VERSION,"input_hash":input_hash,"content_hash":content_hash,"tool_hash":tool_hash,"files":outputs,
        "source_files":dict(db.execute("SELECT path,sha256 FROM source_file ORDER BY path")),
        "review_changes_hash":changes_hash})


def build(project, out, overlay=None):
    project,out=Path(project).resolve(),Path(out).resolve()
    root=project/"data/botanical"
    if out.is_relative_to(project) or out.exists():
        raise IntegrityError("Output must be a new directory outside the Godot project")
    docs,files=read_documents(root)
    registry=docs["master_registry/master_botanical_registry.json"]
    out.parent.mkdir(parents=True,exist_ok=True)
    stage=Path(tempfile.mkdtemp(prefix=".botanical-",dir=out.parent))
    db=None
    try:
        db=sqlite3.connect(stage/"botanical.sqlite")
        db.executescript(Path(__file__).with_name("schema.sql").read_text())
        for path,content in files.items():
            db.execute("INSERT INTO source_file VALUES(?,?,?,?,?)",(path,digest(content),content,
                       docs.get(path,{}).get("schema_version"),"immutable_original"))
        seen=set()
        for plant in registry["records"]:
            pid=plant.get("plant_id")
            if not isinstance(pid,str) or not pid or pid in seen:
                raise IntegrityError(f"Missing or duplicate registry ID: {pid}")
            seen.add(pid)
            db.execute("INSERT INTO plant(plant_id,registry_json) VALUES(?,?)",(pid,canonical(plant)))
            for source in plant.get("source_files",[]):
                if safe_relative(source) not in files:
                    raise IntegrityError(f"Missing provenance source: {source}")
        rows=list(collections(docs))
        source_ids={row["id"] for _,_,row in rows}
        if source_ids!=seen or len(rows)!=registry["source_record_rows"] or len(seen)!=registry["unique_id_count"]:
            raise IntegrityError("Source/registry ID or count mismatch")
        for plant in registry["records"]:
            actual={path for path,_,row in rows if row["id"]==plant["plant_id"]}
            if actual != set(plant["source_files"]):
                raise IntegrityError(f"Registry/source provenance mismatch: {plant['plant_id']}")
        review_ids=[r["Plant ID"] for r in csv.DictReader(files["master_registry/master_botanical_review.csv"].decode("utf-8").splitlines())]
        if len(review_ids)!=len(set(review_ids)) or set(review_ids)!=seen:
            raise IntegrityError("Master review CSV IDs mismatch")
        for path,pointer,row in rows:
            raw=canonical(row);key=path+"#"+pointer
            db.execute("INSERT INTO source_record VALUES(?,?,?,?,?,?,?)",(key,row["id"],path,pointer,raw,raw,digest(raw)))
        if overlay:
            payload=strict_json(Path(overlay).read_text())
            if payload.get("schema_version")!=VERSION:
                raise IntegrityError("Unsupported overlay schema")
            for change in payload["changes"]:
                apply_changes(db,validate_changes(db,[change]))
        for key,effective in db.execute("SELECT record_key,effective_json FROM source_record ORDER BY record_key").fetchall():
            row=strict_json(effective);insert_fields(db,key,row);extract_evidence(db,key,row)
            if row.get("parent_species_id"):
                parent=row["parent_species_id"]
                if parent not in seen:
                    issue(db,"unresolved_parent_id",parent,row["id"])
                else:
                    db.execute("INSERT INTO record_relationship VALUES(?,?,?,?,?,?)",(row["id"],parent,"source_parent_profile",key,"/parent_species_id","source_reported_unverified"))
        taxonomy(db,docs);identity_assertions(db);duplicate_candidates(db)
        for plant in registry["records"]:
            assets(db,project,plant)
            if not plant.get("scientific_name"):
                issue(db,"missing_registry_scientific_name","Resolve using preserved source records",plant["plant_id"])
        live=parse_live_profiles(project)
        for legacy,profile in live.items():
            bound=legacy if legacy in seen else None
            db.execute("INSERT INTO gameplay_binding VALUES(?,?,?,?,?)",(legacy,bound,
                "legacy_id_match_unverified" if bound else "requires_identity_mapping","features/market/plant_growth.gd",canonical(profile)))
            if bound is None:
                issue(db,"unmapped_live_growth_profile",legacy)
        # Full typed leaf and source snapshot roundtrip, not just counts.
        for path,pointer,row in rows:
            raw=db.execute("SELECT raw_json FROM source_record WHERE source_path=? AND pointer=?",(path,pointer)).fetchone()[0]
            if strict_json(raw)!=row:
                raise IntegrityError("Lossless record roundtrip failed")
        if db.execute("PRAGMA foreign_key_check").fetchall() or db.execute("PRAGMA integrity_check").fetchone()[0]!="ok":
            raise IntegrityError("SQLite integrity check failed")
        input_hash=digest(canonical({path:digest(value) for path,value in sorted(files.items())}))
        for key,value in (("schema_version",VERSION),("input_hash",input_hash)):
            db.execute("INSERT INTO metadata VALUES(?,?)",(key,value))
        export_build(db,stage,input_hash)
        db.commit();db.close();db=None
        # Never write sources; fail if any input changed concurrently during build.
        if any(checked_file(root,path).read_bytes()!=content for path,content in files.items()):
            raise IntegrityError("Inputs changed during build")
        stage.rename(out)
        return strict_json((out/"integrity_report.json").read_text())
    finally:
        if db is not None:
            db.close()
        if stage.exists():
            shutil.rmtree(stage)


def open_database(path):
    db=sqlite3.connect(Path(path).resolve().as_uri()+"?mode=ro",uri=True)
    version=db.execute("SELECT value FROM metadata WHERE key='schema_version'").fetchone()
    if version!=(VERSION,):
        db.close();raise IntegrityError("Unsupported database schema")
    return db


def review_changes(database,csv_path,out):
    out=Path(out)
    if out.exists():
        raise IntegrityError("Refusing to overwrite a review artifact")
    with open_database(database) as db, Path(csv_path).open(newline="",encoding="utf-8-sig") as stream:
        reader=csv.DictReader(stream)
        if reader.fieldnames!=REVIEW_COLUMNS:
            raise IntegrityError("Unexpected Changes.csv columns")
        accepted=validate_changes(db,list(reader))
        write_json(out,{"schema_version":VERSION,"changes":previous_changes(db)+accepted,"purpose":"reviewed_overlay_not_source_replacement"})
    return len(accepted)


def restore_sources(database,out):
    out=Path(out)
    if out.exists():
        raise IntegrityError("Restore destination must not exist")
    with open_database(database) as db:
        rows=db.execute("SELECT path,sha256,content FROM source_file ORDER BY path").fetchall()
        for path,sha,content in rows:
            safe_relative(path)
            if digest(content)!=sha:
                raise IntegrityError("Corrupt source snapshot")
        stage=Path(tempfile.mkdtemp(prefix=".botanical-restore-",dir=out.resolve().parent))
        try:
            for path,sha,content in rows:
                target=checked_file(stage,path);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(content)
            stage.rename(out)
        finally:
            if stage.exists():
                shutil.rmtree(stage)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest="command",required=True)
    command=sub.add_parser("build");command.add_argument("--project",type=Path,default=DEFAULT_PROJECT)
    command.add_argument("--out",type=Path,required=True);command.add_argument("--overlay",type=Path)
    command=sub.add_parser("review");command.add_argument("--database",type=Path,required=True)
    command.add_argument("--changes",type=Path,required=True);command.add_argument("--out",type=Path,required=True)
    command=sub.add_parser("restore");command.add_argument("--database",type=Path,required=True);command.add_argument("--out",type=Path,required=True)
    args=parser.parse_args()
    try:
        if args.command=="build":
            print(canonical(build(args.project,args.out,args.overlay)["counts"]))
        elif args.command=="review":
            print(f"Validated {review_changes(args.database,args.changes,args.out)} proposed changes; no source or game files written")
        else:
            restore_sources(args.database,args.out);print("Restored immutable input snapshot")
    except (IntegrityError,sqlite3.Error,OSError,ValueError,KeyError,TypeError) as error:
        parser.exit(1,f"Botanical validation failed: {error}\n")


if __name__=="__main__":
    main()
