-- Verificación rápida de políticas optimizadas
-- Ejecutar DESPUÉS de optimize_tags_rls_policies.sql

-- Ver todas las políticas actuales en tags
SELECT
    policyname,
    cmd as operacion,
    permissive,
    roles
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'tags'
ORDER BY cmd, policyname;

-- Contar políticas por tipo
SELECT
    cmd as operacion,
    COUNT(*) as cantidad
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'tags'
GROUP BY cmd
ORDER BY cmd;
