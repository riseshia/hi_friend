CREATE TABLE IF NOT EXISTS receivers (
  id INTEGER PRIMARY KEY,
  full_qualified_name TEXT NOT NULL,
  is_singleton BOOLEAN NOT NULL,
  file_path TEXT NOT NULL,
  line INTEGER,
  file_hash TEXT,
  UNIQUE(full_qualified_name, file_path)
);

CREATE INDEX idx_receivers_full_qualified_name ON receivers(full_qualified_name);
CREATE INDEX idx_receivers_file_path ON receivers(file_path);

DROP VIEW IF EXISTS view_receivers;
CREATE VIEW view_receivers AS
SELECT
  full_path,
  MAX(is_singleton) AS is_singleton
FROM receivers
GROUP BY full_path;

CREATE TABLE IF NOT EXISTS methods (
  id INTEGER PRIMARY KEY,
  receiver_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  line INTEGER,
  is_from_mixin BOOLEAN DEFAULT 0,
  UNIQUE(receiver_id, name, file_path)
);

CREATE INDEX idx_methods_receiver_id ON methods(receiver_id);
CREATE INDEX idx_methods_name ON methods(name);

CREATE TABLE IF NOT EXISTS inheritances (
  id INTEGER PRIMARY KEY,
  child_receiver_full_qualified_name TEXT NOT NULL,
  parent_receiver_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  line INTEGER
);

CREATE INDEX idx_inheritances_parent ON inheritances(parent_receiver_name);
CREATE INDEX idx_inheritances_child ON inheritances(child_receiver_full_qualified_name);

CREATE TABLE IF NOT EXISTS mixins (
  id INTEGER PRIMARY KEY,
  target_receiver_full_path TEXT NOT NULL,
  mixin_receiver_full_path TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('include', 'prepend')),
  file_path TEXT NOT NULL,
  line INTEGER
);

CREATE INDEX idx_mixins_mixin ON mixins(mixin_receiver_full_path);
CREATE INDEX idx_mixins_target ON mixins(target_receiver_full_path);

CREATE TABLE IF NOT EXISTS method_responses (
  receiver_full_path TEXT NOT NULL,
  method_name TEXT NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('self', 'mixin', 'inherit')),
  PRIMARY KEY (receiver_full_path, method_name)
);

CREATE INDEX idx_method_responses_method ON method_responses(method_name);
