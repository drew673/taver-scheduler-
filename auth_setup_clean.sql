-- ============================================================
-- TAVER SCHEDULER — AUTH SETUP (clean version, no conflicts)
-- Run this in Supabase SQL Editor
-- ============================================================

-- User profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT NOT NULL,
  name        TEXT DEFAULT '',
  role        TEXT DEFAULT 'staff',
  staff_id    TEXT DEFAULT '',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_read_own_profile" ON user_profiles;
CREATE POLICY "users_read_own_profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "users_update_own_profile" ON user_profiles;
CREATE POLICY "users_update_own_profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "admins_read_all_profiles" ON user_profiles;
CREATE POLICY "admins_read_all_profiles" ON user_profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_profiles up WHERE up.id = auth.uid() AND up.role = 'admin')
  );

DROP POLICY IF EXISTS "allow_insert_own_profile" ON user_profiles;
CREATE POLICY "allow_insert_own_profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, role)
  VALUES (
    NEW.id,
    NEW.email,
    CASE WHEN NEW.email = 'drew@tavergroup.com' THEN 'admin' ELSE 'staff' END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Jobs policies for authenticated users (drop existing anon ones first)
DROP POLICY IF EXISTS "auth_read_jobs" ON jobs;
DROP POLICY IF EXISTS "auth_write_jobs" ON jobs;
DROP POLICY IF EXISTS "anon_read_jobs" ON jobs;
DROP POLICY IF EXISTS "anon_all_jobs" ON jobs;

CREATE POLICY "anon_all_jobs" ON jobs FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "auth_read_jobs" ON jobs
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "auth_write_jobs" ON jobs
  FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Same for shifts and personnel
DROP POLICY IF EXISTS "auth_read_shifts" ON shifts;
DROP POLICY IF EXISTS "auth_read_personnel" ON personnel;

CREATE POLICY "auth_read_shifts" ON shifts
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "auth_read_personnel" ON personnel
  FOR SELECT TO authenticated USING (true);

-- ============================================================
-- SHIFT CONFIRMATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS shift_confirmations (
  id          TEXT PRIMARY KEY,
  shift_id    TEXT NOT NULL,
  job_id      TEXT NOT NULL,
  staff_name  TEXT NOT NULL,
  status      TEXT DEFAULT 'pending', -- 'pending', 'confirmed', 'declined'
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE shift_confirmations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_all_confirmations" ON shift_confirmations;
CREATE POLICY "anon_all_confirmations" ON shift_confirmations
  FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "auth_all_confirmations" ON shift_confirmations;
CREATE POLICY "auth_all_confirmations" ON shift_confirmations
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

SELECT 'Shift confirmations table created' AS status;
