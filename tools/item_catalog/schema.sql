PRAGMA foreign_keys=ON;
CREATE TABLE metadata(key TEXT PRIMARY KEY,value TEXT NOT NULL);
CREATE TABLE source_file(path TEXT PRIMARY KEY,sha256 TEXT NOT NULL,bytes INTEGER NOT NULL,kind TEXT NOT NULL);
CREATE TABLE category(category_id TEXT PRIMARY KEY,label TEXT NOT NULL,parent_id TEXT REFERENCES category);
CREATE TABLE item(
 item_id TEXT PRIMARY KEY,name TEXT NOT NULL,domain TEXT NOT NULL,legacy_id TEXT,
 parent_id TEXT REFERENCES item DEFERRABLE INITIALLY DEFERRED,
 category_id TEXT NOT NULL REFERENCES category,collection TEXT,description TEXT NOT NULL,
 source_path TEXT NOT NULL REFERENCES source_file(path),revision TEXT NOT NULL,definition_json TEXT NOT NULL,
 implementation_status TEXT NOT NULL,art_status TEXT NOT NULL,owner_status TEXT NOT NULL
);
CREATE INDEX item_category ON item(category_id);
CREATE INDEX item_parent ON item(parent_id);
CREATE TABLE external_id(domain TEXT NOT NULL,legacy_id TEXT NOT NULL,item_id TEXT NOT NULL REFERENCES item,
 PRIMARY KEY(domain,legacy_id));
CREATE TABLE listing(listing_id TEXT PRIMARY KEY,item_id TEXT NOT NULL REFERENCES item,source_price REAL,effective_price REAL,
 currency TEXT,available INTEGER NOT NULL CHECK(available IN (0,1)),stack_limit INTEGER,
 sale_value REAL,unlock_json TEXT,purchase_restrictions_json TEXT,economy_notes TEXT NOT NULL,
 CHECK(effective_price IS NULL OR effective_price>=0));
CREATE TABLE physical(item_id TEXT PRIMARY KEY REFERENCES item,dimensions_json TEXT,pivot_json TEXT,
 footprint_json TEXT,placement_contract TEXT,mass_kg REAL,attachment_json TEXT,terrain_json TEXT,
 clearance_json TEXT,indoor_outdoor TEXT);
CREATE TABLE asset(asset_id TEXT PRIMARY KEY,path TEXT NOT NULL,fragment TEXT,kind TEXT NOT NULL,
 sha256 TEXT,exists_on_disk INTEGER NOT NULL CHECK(exists_on_disk IN (0,1)),license_json TEXT,
 status TEXT NOT NULL,metadata_json TEXT NOT NULL);
CREATE INDEX asset_path ON asset(path);
CREATE TABLE asset_reference(source_path TEXT NOT NULL REFERENCES source_file(path),target_path TEXT NOT NULL,
 kind TEXT NOT NULL,exists_on_disk INTEGER NOT NULL,PRIMARY KEY(source_path,target_path,kind));
CREATE TABLE item_asset(item_id TEXT NOT NULL REFERENCES item,asset_id TEXT NOT NULL REFERENCES asset,
 role TEXT NOT NULL,parameters_json TEXT NOT NULL,PRIMARY KEY(item_id,asset_id,role));
CREATE TABLE asset_component(parent_asset_id TEXT REFERENCES asset,child_asset_id TEXT REFERENCES asset,
 role TEXT NOT NULL,PRIMARY KEY(parent_asset_id,child_asset_id,role));
CREATE TABLE behavior(behavior_id TEXT PRIMARY KEY,status TEXT NOT NULL,script_path TEXT,
 contract_json TEXT NOT NULL,save_contract TEXT NOT NULL);
CREATE TABLE item_behavior(item_id TEXT REFERENCES item,behavior_id TEXT REFERENCES behavior,
 parameters_json TEXT NOT NULL,PRIMARY KEY(item_id,behavior_id));
CREATE TABLE botanical_reference(plant_id TEXT PRIMARY KEY,source_path TEXT NOT NULL,revision TEXT NOT NULL);
CREATE TABLE botanical_link(item_id TEXT PRIMARY KEY REFERENCES item,plant_id TEXT REFERENCES botanical_reference,
 legacy_profile_id TEXT,status TEXT NOT NULL,product_definition_id TEXT);
CREATE TABLE requirement(requirement_id TEXT PRIMARY KEY,source_path TEXT REFERENCES source_file(path),
 line INTEGER NOT NULL,text TEXT NOT NULL,status TEXT NOT NULL DEFAULT 'specification_not_runtime');
CREATE TABLE source_symbol(symbol_id TEXT PRIMARY KEY,source_path TEXT REFERENCES source_file(path),
 name TEXT NOT NULL,line INTEGER NOT NULL,kind TEXT NOT NULL,scope TEXT NOT NULL);
CREATE TABLE issue(issue_id TEXT PRIMARY KEY,code TEXT NOT NULL,item_id TEXT REFERENCES item,detail TEXT NOT NULL);
CREATE TABLE change_history(change_id TEXT PRIMARY KEY,item_id TEXT REFERENCES item,
 base_revision TEXT NOT NULL,operation TEXT NOT NULL,field TEXT NOT NULL,before_json TEXT NOT NULL,
 after_json TEXT NOT NULL,reviewer TEXT NOT NULL,reviewed_at TEXT NOT NULL,reason TEXT NOT NULL);
