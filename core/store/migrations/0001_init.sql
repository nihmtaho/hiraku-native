CREATE TABLE folders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  position INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE note_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  is_system INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE note_type_fields (
  id TEXT PRIMARY KEY,
  note_type_id TEXT NOT NULL REFERENCES note_types(id),
  ord INTEGER NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  input_kind TEXT NOT NULL,
  required INTEGER NOT NULL DEFAULT 0,
  searchable INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE card_templates (
  id TEXT PRIMARY KEY,
  note_type_id TEXT NOT NULL REFERENCES note_types(id),
  front_fields TEXT NOT NULL,
  back_fields TEXT NOT NULL,
  typing_answer_field_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE decks (
  id TEXT PRIMARY KEY,
  folder_id TEXT NOT NULL REFERENCES folders(id),
  note_type_id TEXT NOT NULL REFERENCES note_types(id),
  name TEXT NOT NULL,
  description TEXT,
  position INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX decks_folder ON decks(folder_id, position);

CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES decks(id),
  note_type_id TEXT NOT NULL REFERENCES note_types(id),
  fields TEXT NOT NULL,
  sort_field TEXT NOT NULL,
  search_text TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX notes_deck ON notes(deck_id, sort_field);
CREATE INDEX notes_search ON notes(search_text);

CREATE TABLE cards (
  id TEXT PRIMARY KEY,
  note_id TEXT NOT NULL REFERENCES notes(id),
  template_id TEXT NOT NULL REFERENCES card_templates(id),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  UNIQUE (note_id, template_id)
);

CREATE TABLE card_states (
  card_id TEXT PRIMARY KEY REFERENCES cards(id),
  state INTEGER NOT NULL,
  due INTEGER NOT NULL,
  stability REAL NOT NULL,
  difficulty REAL NOT NULL,
  elapsed_days INTEGER NOT NULL,
  scheduled_days INTEGER NOT NULL,
  learning_steps INTEGER NOT NULL,
  reps INTEGER NOT NULL,
  lapses INTEGER NOT NULL,
  last_review INTEGER,
  suspended INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX card_states_due ON card_states(due);
CREATE INDEX card_states_state ON card_states(state);

CREATE TABLE review_logs (
  id TEXT PRIMARY KEY,
  card_id TEXT NOT NULL REFERENCES cards(id),
  rating INTEGER NOT NULL,
  reviewed_at INTEGER NOT NULL,
  mode TEXT NOT NULL,
  elapsed_ms INTEGER NOT NULL,
  prev_state INTEGER NOT NULL,
  prev_due INTEGER NOT NULL,
  prev_stability REAL NOT NULL,
  prev_difficulty REAL NOT NULL,
  prev_learning_steps INTEGER NOT NULL,
  prev_reps INTEGER NOT NULL,
  prev_lapses INTEGER NOT NULL,
  prev_last_review INTEGER,
  created_at INTEGER NOT NULL
);
CREATE INDEX review_logs_card ON review_logs(card_id, reviewed_at);

CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

INSERT INTO note_types (id, name, is_system, created_at, updated_at) VALUES
  ('nt-system-ja', 'Từ vựng Nhật', 1, 0, 0);

INSERT INTO note_type_fields (id, note_type_id, ord, name, role, input_kind, required, searchable, created_at, updated_at) VALUES
  ('nf-term', 'nt-system-ja', 1, 'Từ', 'term', 'text', 1, 1, 0, 0),
  ('nf-reading', 'nt-system-ja', 2, 'Cách đọc', 'reading', 'kana', 0, 1, 0, 0),
  ('nf-meaning', 'nt-system-ja', 3, 'Nghĩa', 'meaning', 'text', 1, 1, 0, 0),
  ('nf-example', 'nt-system-ja', 4, 'Câu ví dụ', 'example', 'text', 0, 1, 0, 0);

INSERT INTO card_templates (id, note_type_id, front_fields, back_fields, typing_answer_field_id, created_at, updated_at) VALUES
  ('ct-system-ja', 'nt-system-ja', '["nf-term"]', '["nf-reading","nf-meaning","nf-example"]', 'nf-reading', 0, 0);
