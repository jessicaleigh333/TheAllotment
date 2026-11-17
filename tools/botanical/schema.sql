PRAGMA foreign_keys = ON;
CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE source_file(
 path TEXT PRIMARY KEY, sha256 TEXT NOT NULL, content BLOB NOT NULL,
 schema_version TEXT, role TEXT NOT NULL
);
CREATE TABLE plant(
 plant_id TEXT PRIMARY KEY, registry_json TEXT NOT NULL,
 identity_status TEXT NOT NULL DEFAULT 'unresolved', publication_status TEXT NOT NULL DEFAULT 'research_only'
 CHECK(publication_status IN ('research_only','approved'))
);
CREATE TABLE source_record(
 record_key TEXT PRIMARY KEY, plant_id TEXT NOT NULL REFERENCES plant,
 source_path TEXT NOT NULL REFERENCES source_file(path), pointer TEXT NOT NULL,
 raw_json TEXT NOT NULL, effective_json TEXT NOT NULL, revision TEXT NOT NULL,
 UNIQUE(source_path,pointer)
);
CREATE INDEX source_record_plant ON source_record(plant_id);
CREATE TABLE field_value(
 record_key TEXT NOT NULL REFERENCES source_record, pointer TEXT NOT NULL,
 value_json TEXT NOT NULL, value_type TEXT NOT NULL,
 PRIMARY KEY(record_key,pointer)
);
CREATE TABLE evidence(
 evidence_id TEXT PRIMARY KEY, record_key TEXT NOT NULL REFERENCES source_record,
 pointer TEXT NOT NULL, url TEXT NOT NULL, context_json TEXT NOT NULL,
 scope TEXT NOT NULL DEFAULT 'record_lead_not_field_verified', review_status TEXT NOT NULL DEFAULT 'unverified'
);
CREATE INDEX evidence_record ON evidence(record_key);
CREATE TABLE taxon_node(
 node_id TEXT PRIMARY KEY, label TEXT NOT NULL, rank TEXT NOT NULL,
 source_path TEXT NOT NULL REFERENCES source_file(path), pointer TEXT NOT NULL,
 status TEXT NOT NULL DEFAULT 'source_reported_unverified'
);
CREATE TABLE taxon_edge(
 parent_id TEXT NOT NULL REFERENCES taxon_node, child_id TEXT NOT NULL REFERENCES taxon_node,
 source_path TEXT NOT NULL REFERENCES source_file(path), pointer TEXT NOT NULL,
 status TEXT NOT NULL DEFAULT 'source_reported_unverified',
 PRIMARY KEY(parent_id,child_id), CHECK(parent_id != child_id)
);
CREATE TABLE record_relationship(
 from_id TEXT NOT NULL REFERENCES plant, to_id TEXT NOT NULL REFERENCES plant,
 relation TEXT NOT NULL, record_key TEXT NOT NULL REFERENCES source_record,
 pointer TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'source_reported_unverified',
 PRIMARY KEY(from_id,to_id,relation,record_key,pointer)
);
CREATE TABLE identity_assertion(
 assertion_id TEXT PRIMARY KEY, plant_id TEXT NOT NULL REFERENCES plant,
 record_key TEXT NOT NULL REFERENCES source_record, pointer TEXT NOT NULL,
 relation TEXT NOT NULL, label TEXT NOT NULL, candidate_node_id TEXT REFERENCES taxon_node,
 status TEXT NOT NULL DEFAULT 'source_reported_unverified'
);
CREATE INDEX identity_subject ON identity_assertion(plant_id,relation);
CREATE TABLE profile_definition(
 profile_id TEXT PRIMARY KEY, plant_id TEXT NOT NULL REFERENCES plant,
 profile_version TEXT NOT NULL, definition_json TEXT NOT NULL,
 approval_status TEXT NOT NULL DEFAULT 'not_reviewed'
);
CREATE TABLE model_component(
 component_id TEXT PRIMARY KEY, kind TEXT NOT NULL, asset_path TEXT,
 content_hash TEXT, license TEXT, source_path TEXT,
 status TEXT NOT NULL DEFAULT 'not_reviewed'
);
CREATE TABLE model_component_link(
 binding_id TEXT NOT NULL REFERENCES asset_binding,
 component_id TEXT NOT NULL REFERENCES model_component, override_json TEXT,
 PRIMARY KEY(binding_id,component_id)
);
CREATE TABLE duplicate_candidate(
 candidate_id TEXT PRIMARY KEY, left_id TEXT NOT NULL REFERENCES plant,
 right_id TEXT NOT NULL REFERENCES plant, reason TEXT NOT NULL, scientific_scope TEXT,
 disposition TEXT NOT NULL DEFAULT 'needs_identity_review', CHECK(left_id < right_id)
);
CREATE TABLE asset_binding(
 binding_id TEXT PRIMARY KEY, plant_id TEXT NOT NULL REFERENCES plant,
 role TEXT NOT NULL, stage_id TEXT, asset_path TEXT, model_family_id TEXT,
 base_model_id TEXT, dimensions_json TEXT, materials_json TEXT, animations_json TEXT,
 source_pointer TEXT NOT NULL, status TEXT NOT NULL, verified_exists INTEGER NOT NULL CHECK(verified_exists IN (0,1))
);
CREATE TABLE gameplay_binding(
 legacy_id TEXT PRIMARY KEY, plant_id TEXT REFERENCES plant, status TEXT NOT NULL,
 profile_source TEXT NOT NULL, profile_json TEXT NOT NULL
);
CREATE TABLE review_change(
 change_id TEXT PRIMARY KEY, record_key TEXT NOT NULL REFERENCES source_record,
 pointer TEXT NOT NULL, operation TEXT NOT NULL CHECK(operation IN ('set','clear')),
 before_json TEXT NOT NULL, after_json TEXT NOT NULL, base_revision TEXT NOT NULL,
 reviewer TEXT NOT NULL, reviewed_at TEXT NOT NULL, reason TEXT NOT NULL, evidence_url TEXT NOT NULL
);
CREATE TABLE issue(
 issue_id TEXT PRIMARY KEY, severity TEXT NOT NULL, code TEXT NOT NULL,
 plant_id TEXT REFERENCES plant, detail TEXT NOT NULL
);
