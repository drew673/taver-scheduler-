-- ============================================================
-- TAVER GROUP SCHEDULER — Supabase Database Setup v2
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- If you already ran v1, this is safe to run again (IF NOT EXISTS)
-- ============================================================

-- Jobs table
CREATE TABLE IF NOT EXISTS jobs (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  week         INTEGER NOT NULL,
  po           TEXT DEFAULT '',
  site_address TEXT DEFAULT '',
  map_link     TEXT DEFAULT '',
  client       TEXT DEFAULT '',
  notes        TEXT DEFAULT '',
  client_contact TEXT DEFAULT '',
  client_phone   TEXT DEFAULT '',
  color        TEXT DEFAULT '#2d7a4a',
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Shifts table
CREATE TABLE IF NOT EXISTS shifts (
  id         TEXT PRIMARY KEY,
  job_id     TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  date       TEXT NOT NULL,
  day_label  TEXT DEFAULT '',
  start_time TEXT DEFAULT '',
  end_time   TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Personnel table
CREATE TABLE IF NOT EXISTS personnel (
  id          TEXT PRIMARY KEY,
  shift_id    TEXT NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
  job_id      TEXT NOT NULL,
  role        TEXT DEFAULT '',
  name        TEXT DEFAULT '',
  phone       TEXT DEFAULT '',
  company     TEXT DEFAULT '',
  riw         BOOLEAN DEFAULT FALSE,
  riw_number  TEXT DEFAULT '',
  shift_start TEXT DEFAULT '',
  shift_end   TEXT DEFAULT ''
);

-- Staff directory table
CREATE TABLE IF NOT EXISTS staff (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  phone      TEXT DEFAULT '',
  role       TEXT DEFAULT '',
  company    TEXT DEFAULT '',
  riw        BOOLEAN DEFAULT FALSE,
  riw_number TEXT DEFAULT '',
  notes      TEXT DEFAULT '',
  added_from TEXT DEFAULT 'manual',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Enable Row Level Security ──────────────────────────────────────────
ALTER TABLE jobs      ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts    ENABLE ROW LEVEL SECURITY;
ALTER TABLE personnel ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff     ENABLE ROW LEVEL SECURITY;

-- ── Drop old policies if they exist and recreate ───────────────────────
DROP POLICY IF EXISTS "Allow all on jobs"      ON jobs;
DROP POLICY IF EXISTS "Allow all on shifts"    ON shifts;
DROP POLICY IF EXISTS "Allow all on personnel" ON personnel;
DROP POLICY IF EXISTS "Allow all on staff"     ON staff;

-- Full access with anon key (shared team tool)
CREATE POLICY "anon_all_jobs"      ON jobs      FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_shifts"    ON shifts    FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_personnel" ON personnel FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_staff"     ON staff     FOR ALL TO anon USING (true) WITH CHECK (true);

-- ── Indexes ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_shifts_job_id   ON shifts(job_id);
CREATE INDEX IF NOT EXISTS idx_pax_shift_id    ON personnel(shift_id);
CREATE INDEX IF NOT EXISTS idx_pax_job_id      ON personnel(job_id);
CREATE INDEX IF NOT EXISTS idx_jobs_week       ON jobs(week);

-- ── Auto-update timestamps ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS jobs_updated_at  ON jobs;
DROP TRIGGER IF EXISTS staff_updated_at ON staff;

CREATE TRIGGER jobs_updated_at  BEFORE UPDATE ON jobs  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER staff_updated_at BEFORE UPDATE ON staff FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Verify everything is set up ────────────────────────────────────────
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as columns
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('jobs','shifts','personnel','staff')
ORDER BY table_name;

-- ============================================================
-- JOB NUMBERS & JOB LOG — run this block separately
-- ============================================================

-- Add job_number and created_at columns to jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS job_number TEXT DEFAULT '';
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Job counter table (single row, atomically incremented)
CREATE TABLE IF NOT EXISTS job_counter (
  id      INTEGER PRIMARY KEY DEFAULT 1,
  current INTEGER NOT NULL DEFAULT 0,
  CHECK (id = 1)  -- ensures only one row ever exists
);

-- Insert the initial counter row if it doesn't exist
INSERT INTO job_counter (id, current) VALUES (1, 0) ON CONFLICT (id) DO NOTHING;

-- Enable RLS
ALTER TABLE job_counter ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_counter" ON job_counter;
CREATE POLICY "anon_all_counter" ON job_counter FOR ALL TO anon USING (true) WITH CHECK (true);

-- Function to atomically increment the counter and return next number
CREATE OR REPLACE FUNCTION increment_job_counter()
RETURNS json AS $$
DECLARE
  next_num INTEGER;
BEGIN
  UPDATE job_counter SET current = current + 1 WHERE id = 1 RETURNING current INTO next_num;
  RETURN json_build_object('next_number', next_num);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify
SELECT 'Job counter setup complete ✓' AS status;

-- Add status column to jobs
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'confirmed';
