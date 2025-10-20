-- Fix Security Definer View Errors
-- Recrear 3 vistas SIN SECURITY DEFINER para mejorar seguridad
-- Fecha: 2025-10-19

-- ================================================================
-- PROBLEMA: Las vistas tienen SECURITY DEFINER, lo que puede
--           exponer datos con los permisos del creador de la vista
-- SOLUCIÓN: Recrear vistas sin SECURITY DEFINER (usar SECURITY INVOKER)
-- SEGURIDAD: Las vistas respetarán los permisos del usuario que consulta
-- ================================================================

-- ================================================================
-- 1. session_schedule - Agenda con información de ponentes
-- ================================================================

-- Eliminar la vista existente
DROP VIEW IF EXISTS session_schedule CASCADE;

-- Recrear sin SECURITY DEFINER (por defecto usa SECURITY INVOKER)
CREATE VIEW session_schedule
WITH (security_invoker = true)
AS
SELECT
    s.id,
    s.title,
    s.description,
    s.session_type,
    s.start_time,
    s.end_time,
    s.location,
    s.room,
    s.capacity,
    s.is_featured,
    s.tags,
    COALESCE(
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'id', sp.id,
                'full_name', sp.full_name,
                'organization', sp.organization,
                'job_title', sp.job_title,
                'is_primary', ss.is_primary
            ) ORDER BY ss.presentation_order
        ) FILTER (WHERE sp.id IS NOT NULL),
        '[]'::json
    ) AS speakers
FROM sessions s
LEFT JOIN session_speakers ss ON s.id = ss.session_id
LEFT JOIN speakers sp ON ss.speaker_id = sp.id
GROUP BY s.id, s.title, s.description, s.session_type, s.start_time, s.end_time,
         s.location, s.room, s.capacity, s.is_featured, s.tags
ORDER BY s.start_time;

COMMENT ON VIEW session_schedule IS
    'Vista de agenda con ponentes. SECURITY INVOKER: respeta permisos del usuario consultante.';

-- ================================================================
-- 2. voting_results - Resultados de votaciones
-- ================================================================

-- Eliminar la vista existente
DROP VIEW IF EXISTS voting_results CASCADE;

-- Recrear sin SECURITY DEFINER
CREATE VIEW voting_results
WITH (security_invoker = true)
AS
SELECT
    vt.id,
    vt.title,
    vt.description,
    vt.options,
    vt.is_active,
    COUNT(v.id) as total_votes,
    JSON_AGG(
        JSON_BUILD_OBJECT(
            'selected_options', v.selected_options,
            'voted_at', v.voted_at
        )
    ) as vote_details
FROM voting_topics vt
LEFT JOIN votes v ON vt.id = v.voting_topic_id
GROUP BY vt.id, vt.title, vt.description, vt.options, vt.is_active;

COMMENT ON VIEW voting_results IS
    'Vista de resultados de votación. SECURITY INVOKER: respeta permisos del usuario consultante.';

-- ================================================================
-- 3. public_voting_results - Resultados públicos (sin identidades)
-- ================================================================

-- Eliminar la vista existente
DROP VIEW IF EXISTS public_voting_results CASCADE;

-- Recrear sin SECURITY DEFINER
CREATE VIEW public_voting_results
WITH (security_invoker = true)
AS
SELECT
    vt.id,
    vt.title,
    vt.description,
    vt.options,
    vt.is_active,
    vt.start_time,
    vt.end_time,
    COUNT(v.id) as total_votes,
    -- Agregación segura sin exponer identidades
    jsonb_agg(v.selected_options) as all_votes
FROM voting_topics vt
LEFT JOIN votes v ON vt.id = v.voting_topic_id
WHERE vt.is_active = true
GROUP BY vt.id, vt.title, vt.description, vt.options, vt.is_active, vt.start_time, vt.end_time;

COMMENT ON VIEW public_voting_results IS
    'Vista pública de votaciones (sin identidades). SECURITY INVOKER: respeta permisos del usuario consultante.';

-- ================================================================
-- VERIFICACIÓN: Confirmar que las vistas NO tienen SECURITY DEFINER
-- ================================================================

SELECT
    schemaname,
    viewname,
    viewowner,
    CASE
        WHEN definition LIKE '%security_invoker%' THEN '✅ SECURITY INVOKER (Seguro)'
        WHEN definition LIKE '%SECURITY DEFINER%' THEN '❌ SECURITY DEFINER (Inseguro)'
        ELSE '⚪ Sin especificar (por defecto INVOKER)'
    END as security_mode
FROM pg_views
WHERE schemaname = 'public'
AND viewname IN ('session_schedule', 'voting_results', 'public_voting_results')
ORDER BY viewname;

-- ================================================================
-- VERIFICACIÓN ADICIONAL: Opciones de las vistas
-- ================================================================

SELECT
    c.relname as view_name,
    c.reloptions as view_options,
    CASE
        WHEN 'security_invoker=true' = ANY(c.reloptions) THEN '✅ Seguro'
        WHEN 'security_definer=true' = ANY(c.reloptions) THEN '❌ Inseguro'
        ELSE '⚪ Por defecto'
    END as security_status
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
AND c.relkind = 'v'
AND c.relname IN ('session_schedule', 'voting_results', 'public_voting_results')
ORDER BY c.relname;

-- ================================================================
-- RESUMEN
-- ================================================================

DO $$
DECLARE
    secure_views INTEGER;
    total_views INTEGER := 3;
BEGIN
    SELECT COUNT(*) INTO secure_views
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
    AND c.relkind = 'v'
    AND c.relname IN ('session_schedule', 'voting_results', 'public_voting_results')
    AND (
        'security_invoker=true' = ANY(c.reloptions)
        OR c.reloptions IS NULL  -- Por defecto es INVOKER
    );

    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║      CORRECCIÓN DE SECURITY DEFINER EN VISTAS            ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Vistas corregidas: % de %                              ║', LPAD(secure_views::text, 1, ' '), total_views;
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    IF secure_views = total_views THEN
        RAISE NOTICE '║ ✅ Todas las vistas ahora usan SECURITY INVOKER          ║';
        RAISE NOTICE '║ ✅ Los errores del Security Advisor deben desaparecer    ║';
        RAISE NOTICE '║ ℹ️  Las vistas respetan permisos del usuario consultante ║';
    ELSE
        RAISE NOTICE '║ ⚠️  Algunas vistas no se corrigieron correctamente       ║';
        RAISE NOTICE '║ ℹ️  Revisa la salida de las consultas de verificación    ║';
    END IF;
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;

-- ================================================================
-- NOTAS IMPORTANTES
-- ================================================================
--
-- ¿Qué significa SECURITY INVOKER?
-- - La vista ejecuta las consultas con los permisos del USUARIO que la consulta
-- - Es más seguro porque respeta las políticas RLS de cada usuario
-- - Previene escalación de privilegios
--
-- ¿Qué significa SECURITY DEFINER?
-- - La vista ejecuta con los permisos del CREADOR de la vista
-- - Puede exponer datos que el usuario no debería ver
-- - Puede ser peligroso si el creador tiene permisos elevados
--
-- Recomendación:
-- - Usar SECURITY INVOKER por defecto (como ahora)
-- - Solo usar SECURITY DEFINER si es absolutamente necesario
--   y con mucho cuidado
--
-- ================================================================
