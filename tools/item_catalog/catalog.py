"""Reproducible offline item audit/build; no binary assets or player saves in SQLite."""
from __future__ import annotations
import argparse
import copy
import csv
from datetime import datetime
import json
from pathlib import Path
import re
import shutil
import sqlite3
import subprocess
import tempfile

from tools.botanical.foundation import (IntegrityError, canonical, digest, strict_json, safe_relative,
    checked_file, write_json, write_csv, csv_cell)

ROOT=Path(__file__).resolve().parents[2]
PROJECT=ROOT/"the-allotment-garden-world-v-02"
HERE=Path(__file__).parent
VERSION="1.0.0"
CHANGE_COLUMNS=["change_id","item_id","base_revision","operation","field","proposed_json","decision","reviewer","reviewed_at","reason"]
REQUEST_COLUMNS=["request_id","proposed_name","category","related_item_id","description","source_reference","decision","owner_notes"]
EDITABLE={"name","description","tags","owner_notes"}


def issue(db,code,detail,item=None):
    db.execute("INSERT OR IGNORE INTO issue VALUES(?,?,?,?)",(digest(canonical([code,detail,item])),code,item,detail))


def repository_files(repo):
    paths=subprocess.check_output(["git","ls-files","--cached","--others","--exclude-standard","-z"],cwd=repo).decode().split("\0")
    for relative in sorted(set(p for p in paths if p)):
        if relative.startswith((".git/",".item-build/",".botanical-build/")) or relative.endswith((".uid",".import")):
            continue
        if (repo/relative).is_symlink():
            raise IntegrityError("Symlink repository source")
        path=checked_file(repo,relative)
        if path.is_file():yield relative,path


