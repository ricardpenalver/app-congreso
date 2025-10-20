-- Fix Error 1: Enable RLS on organizations table
-- Error: Policy Exists RLS Disabled for public.organizations

-- Habilitar RLS en la tabla organizations
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Verificar que RLS está habilitado
SELECT
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'organizations';
