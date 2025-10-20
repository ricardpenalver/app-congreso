-- Script de Verificación de Seguridad
-- Ejecutar DESPUÉS de aplicar security_fixes.sql
-- Fecha: 2025-10-19

-- ================================================================
-- VERIFICACIÓN 1: Tablas con RLS habilitado
-- ================================================================
SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- ================================================================
-- VERIFICACIÓN 2: Conteo de políticas por tabla
-- ================================================================
SELECT
    tablename,
    COUNT(*) as total_policies,
    COUNT(*) FILTER (WHERE cmd = 'SELECT') as select_policies,
    COUNT(*) FILTER (WHERE cmd = 'INSERT') as insert_policies,
    COUNT(*) FILTER (WHERE cmd = 'UPDATE') as update_policies,
    COUNT(*) FILTER (WHERE cmd = 'DELETE') as delete_policies,
    COUNT(*) FILTER (WHERE cmd = 'ALL') as all_policies
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- ================================================================
-- VERIFICACIÓN 3: Tablas CON RLS pero SIN políticas (PROBLEMAS)
-- ================================================================
SELECT
    t.tablename,
    'ERROR: RLS habilitado pero sin políticas' as status
FROM pg_tables t
LEFT JOIN pg_policies p ON t.tablename = p.tablename AND t.schemaname = p.schemaname
WHERE t.schemaname = 'public'
AND t.rowsecurity = true
GROUP BY t.tablename
HAVING COUNT(p.policyname) = 0
ORDER BY t.tablename;

-- ================================================================
-- VERIFICACIÓN 4: Detalle de políticas críticas
-- ================================================================
-- Verificar que las tablas críticas tienen políticas
SELECT
    tablename,
    policyname,
    cmd as operation,
    CASE
        WHEN roles = '{public}' THEN 'Acceso público'
        WHEN roles = '{authenticated}' THEN 'Solo autenticados'
        ELSE roles::text
    END as who_can_access
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN (
    'attendees',
    'votes',
    'voting_topics',
    'ideas',
    'organizations',
    'resources',
    'idea_tags',
    'notification_templates'
)
ORDER BY tablename, cmd;

-- ================================================================
-- VERIFICACIÓN 5: Triggers de seguridad
-- ================================================================
SELECT
    trigger_name,
    event_object_table as table_name,
    event_manipulation as event_type,
    action_timing as timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name IN (
    'trigger_validate_unique_vote',
    'trigger_validate_vote_structure'
)
ORDER BY event_object_table;

-- ================================================================
-- VERIFICACIÓN 6: Funciones de validación
-- ================================================================
SELECT
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'validate_unique_vote',
    'validate_vote_structure'
)
ORDER BY routine_name;

-- ================================================================
-- RESUMEN EJECUTIVO
-- ================================================================
DO $$
DECLARE
    total_tables INTEGER;
    tables_with_rls INTEGER;
    tables_without_policies INTEGER;
    total_policies INTEGER;
BEGIN
    -- Contar tablas totales
    SELECT COUNT(*) INTO total_tables
    FROM pg_tables
    WHERE schemaname = 'public';

    -- Contar tablas con RLS
    SELECT COUNT(*) INTO tables_with_rls
    FROM pg_tables
    WHERE schemaname = 'public'
    AND rowsecurity = true;

    -- Contar tablas con RLS pero sin políticas
    SELECT COUNT(*) INTO tables_without_policies
    FROM (
        SELECT t.tablename
        FROM pg_tables t
        LEFT JOIN pg_policies p ON t.tablename = p.tablename AND t.schemaname = p.schemaname
        WHERE t.schemaname = 'public'
        AND t.rowsecurity = true
        GROUP BY t.tablename
        HAVING COUNT(p.policyname) = 0
    ) AS subq;

    -- Contar políticas totales
    SELECT COUNT(*) INTO total_policies
    FROM pg_policies
    WHERE schemaname = 'public';

    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         RESUMEN DE SEGURIDAD - SUPABASE RLS              ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Tablas totales:                    % ', LPAD(total_tables::text, 19, ' ');
    RAISE NOTICE '║ Tablas con RLS habilitado:         % ', LPAD(tables_with_rls::text, 19, ' ');
    RAISE NOTICE '║ Políticas totales configuradas:    % ', LPAD(total_policies::text, 19, ' ');
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    IF tables_without_policies > 0 THEN
        RAISE NOTICE '║ ⚠️  ADVERTENCIA: % tablas con RLS pero sin políticas', LPAD(tables_without_policies::text, 4, ' ');
    ELSE
        RAISE NOTICE '║ ✅ Todas las tablas con RLS tienen políticas            ║';
    END IF;
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;
