-- Fix: "infinite recursion detected in policy for relation roles"
-- Run in Supabase SQL Editor.
-- Cause: policies ON `roles` that contain `EXISTS (SELECT ... FROM roles ...)` re-trigger RLS.
-- Fix: use SECURITY DEFINER helpers with row_security off for those checks.

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

-- Remove overlapping / experimental policies (from dashboard)
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
