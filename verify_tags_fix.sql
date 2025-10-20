-- Verificación de que las etiquetas se guardaron correctamente en Supabase
-- Script de verificación post-corrección del error HTTP 400
-- Fecha: 2025-10-19

-- ================================================================
-- VERIFICACIÓN 1: Ver las últimas 5 etiquetas creadas
-- ================================================================

SELECT
    id,
    name,
    description,
    color,
    created_by,
    created_at,
    CASE
        WHEN created_by IS NULL THEN '✅ Anónimo'
        ELSE '👤 Usuario: ' || created_by::text
    END as tipo_creacion
FROM tags
ORDER BY created_at DESC
LIMIT 5;

-- ================================================================
-- VERIFICACIÓN 2: Buscar las etiquetas del test
-- ================================================================

SELECT
    id,
    name,
    description,
    created_by,
    created_at
FROM tags
WHERE name IN ('inteligencia artificial', 'blockchain', 'metaverso')
ORDER BY created_at DESC;

-- ================================================================
-- VERIFICACIÓN 3: Contar etiquetas anónimas vs autenticadas
-- ================================================================

SELECT
    CASE
        WHEN created_by IS NULL THEN 'Anónimas'
        ELSE 'Autenticadas'
    END as tipo,
    COUNT(*) as total,
    MIN(created_at) as primera_creacion,
    MAX(created_at) as ultima_creacion
FROM tags
GROUP BY (created_by IS NULL)
ORDER BY tipo;

-- ================================================================
-- VERIFICACIÓN 4: Ver políticas RLS activas en tags
-- ================================================================

SELECT
    policyname,
    cmd as operacion,
    CASE
        WHEN with_check::text LIKE '%true%' THEN '✅ Permite anónimos'
        WHEN with_check::text LIKE '%IS NULL%' THEN '✅ Permite anónimos condicional'
        ELSE '⚠️ Requiere autenticación'
    END as acceso_anonimo
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'tags'
ORDER BY cmd;

-- ================================================================
-- RESUMEN FINAL
-- ================================================================

DO $$
DECLARE
    total_tags INTEGER;
    tags_anonimos INTEGER;
    tags_ultimas_24h INTEGER;
    politicas_insert INTEGER;
BEGIN
    -- Contar tags totales
    SELECT COUNT(*) INTO total_tags FROM tags;

    -- Contar tags anónimos
    SELECT COUNT(*) INTO tags_anonimos
    FROM tags
    WHERE created_by IS NULL;

    -- Contar tags de últimas 24h
    SELECT COUNT(*) INTO tags_ultimas_24h
    FROM tags
    WHERE created_at > NOW() - INTERVAL '24 hours';

    -- Contar políticas INSERT
    SELECT COUNT(*) INTO politicas_insert
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'tags'
    AND cmd = 'INSERT';

    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║     VERIFICACIÓN DE CORRECCIÓN DE ERROR HTTP 400          ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Tags totales en la BD:        %                         ║', LPAD(total_tags::text, 5, ' ');
    RAISE NOTICE '║ Tags anónimos (created_by NULL): %                      ║', LPAD(tags_anonimos::text, 5, ' ');
    RAISE NOTICE '║ Tags creados últimas 24h:     %                         ║', LPAD(tags_ultimas_24h::text, 5, ' ');
    RAISE NOTICE '║ Políticas INSERT activas:     %                         ║', LPAD(politicas_insert::text, 5, ' ');
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';

    IF politicas_insert > 0 AND tags_anonimos > 0 THEN
        RAISE NOTICE '║ ✅ ERROR HTTP 400 SOLUCIONADO                            ║';
        RAISE NOTICE '║ ✅ Las etiquetas se guardan en Supabase correctamente    ║';
        RAISE NOTICE '║ ✅ Los usuarios anónimos pueden crear tags              ║';
    ELSIF politicas_insert > 0 AND tags_anonimos = 0 THEN
        RAISE NOTICE '║ ⚠️  Políticas correctas pero no hay tags anónimos       ║';
        RAISE NOTICE '║ ℹ️  Prueba crear una etiqueta desde la app              ║';
    ELSE
        RAISE NOTICE '║ ❌ Configuración incorrecta                              ║';
        RAISE NOTICE '║ ℹ️  Revisa las políticas RLS                            ║';
    END IF;

    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;

-- ================================================================
-- NOTAS
-- ================================================================

COMMENT ON TABLE tags IS
    'Tabla de etiquetas. Permite creación tanto por usuarios autenticados como anónimos (created_by puede ser NULL).';

-- ================================================================
-- LIMPIEZA OPCIONAL: Eliminar tags de prueba
-- ================================================================

-- Si quieres eliminar las etiquetas de prueba, descomenta la siguiente línea:
-- DELETE FROM tags WHERE name IN ('inteligencia artificial', 'blockchain', 'metaverso', 'test-diagnostico-2025');
