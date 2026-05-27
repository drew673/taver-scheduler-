-- ============================================================
-- TAVER SCHEDULER — AUTH SETUP
-- Run this in Supabase SQL Editor
-- ============================================================

-- User profiles table — links Supabase auth to staff
CREATE TABLE IF NOT EXISTS user_profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT NOT NULL,
  name        TEXT DEFAULT '',
  role        TEXT DEFAULT 'staff', -- 'admin' or 'staff'
  staff_id    TEXT DEFAULT '',      -- links to staff directory entry
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
DROP POLICY IF EXISTS "users_read_own_profile" ON user_profiles;
CREATE POLICY "users_read_own_profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
DROP POLICY IF EXISTS "users_update_own_profile" ON user_profiles;
CREATE POLICY "users_update_own_profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

-- Admins can read all profiles
DROP POLICY IF EXISTS "admins_read_all_profiles" ON user_profiles;
CREATE POLICY "admins_read_all_profiles" ON user_profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid() AND up.role = 'admin'
    )
  );

-- Allow insert during signup (handled by trigger)
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

-- Make existing jobs/shifts readable by authenticated users
-- Admins get full access, staff get read-only on their relevant data

-- Jobs: admins full access, staff read
DROP POLICY IF EXISTS "auth_read_jobs" ON jobs;
DROP POLICY IF EXISTS "auth_write_jobs" ON jobs;
DROP POLICY IF EXISTS "anon_all_jobs" ON jobs;

CREATE POLICY "auth_read_jobs" ON jobs
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "auth_write_jobs" ON jobs
  FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Keep anon access for docket/timesheet links
CREATE POLICY "anon_read_jobs" ON jobs
  FOR SELECT TO anon USING (true);

SELECT 'Auth setup complete' AS status;
