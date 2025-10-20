-- Verificar estado de RLS en todas las tablas
-- Identifica tablas con políticas pero sin RLS habilitado

WITH table_policies AS (
    SELECT
        schemaname,
        tablename,
        COUNT(*) as policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY schemaname, tablename
),
table_rls_status AS (
    SELECT
        schemaname,
        tablename,
        rowsecurity as rls_enabled
    FROM pg_tables
    WHERE schemaname = 'public'
)
SELECT
    t.tablename,
    t.rls_enabled,
    COALESCE(p.policy_count, 0) as total_policies,
    CASE
        WHEN t.rls_enabled = false AND COALESCE(p.policy_count, 0) > 0
        THEN '❌ ERROR: Políticas sin RLS habilitado'
        WHEN t.rls_enabled = true AND COALESCE(p.policy_count, 0) = 0
        THEN '⚠️  WARNING: RLS habilitado sin políticas'
        WHEN t.rls_enabled = true AND COALESCE(p.policy_count, 0) > 0
        THEN '✅ OK'
        ELSE '⚪ Sin RLS ni políticas'
    END as status
FROM table_rls_status t
LEFT JOIN table_policies p ON t.tablename = p.tablename
ORDER BY
    CASE
        WHEN t.rls_enabled = false AND COALESCE(p.policy_count, 0) > 0 THEN 1
        WHEN t.rls_enabled = true AND COALESCE(p.policy_count, 0) = 0 THEN 2
        WHEN t.rls_enabled = true AND COALESCE(p.policy_count, 0) > 0 THEN 3
        ELSE 4
    END,
    t.tablename;
