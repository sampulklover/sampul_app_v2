-- Marketing staff role + RLS updates
-- Run in Supabase SQL Editor after backup.
-- 1) Adds enum value `marketing` to `user_roles`
-- 2) Lets admin OR marketing manage AI + learning content (same as previous admin-only)
-- 3) Secures `roles` table: users read own row; admins read/write all; marketing cannot assign roles
-- 4) Lets admins read all profiles (for in-app team list) — ORs with any existing SELECT policies

-- ---------------------------------------------------------------------------
-- Enum: marketing
-- ---------------------------------------------------------------------------
DO $enum$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'user_roles'
      AND e.enumlabel = 'marketing'
  ) THEN
    ALTER TYPE user_roles ADD VALUE 'marketing';
  END IF;
END
$enum$;

-- ---------------------------------------------------------------------------
-- RLS-safe role checks (avoids infinite recursion on table `roles`)
-- Policies on `roles` must NOT subquery `roles`. Other tables subquerying
-- `roles` can still recurse when those policies OR together awkwardly — so we
-- use these helpers everywhere.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.auth_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.roles r
    WHERE r.uuid = auth.uid()
      AND r.role = 'admin'::user_roles
  );
$$;

CREATE OR REPLACE FUNCTION public.auth_is_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.roles r
    WHERE r.uuid = auth.uid()
      AND r.role IN ('admin'::user_roles, 'marketing'::user_roles)
  );
$$;

GRANT EXECUTE ON FUNCTION public.auth_is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.auth_is_staff() TO authenticated;

-- ---------------------------------------------------------------------------
-- ai_chat_settings, ai_chat_qna, learning_resources: admin OR marketing
-- Wrapped in DO blocks so DROP + CREATE run in one shot. Drops every policy
-- except the public read policy (by name from pg_policies) so duplicates /
-- re-runs always work.
-- ---------------------------------------------------------------------------
DO $ai_settings$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ai_chat_settings'
      AND policyname IS DISTINCT FROM 'Anyone can read active AI chat settings'
  LOOP
    EXECUTE format('DROP POLICY %I ON public.ai_chat_settings', r.policyname);
  END LOOP;

  EXECUTE $s1$
    CREATE POLICY "Staff can read all AI chat settings"
    ON public.ai_chat_settings
    FOR SELECT
    USING (public.auth_is_staff());
  $s1$;
  EXECUTE $s2$
    CREATE POLICY "Staff can insert AI chat settings"
    ON public.ai_chat_settings
    FOR INSERT
    WITH CHECK (public.auth_is_staff());
  $s2$;
  EXECUTE $s3$
    CREATE POLICY "Staff can update AI chat settings"
    ON public.ai_chat_settings
    FOR UPDATE
    USING (public.auth_is_staff())
    WITH CHECK (public.auth_is_staff());
  $s3$;
  EXECUTE $s4$
    CREATE POLICY "Staff can delete AI chat settings"
    ON public.ai_chat_settings
    FOR DELETE
    USING (public.auth_is_staff());
  $s4$;
END
$ai_settings$;

DO $ai_qna$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ai_chat_qna'
      AND policyname IS DISTINCT FROM 'Anyone can read active AI chat QnA'
  LOOP
    EXECUTE format('DROP POLICY %I ON public.ai_chat_qna', r.policyname);
  END LOOP;

  EXECUTE $q1$
    CREATE POLICY "Staff can manage AI chat QnA"
    ON public.ai_chat_qna
    FOR ALL
    USING (public.auth_is_staff())
    WITH CHECK (public.auth_is_staff());
  $q1$;
END
$ai_qna$;

DO $learning$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'learning_resources'
      AND policyname IS DISTINCT FROM 'Public read published learning resources'
  LOOP
    EXECUTE format('DROP POLICY %I ON public.learning_resources', r.policyname);
  END LOOP;

  EXECUTE $lr1$
    CREATE POLICY "Staff manage learning resources"
    ON public.learning_resources
    FOR ALL
    USING (public.auth_is_staff())
    WITH CHECK (public.auth_is_staff());
  $lr1$;
END
$learning$;

-- ---------------------------------------------------------------------------
-- roles table RLS (in-app team management)
-- ---------------------------------------------------------------------------
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

-- Remove legacy / duplicate policies that overlap or recurse (from dashboard experiments)
DROP POLICY IF EXISTS "admin_all_access" ON public.roles;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.roles;

DROP POLICY IF EXISTS "Users read own role" ON public.roles;
DROP POLICY IF EXISTS "Admins read all roles" ON public.roles;
DROP POLICY IF EXISTS "Admins insert roles" ON public.roles;
DROP POLICY IF EXISTS "Admins update roles" ON public.roles;
DROP POLICY IF EXISTS "Admins delete roles" ON public.roles;

CREATE POLICY "Users read own role"
ON public.roles
FOR SELECT
USING (uuid = auth.uid());

CREATE POLICY "Admins read all roles"
ON public.roles
FOR SELECT
USING (public.auth_is_admin());

CREATE POLICY "Admins insert roles"
ON public.roles
FOR INSERT
WITH CHECK (public.auth_is_admin());

CREATE POLICY "Admins update roles"
ON public.roles
FOR UPDATE
USING (public.auth_is_admin())
WITH CHECK (public.auth_is_admin());

CREATE POLICY "Admins delete roles"
ON public.roles
FOR DELETE
USING (public.auth_is_admin());

-- ---------------------------------------------------------------------------
-- profiles: admins list users for team access screen
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins read profiles for team access" ON public.profiles;

CREATE POLICY "Admins read profiles for team access"
ON public.profiles
FOR SELECT
USING (public.auth_is_admin());
