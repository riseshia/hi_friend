CREATE TABLE IF NOT EXISTS receivers (
  id INTEGER PRIMARY KEY,
  fqname TEXT NOT NULL,
  is_singleton BOOLEAN NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('Class', 'Module')),
  file_path TEXT NOT NULL,
  line INTEGER,
  file_hash TEXT,
  UNIQUE(fqname, file_path)
);

CREATE INDEX idx_receivers_fqname ON receivers(fqname);
CREATE INDEX idx_receivers_file_path ON receivers(file_path);

DROP VIEW IF EXISTS view_receivers;
CREATE VIEW view_receivers AS
SELECT
  distinct fqname
FROM receivers;

CREATE TABLE IF NOT EXISTS methods (
  id INTEGER PRIMARY KEY,
  receiver_id INTEGER NOT NULL,
  visibility TEXT NOT NULL CHECK (visibility IN ('public', 'protected', 'private')),
  name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  line INTEGER,
  UNIQUE(receiver_id, name, file_path)
);

CREATE INDEX idx_methods_receiver_id ON methods(receiver_id);
CREATE INDEX idx_methods_name ON methods(name);

CREATE TABLE IF NOT EXISTS included_modules (
  id INTEGER PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('include', 'inherit')),
  target_fqname TEXT NOT NULL,
  passed_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  line INTEGER
);

CREATE INDEX idx_included_modules_parent ON included_modules(passed_name);
CREATE INDEX idx_included_modules_target_fqname ON included_modules(target_fqname);

CREATE TABLE IF NOT EXISTS receiver_responds (
  receiver_fqname TEXT NOT NULL,
  method_name TEXT NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('self', 'mixin', 'inherit')),
  PRIMARY KEY (receiver_fqname, method_name)
);

CREATE INDEX idx_method_responses_method ON receiver_responds(method_name);