def scan_repository(db,repo,project):
    game_prefix=project.relative_to(repo).as_posix()+"/"
    files={}
    for relative,path in repository_files(repo):
        # Runtime export is generated output, never its own source.
        if relative.startswith(game_prefix+"data/items/"):continue
        key=relative[len(game_prefix):] if relative.startswith(game_prefix) else "repo/"+relative
        raw=path.read_bytes();files[key]=raw
        db.execute("INSERT INTO source_file VALUES(?,?,?,?)",(key,digest(raw),len(raw),path.suffix or "file"))
        if not relative.startswith(game_prefix):continue
        ext=path.suffix.lower()
        if ext in (".gd",".gdshader",".tscn",".tres",".gltf",".png",".svg",".jpg",".jpeg",".hdr",".ogg",".wav",".glb",".blend",".bin"):
            aid="asset:"+key
            kind={".gd":"script",".gdshader":"shader",".tscn":"scene",".tres":"resource",
                  ".gltf":"model_source",".glb":"model",".blend":"editable_source",".bin":"mesh_buffer",
                  ".ogg":"audio",".wav":"audio"}.get(ext,"texture_or_artwork")
            db.execute("INSERT INTO asset VALUES(?,?,?,?,?,?,?,?,?)",(aid,key,None,kind,digest(raw),1,None,
                       "exists_not_owner_approved",canonical({"reference_status":"not_yet_analyzed"})))
        if ext in (".gd",".gdshader",".tscn",".tres",".godot",".md"):
            text=raw.decode("utf-8")
            for target in sorted(set(re.findall(r'''res://([^"'`\s\)\],]+)''',text))):
                target=target.rstrip(":.;")
                if target.startswith("data/items/"):continue  # Generated output is not an input dependency.
                # A dynamic directory/string prefix is not a missing file.
                if not Path(target).suffix or target.endswith(("/","+")):continue
                try:exists=checked_file(project,target).is_file()
                except IntegrityError:exists=False
                kind="dynamic_template" if any(token in target for token in ("%","{","<","*")) else "specification_path" if ext==".md" else "literal_res_path"
                db.execute("INSERT OR IGNORE INTO asset_reference VALUES(?,?,?,?)",(key,target,kind,int(exists)))
                if not exists:issue(db,"dynamic_reference_needs_runtime_resolution" if kind=="dynamic_template" else
                    "planned_reference_not_present" if kind=="specification_path" else "missing_literal_reference",key+" -> "+target)
            if ext==".gd":
                for n,line in enumerate(text.splitlines(),1):
                    match=re.match(r"\s*(?:static )?func ([A-Za-z_][A-Za-z0-9_]*)\(",line)
                    if match:
                        db.execute("INSERT INTO source_symbol VALUES(?,?,?,?,?,?)",(key+":"+match[1],key,match[1],n,"function",
                            "test" if "/tests/" in "/"+key else "staging" if key.startswith("staging/") else "runtime_or_reusable_definition"))
            if ext==".md":
                for n,line in enumerate(text.splitlines(),1):
                    if re.search(r"planned|not yet|future|remain.*unimplemented",line,re.I):
                        db.execute("INSERT INTO requirement VALUES(?,?,?,?,?)",(digest(key+str(n)+line),key,n,line,"specification_not_runtime"))
            if ext in (".tscn",".tres"):
                for match in re.finditer(r'\[sub_resource type="([^"]+)" id="([^"]+)"\]',text):
                    kind,sid=match.groups()
                    db.execute("INSERT INTO asset VALUES(?,?,?,?,?,?,?,?,?)",("asset:"+key+"#"+sid,key,sid,kind,None,1,None,
                               "embedded_resource_not_owner_approved",canonical({"source":"sub_resource"})))
        if ext==".gltf":
            doc=strict_json(raw.decode())
            for kind in ("meshes","materials","animations","textures","skins"):
                for index,value in enumerate(doc.get(kind,[])):
                    fragment=kind+"/"+str(index)
                    db.execute("INSERT INTO asset VALUES(?,?,?,?,?,?,?,?,?)",("asset:"+key+"#"+fragment,key,fragment,kind,None,1,None,
                               "embedded_resource_not_owner_approved",canonical({"name":value.get("name"),"definition":value})))
            for value in doc.get("buffers",[])+doc.get("images",[]):
                uri=value.get("uri","")
                if not uri or uri.startswith("data:"):continue
                target=(Path(key).parent/uri).as_posix()
                exists=checked_file(project,target).is_file()
                db.execute("INSERT OR IGNORE INTO asset_reference VALUES(?,?,?,?)",(key,target,"gltf_dependency",int(exists)))
    manifest_path=project/"assets/third_party/manifest.json"
    if manifest_path.is_file():
        for entry in strict_json(manifest_path.read_text())["assets"]:
            for value in entry.get("files",[]):
                key="assets/third_party/"+value["path"]
                db.execute("UPDATE asset SET license_json=? WHERE path=?",(canonical({k:v for k,v in entry.items() if k!="files"}),key))
    # Equal bytes are reuse candidates, not permission to delete files or erase licenses.
    for sha,count in db.execute("SELECT sha256,count(*) FROM asset WHERE sha256 IS NOT NULL GROUP BY sha256 HAVING count(*)>1"):
        issue(db,"identical_asset_bytes",canonical({"sha256":sha,"count":count}))
    for aid,path in db.execute("SELECT asset_id,path FROM asset WHERE fragment IS NULL"):
        incoming=db.execute("SELECT count(*) FROM asset_reference WHERE target_path=?",(path,)).fetchone()[0]
        db.execute("UPDATE asset SET metadata_json=? WHERE asset_id=?",(canonical({"literal_incoming_references":incoming,
            "usage":"literal_reference_present" if incoming else "no_literal_reference_dynamic_usage_unresolved"}),aid))
    return files


def add_category(db,key,label,parent=None):
    db.execute("INSERT OR IGNORE INTO category VALUES(?,?,?)",(key,label,parent))


def add_item(db,item):
    definition=canonical(item)
    db.execute("INSERT INTO item VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)",(item["item_id"],item["name"],item["domain"],item.get("legacy_id"),
        item.get("parent_id"),item["category_id"],item.get("collection"),item.get("description",""),item["source_path"],digest(definition),definition,
        item["implementation_status"],item.get("art_status","not_owner_reviewed"),"not_reviewed"))
    if item.get("legacy_id"):
        db.execute("INSERT INTO external_id VALUES(?,?,?)",(item["domain"],item["legacy_id"],item["item_id"]))
    physical=item.get("physical",{})
    db.execute("INSERT INTO physical VALUES(?,?,?,?,?,?,?,?,?,?)",(item["item_id"],
        canonical(physical.get("dimensions_m")),canonical(physical.get("pivot_m")),canonical(physical.get("footprint")),
        physical.get("placement_contract"),None,None,None,canonical(physical.get("clearance")),None))


def bind(db,item,asset,role,parameters=None):
    db.execute("INSERT OR IGNORE INTO item_asset VALUES(?,?,?,?)",(item,asset,role,canonical(parameters or {})))


def behavior(db,item,behavior_id,parameters=None):
    db.execute("INSERT INTO item_behavior VALUES(?,?,?)",(item,behavior_id,canonical(parameters or {})))


def procedural_asset(db,recipe):
    aid="recipe:"+recipe
    db.execute("INSERT OR IGNORE INTO asset VALUES(?,?,?,?,?,?,?,?,?)",(aid,"assets/garden_art/garden_library.gd",recipe,
        "procedural_model_recipe",None,1,None,"existing_recipe_art_review_pending",canonical({"recipe_id":recipe,"lod_count":3})))
    return aid


def ingest(db,project,snapshot):
    if snapshot.get("schema_version")!=VERSION:raise IntegrityError("Unsupported extraction schema")
    contract=strict_json((HERE/"behaviors.json").read_text())
    for b in contract["behaviors"]:
        if b["script_path"] and not checked_file(project,b["script_path"]).is_file():raise IntegrityError("Missing behavior script")
        db.execute("INSERT INTO behavior VALUES(?,?,?,?,?)",(b["behavior_id"],b["status"],b["script_path"],canonical(b),b["save_contract"]))
    registry_path="data/botanical/master_registry/master_botanical_registry.json"
    registry=strict_json((project/registry_path).read_text())
    if registry["schema_version"]!=VERSION:raise IntegrityError("Unsupported botanical reference schema")
    plants={r["plant_id"]:r for r in registry["records"]}
    if len(plants)!=len(registry["records"]):raise IntegrityError("Duplicate authoritative botanical ID")
    for pid,record in plants.items():
        db.execute("INSERT INTO botanical_reference VALUES(?,?,?)",(pid,registry_path,digest(canonical(record))))
    seen=set()
    for row in snapshot["shop"]:
        source=row["resolved"];iid=row["id"]
        if iid in seen:raise IntegrityError("Duplicate item ID: "+iid)
        if source.get("id")!=iid or not isinstance(iid,str) or not iid:raise IntegrityError("Inconsistent legacy ID")
        if source.get("category") not in ("Plants","Seeds","Decor","Avatar","Tools"):raise IntegrityError("Unreviewed shop category")
        if not isinstance(source.get("price",0),(int,float)) or source.get("price",0)<0:raise IntegrityError("Invalid historical price")
        seen.add(iid)
        add_category(db,"shop","Shop")
        category="shop:"+source["category"];add_category(db,category,source["category"],"shop")
        parent=iid.split("@")[0] if "@" in iid else None
        profile=source.get("plant")
        item={"item_id":iid,"name":source["name"],"domain":"shop","legacy_id":iid,"parent_id":parent,
            "category_id":category,"collection":row["collection"],"description":source.get("description",""),
            "tags":[source["category"],source.get("family",""),row["collection"],source.get("latin","")],
            "source_path":row["source"],"implementation_status":"functional_local_item_prototype_art",
            "physical":{"dimensions_m":row["dimensions_m"],"pivot_m":row["pivot_m"],
                "footprint":{"radius_m":source.get("radius",0),"mature_dimensions_m":row["mature_dimensions_m"]},
                "collision_shapes":row.get("collision_shapes",[]),
                "placement_contract":"placement.world" if source.get("radius",0)>0 else "not_world_placeable",
                "clearance":{"stack_top":row["stack_top"],"stack_foot":row["stack_foot"],"can_stack":row["can_stack"]}},
            "legacy_shop_data":source,"original_source_record":row["original"],"model_recipe":row["model_recipe"],
            "thumbnail":row["icon"],"variant_parameters":{"growth_stage":source.get("growth_stage"),"plant_profile":profile},
            "item_version":1,"owner_notes":"","review_status":"not_reviewed"}
        item["base_design_id"]="design:"+row["model_recipe"]
        item["variant_id"]=iid if parent else None
        item["related_item_ids"]=[]
        add_item(db,item)
        available=source.get("available",True)
        db.execute("INSERT INTO listing VALUES(?,?,?,?,?,?,?,?,?,?,?)",("listing:local:"+iid,iid,source.get("price"),0,"Runes",int(available),999,None,None,
            canonical({"local_demo_only":True,"free_direct_placement":True}),"Historical source price preserved; current acquisition is free. No sale mechanic."))
        model=procedural_asset(db,row["model_recipe"]);bind(db,iid,model,"primary_model",item["variant_parameters"])
        icon="asset:"+row["icon"]["path"].removeprefix("res://")
        bind(db,iid,icon,"shop_thumbnail",{"atlas_region":row["icon"].get("region")})
        for surface in row["surfaces"]:
            for material in surface["materials"]:
                role=material.get("role_id",-1)
                mid="material:mesh_builder:"+str(role)
                db.execute("INSERT OR IGNORE INTO asset VALUES(?,?,?,?,?,?,?,?,?)",(mid,"assets/garden_art/mesh_builder.gd",str(role),
                    "procedural_material",None,1,None,"existing_not_owner_approved",canonical(material)))
                db.execute("INSERT OR IGNORE INTO asset_component VALUES(?,?,?)",(model,mid,"material_role"))
        behavior(db,iid,"market.acquire")
        if source.get("radius",0)>0:
            behavior(db,iid,"placement.world");behavior(db,iid,"inventory.retrieve")
        if row["can_stack"]:behavior(db,iid,"construction.support")
        if row["gate_controller"]:behavior(db,iid,"gate.proximity")
        if row["glow_controller"]:behavior(db,iid,"lighting.day_night")
        if iid=="straw_hat":behavior(db,iid,"avatar.equip_hat")
        if "fountain" in iid:behavior(db,iid,"fountain.water_visual")
        if profile:
            behavior(db,iid,"growth.real_time")
            pid=profile if profile in plants else None
            db.execute("INSERT INTO botanical_link VALUES(?,?,?,?,?)",(iid,pid,profile,"legacy_profile_match_unverified" if pid else "requires_botanical_mapping",None))
            if not pid:issue(db,"unresolved_botanical_mapping",profile,iid)
        if iid=="watering_can":issue(db,"decorative_tool_only","Watering action is not connected",iid)
    for row in snapshot["recipes"]:
        aid=procedural_asset(db,row["id"])
        if row["id"].endswith("_leaf"):continue
        iid="scenery:"+row["id"];add_category(db,"scenery","Existing scenery")
        add_item(db,{"item_id":iid,"name":row["id"].replace("_"," ").capitalize(),"domain":"scenery","legacy_id":row["id"],
            "category_id":"scenery","source_path":row["source"],"implementation_status":"decorative_recipe_not_shop_listing",
            "physical":{"dimensions_m":row["dimensions_m"]},"description":"Existing scenery recipe; no new inventory entitlement.","tags":["scenery"]})
        bind(db,iid,aid,"scenery_model")
    ground_source="features/garden_editor/ground_cover/catalog.json"
    ground=strict_json((project/ground_source).read_text())
    for row in ground["materials"]+ground.get("border_materials",[]):
        category="surface:"+row["category"];add_category(db,"surface","Surface editor");add_category(db,category,row["category"],"surface")
        iid="surface:"+row["id"]
        add_item(db,{"item_id":iid,"name":row["name"],"domain":"surface","legacy_id":row["id"],"category_id":category,
            "source_path":ground_source,"implementation_status":"functional_surface_editor_not_shop_listing",
            "description":"Existing procedural ground/border material; no discrete object mass or height inferred.",
            "tags":[row["category"],"surface"],"material_parameters":row,
            "physical":{"footprint":{"cell_size_m":0.5},"placement_contract":"surface.paint"}})
        bind(db,iid,"asset:features/garden_editor/ground_cover/surface.gdshader","surface_shader",row)
        behavior(db,iid,"surface.paint")
    appearance="features/avatar/appearance.gd"
    for group,choices in {"hair":["long","bob","braids","bun"],"outfit":["dress","trousers"],
                          "accessory":["hat_enabled","flowers_enabled","satchel_enabled","apron_enabled"]}.items():
        add_category(db,"avatar_option","Avatar workshop options")
        for choice in choices:
            iid="avatar:"+group+":"+choice
            add_item(db,{"item_id":iid,"name":choice.replace("_"," "),"domain":"avatar_option","legacy_id":group+":"+choice,
                "category_id":"avatar_option","source_path":appearance,"implementation_status":"functional_appearance_option_not_shop_listing",
                "description":"Existing appearance option, not a separate purchasable asset.","tags":["avatar",group]})
            bind(db,iid,"asset:assets/characters/gardener/gardener.gltf","avatar_geometry",{"appearance_option":choice})
    for aid,path,exists in db.execute("SELECT asset_id,path,exists_on_disk FROM asset"):
        if not exists:issue(db,"missing_asset",path)
    for gate,leaf in {"garden_gate":"iron_gate_leaf","timber_gate":"timber_gate_leaf","chateau_gate":"chateau_gate_leaf",
                      "potager_gate":"potager_gate_leaf","branch_gate":"branch_gate_leaf"}.items():
        db.execute("INSERT INTO asset_component VALUES(?,?,?)",(procedural_asset(db,gate),procedural_asset(db,leaf),"hinged_leaf_geometry"))


def validate(db):
    if db.execute("PRAGMA foreign_key_check").fetchall():raise IntegrityError("Foreign-key violation")
    if db.execute("PRAGMA integrity_check").fetchone()[0]!="ok":raise IntegrityError("SQLite integrity failure")
    cycle=db.execute("""WITH RECURSIVE parents(a,b) AS (SELECT item_id,parent_id FROM item WHERE parent_id IS NOT NULL
      UNION SELECT parents.a,item.parent_id FROM parents JOIN item ON parents.b=item.item_id WHERE item.parent_id IS NOT NULL)
      SELECT a FROM parents WHERE a=b LIMIT 1""").fetchone()
    if cycle:raise IntegrityError("Item parent cycle")
    for table,parent,child in (("category","parent_id","category_id"),("asset_component","parent_asset_id","child_asset_id")):
        query=f"""WITH RECURSIVE edges(a,b) AS (SELECT {parent},{child} FROM {table} WHERE {parent} IS NOT NULL
          UNION SELECT edges.a,t.{child} FROM edges JOIN {table} t ON edges.b=t.{parent})
          SELECT a FROM edges WHERE a=b LIMIT 1"""
        if db.execute(query).fetchone():raise IntegrityError("Cycle in "+table)
    for iid,value in db.execute("SELECT item_id,dimensions_json FROM physical"):
        dimensions=strict_json(value)
        if dimensions is not None and (not isinstance(dimensions,list) or len(dimensions)!=3 or
            any(not isinstance(n,(int,float)) or isinstance(n,bool) or n<=0 for n in dimensions)):
            raise IntegrityError("Invalid metre dimensions: "+iid)
    for pid,name in db.execute("SELECT plant_id,source_path FROM botanical_reference"):
        if not pid or not name:raise IntegrityError("Invalid botanical reference")
    for aid,path in db.execute("SELECT asset_id,path FROM asset"):
        safe_relative(path)


def history(db):
    cursor=db.execute("SELECT change_id,item_id,base_revision,operation,field,after_json,'approved',reviewer,reviewed_at,reason FROM change_history ORDER BY rowid")
    return [dict(zip(CHANGE_COLUMNS,row)) for row in cursor]


def validate_changes(db,rows):
    prior={r["change_id"]:r for r in history(db)};seen=set();fields=set();accepted=[]
    for row in rows:
        if row.get("decision","") not in ("","draft","approved","rejected"):raise IntegrityError("Unknown decision")
        if row.get("decision")!="approved":continue
        if any(not row.get(k,"").strip() for k in CHANGE_COLUMNS):raise IntegrityError("Missing review metadata or explicit value")
        row={k:row[k] for k in CHANGE_COLUMNS};value=strict_json(row["proposed_json"]);row["proposed_json"]=canonical(value)
        cid,iid,field=row["change_id"],row["item_id"],row["field"]
        if cid in seen or (iid,field) in fields:raise IntegrityError("Duplicate/conflicting change")
        seen.add(cid);fields.add((iid,field))
        if cid in prior:
            if row!=prior[cid]:raise IntegrityError("Change ID reused with different content")
            continue
        current=db.execute("SELECT revision,definition_json FROM item WHERE item_id=?",(iid,)).fetchone()
        if not current or current[0]!=row["base_revision"]:raise IntegrityError("Unknown item or stale revision")
        if field not in EDITABLE:raise IntegrityError("Identity, economy, behavior, physical and asset changes require publication review")
        if row["operation"] not in ("set","clear"):raise IntegrityError("Use explicit set/clear")
        if row["operation"]=="clear":
            if value is not None or field=="name":raise IntegrityError("Clear requires null and cannot remove name")
        elif field=="tags":
            if not isinstance(value,list) or any(not isinstance(v,str) for v in value):raise IntegrityError("Tags must be strings")
        elif not isinstance(value,str) or (field=="name" and not value.strip()):raise IntegrityError("Text field requires valid text")
        datetime.strptime(row["reviewed_at"],"%Y-%m-%dT%H:%M:%SZ")
        accepted.append(row)
    return accepted


def apply_changes(db,rows):
    for row in rows:
        iid,field=row["item_id"],row["field"]
        item=strict_json(db.execute("SELECT definition_json FROM item WHERE item_id=?",(iid,)).fetchone()[0])
        before=item.get(field);value=strict_json(row["proposed_json"])
        item[field]=value
        db.execute("UPDATE item SET definition_json=?,revision=? WHERE item_id=?",(canonical(item),digest(canonical(item)),iid))
        if field in ("name","description"):
            db.execute("UPDATE item SET "+field+"=? WHERE item_id=?",(value or "",iid))
        db.execute("INSERT INTO change_history VALUES(?,?,?,?,?,?,?,?,?,?)",(row["change_id"],iid,row["base_revision"],row["operation"],field,
            canonical(before),canonical(value),row["reviewer"],row["reviewed_at"],row["reason"]))


def export(db,out,source_hash):
    items=[]
    for iid,raw,revision in db.execute("SELECT item_id,definition_json,revision FROM item ORDER BY item_id"):
        item=strict_json(raw);item["revision"]=revision
        item.pop("original_source_record",None)  # Preserved in SQLite and audit snapshot, not duplicated at startup.
        item["asset_bindings"]=[{"asset_id":aid,"role":role,"parameters":strict_json(params)} for aid,role,params in db.execute("SELECT asset_id,role,parameters_json FROM item_asset WHERE item_id=? ORDER BY asset_id,role",(iid,))]
        item["behavior_ids"]=[r[0] for r in db.execute("SELECT behavior_id FROM item_behavior WHERE item_id=? ORDER BY behavior_id",(iid,))]
        cursor=db.execute("SELECT * FROM listing WHERE item_id=?",(iid,))
        listing=cursor.fetchone()
        item["shop_listing"]=dict(zip([c[0] for c in cursor.description],listing)) if listing else None
        link=db.execute("SELECT plant_id,legacy_profile_id,status FROM botanical_link WHERE item_id=?",(iid,)).fetchone()
        item["botanical_link"]={"plant_id":link[0],"legacy_profile_id":link[1],"status":link[2]} if link else None
        items.append(item)
    assets=[{"asset_id":aid,"path":path,"fragment":fragment,"kind":kind,"exists":bool(exists),"metadata":strict_json(meta)}
        for aid,path,fragment,kind,exists,meta in db.execute("SELECT asset_id,path,fragment,kind,exists_on_disk,metadata_json FROM asset ORDER BY asset_id")]
    behaviors=[strict_json(r[0]) for r in db.execute("SELECT contract_json FROM behavior ORDER BY behavior_id")]
    content_hash=digest(canonical([items,assets,behaviors,source_hash]))
    bundle={"schema_version":VERSION,"source_hash":source_hash,"content_hash":content_hash,
            "items":items,"assets":assets,"behaviors":behaviors,
            "categories":[{"category_id":key,"label":label,"parent_id":parent} for key,label,parent in db.execute("SELECT * FROM category ORDER BY category_id")],
            "asset_components":[{"parent_asset_id":a,"child_asset_id":b,"role":role} for a,b,role in db.execute("SELECT * FROM asset_component ORDER BY parent_asset_id,child_asset_id,role")],
            "save_compatibility":{"strategy":"preserve_existing_ids_and_version_1_saves","migration_required":False,"retirement_policy":"retain_legacy_definition_until_explicit_migration"},
            "live_publication":"existing_items_only_metadata_adapter"}
    content_hash=digest(canonical({k:v for k,v in bundle.items() if k!="content_hash"}))
    bundle["content_hash"]=content_hash
    write_records_json(out/"catalog.v1.json",bundle)
    sheets=out/"sheets";sheets.mkdir()
    queries={
        "Master Item Catalog":"SELECT item_id,name,domain,category_id,collection,parent_id,implementation_status,art_status,owner_status,revision,source_path,description FROM item ORDER BY item_id",
        "Item Categories":"SELECT * FROM category ORDER BY category_id",
        "Shop and Economy":"SELECT * FROM listing ORDER BY item_id",
        "3D Asset Library":"SELECT asset_id,kind,path,fragment,status,license_json,metadata_json FROM asset ORDER BY asset_id",
        "Behavior Library":"SELECT * FROM behavior ORDER BY behavior_id",
        "Placement and Dimensions":"SELECT * FROM physical ORDER BY item_id",
        "Artwork Review":"SELECT a.item_id,a.asset_id,a.role,s.path,s.status,'not_reviewed' AS owner_status,a.parameters_json FROM item_asset a JOIN asset s USING(asset_id) WHERE a.role='shop_thumbnail' ORDER BY a.item_id",
        "Development Tracker":"SELECT item_id,name,implementation_status,art_status,owner_status,'bounds_extracted_not_visual_approval' AS test_status FROM item ORDER BY item_id",
        "Source and Change History":"SELECT * FROM source_file ORDER BY path",
        "Botanical Links":"SELECT * FROM botanical_link ORDER BY item_id",
        "Asset References":"SELECT * FROM asset_reference ORDER BY source_path,target_path",
        "Reusable Components":"SELECT * FROM asset_component ORDER BY parent_asset_id,child_asset_id",
        "Source Symbols":"SELECT * FROM source_symbol ORDER BY source_path,line",
        "Planned Requirements":"SELECT * FROM requirement ORDER BY source_path,line",
        "Audit Issues":"SELECT * FROM issue ORDER BY code,item_id,issue_id",
        "Approved Change History":"SELECT * FROM change_history ORDER BY rowid"}
    for name,query in queries.items():
        cursor=db.execute(query);write_csv(sheets/(name+".csv"),[c[0] for c in cursor.description],cursor)
    write_csv(sheets/"Owner Corrections.csv",CHANGE_COLUMNS,[])
    write_csv(sheets/"New Item Requests.csv",REQUEST_COLUMNS,[])
    report={"schema_version":VERSION,"counts":{table:db.execute("SELECT count(*) FROM "+table).fetchone()[0] for table in (
        "item","listing","asset","behavior","source_file","source_symbol","requirement","asset_component","botanical_reference")},
        "domains":dict(db.execute("SELECT domain,count(*) FROM item GROUP BY domain")),
        "issues":dict(db.execute("SELECT code,count(*) FROM issue GROUP BY code")),
        "owner_art_approval_performed":False,"new_gameplay_activated":False}
    write_json(out/"audit_report.json",report)
    write_json(out/"manifest.json",{"schema_version":VERSION,"source_hash":source_hash,"content_hash":content_hash,
        "source_files":dict(db.execute("SELECT path,sha256 FROM source_file ORDER BY path")),
        "review_history":history(db),"files":{p.relative_to(out).as_posix():digest(p.read_bytes()) for p in sorted(out.rglob("*"))
        if p.is_file() and not p.name.startswith("items.sqlite")}})
    return report


def write_records_json(path,data):
    """One stable entity per line gives reviewable diffs without giant pretty exports."""
    parts=[]
    for key,value in sorted(data.items()):
        encoded="[\n"+",\n".join("    "+canonical(row) for row in value)+"\n  ]" if isinstance(value,list) else canonical(value)
        parts.append("  "+json.dumps(key)+": "+encoded)
    Path(path).write_text("{\n"+",\n".join(parts)+"\n}\n",encoding="utf-8")


def build(out,repo=ROOT,snapshot_path=None,overlay=None):
    out,repo=Path(out).resolve(),Path(repo).resolve();project=repo/PROJECT.name
    if out.exists() or out.is_relative_to(project):raise IntegrityError("Output must be new and outside Godot")
    snapshot_bytes=Path(snapshot_path or HERE/"source_snapshot.json").read_bytes()
    snapshot=strict_json(snapshot_bytes.decode("utf-8"))
    out.parent.mkdir(parents=True,exist_ok=True);temp=Path(tempfile.mkdtemp(prefix=".item-",dir=out.parent));db=None
    try:
        db=sqlite3.connect(temp/"items.sqlite");db.executescript((HERE/"schema.sql").read_text())
        files=scan_repository(db,repo,project);ingest(db,project,snapshot)
        if overlay:
            changes=strict_json(Path(overlay).read_text())
            if changes.get("schema_version")!=VERSION:raise IntegrityError("Unsupported overlay schema")
            for row in changes["changes"]:apply_changes(db,validate_changes(db,[row]))
        validate(db)
        source_hash=digest(canonical({"files":{path:digest(raw) for path,raw in sorted(files.items())},"extraction":digest(snapshot_bytes)}))
        db.execute("INSERT INTO metadata VALUES('schema_version',?)",(VERSION,))
        report=export(db,temp,source_hash)
        for key,raw in files.items():
            path=checked_file(repo,key[5:]) if key.startswith("repo/") else checked_file(project,key)
            if path.read_bytes()!=raw:raise IntegrityError("Source changed during build: "+key)
        if Path(snapshot_path or HERE/"source_snapshot.json").read_bytes()!=snapshot_bytes:
            raise IntegrityError("Extraction changed during build")
        db.commit();db.close();db=None;temp.rename(out)
        return report
    finally:
        if db:db.close()
        if temp.exists():shutil.rmtree(temp)


def review(database,changes,out):
    out=Path(out)
    if out.exists():raise IntegrityError("Review output already exists")
    with sqlite3.connect(Path(database).resolve().as_uri()+"?mode=ro",uri=True) as db,Path(changes).open(newline="",encoding="utf-8-sig") as file:
        if db.execute("SELECT value FROM metadata WHERE key='schema_version'").fetchone()!=(VERSION,):raise IntegrityError("Unsupported database schema")
        reader=csv.DictReader(file)
        if reader.fieldnames!=CHANGE_COLUMNS:raise IntegrityError("Unexpected correction columns")
        accepted=validate_changes(db,list(reader))
        write_json(out,{"schema_version":VERSION,"changes":history(db)+accepted,"publication":"review_metadata_only"})
    return len(accepted)


def requests(database,source,out):
    """Receipt of proposals, never automatic creation of functional items or entitlements."""
    if Path(out).exists():raise IntegrityError("Request output exists")
    result=[];seen=set()
    with sqlite3.connect(Path(database).resolve().as_uri()+"?mode=ro",uri=True) as db,Path(source).open(newline="",encoding="utf-8-sig") as stream:
        reader=csv.DictReader(stream)
        if reader.fieldnames!=REQUEST_COLUMNS:raise IntegrityError("Unexpected new-request columns")
        for row in reader:
            if not row.get("proposed_name","").strip():continue
            if not row.get("request_id","").strip() or row["request_id"] in seen:raise IntegrityError("Missing or duplicate request ID")
            seen.add(row["request_id"])
            if row["decision"] not in ("draft","approved","rejected"):raise IntegrityError("Unknown request decision")
            if row["related_item_id"] and not db.execute("SELECT 1 FROM item WHERE item_id=?",(row["related_item_id"],)).fetchone():
                raise IntegrityError("Unknown related item")
            result.append(row)
    write_json(Path(out),{"schema_version":VERSION,"requests":result,"source_hash":digest(Path(source).read_bytes()),
        "status":"request_receipt_only_requires_design_asset_behavior_and_publication_review"})
    return len(result)


def main():
    parser=argparse.ArgumentParser(description=__doc__);sub=parser.add_subparsers(dest="command",required=True)
    command=sub.add_parser("build");command.add_argument("--out",type=Path,required=True);command.add_argument("--overlay",type=Path)
    command=sub.add_parser("review");command.add_argument("--database",type=Path,required=True);command.add_argument("--changes",type=Path,required=True);command.add_argument("--out",type=Path,required=True)
    command=sub.add_parser("requests");command.add_argument("--database",type=Path,required=True);command.add_argument("--source",type=Path,required=True);command.add_argument("--out",type=Path,required=True)
    args=parser.parse_args()
    try:
        if args.command=="build":print(canonical(build(args.out,overlay=args.overlay)))
        elif args.command=="review":print("Validated changes:",review(args.database,args.changes,args.out))
        else:print("Queued item requests:",requests(args.database,args.source,args.out))
    except (IntegrityError,ValueError,KeyError,TypeError,OSError,sqlite3.Error) as error:parser.exit(1,str(error)+"\n")


if __name__=="__main__":main()
