-- Fix Function Search Path Mutable Warnings
-- Corrección para 6 funciones con search_path mutable
-- Fecha: 2025-10-19

-- ================================================================
-- PROBLEMA: Las funciones no tienen search_path configurado
-- SOLUCIÓN: Recrear funciones con SET search_path = public
-- SEGURIDAD: Previene ataques de "schema poisoning"
-- ================================================================

-- ================================================================
-- 1. update_updated_at_column
-- ================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION update_updated_at_column() IS
    'Actualiza automáticamente el campo updated_at al modificar un registro. Security: search_path fijo.';

-- ================================================================
-- 2. validate_unique_vote
-- ================================================================
CREATE OR REPLACE FUNCTION validate_unique_vote()
RETURNS TRIGGER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar si ya existe un voto para este topic y attendee
    IF EXISTS (
        SELECT 1 FROM votes
        WHERE voting_topic_id = NEW.voting_topic_id
        AND attendee_id = NEW.attendee_id
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
        RAISE EXCEPTION 'Ya has votado en este tema';
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION validate_unique_vote() IS
    'Valida que un usuario no pueda votar más de una vez en el mismo tema. Security: search_path fijo.';

-- ================================================================
-- 3. validate_vote_structure
-- ================================================================
CREATE OR REPLACE FUNCTION validate_vote_structure()
RETURNS TRIGGER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    topic_options JSONB;
BEGIN
    -- Obtener las opciones del topic
    SELECT options INTO topic_options
    FROM voting_topics
    WHERE id = NEW.voting_topic_id;

    -- Validar que selected_options sea un array válido
    IF jsonb_typeof(NEW.selected_options) != 'array' THEN
        RAISE EXCEPTION 'selected_options debe ser un array';
    END IF;

    -- Validar que las opciones seleccionadas existan en el topic
    -- (Esta validación se puede expandir según tus necesidades)

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION validate_vote_structure() IS
    'Valida la estructura JSON de los votos antes de insertarlos. Security: search_path fijo.';

-- ================================================================
-- 4. update_idea_vote_counts
-- ================================================================
CREATE OR REPLACE FUNCTION update_idea_vote_counts()
RETURNS TRIGGER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.vote_type = 'up' THEN
            UPDATE ideas SET upvotes = upvotes + 1 WHERE id = NEW.idea_id;
        ELSE
            UPDATE ideas SET downvotes = downvotes + 1 WHERE id = NEW.idea_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.vote_type = 'up' THEN
            UPDATE ideas SET upvotes = upvotes - 1 WHERE id = OLD.idea_id;
        ELSE
            UPDATE ideas SET downvotes = downvotes - 1 WHERE id = OLD.idea_id;
        END IF;

        IF NEW.vote_type = 'up' THEN
            UPDATE ideas SET upvotes = upvotes + 1 WHERE id = NEW.idea_id;
        ELSE
            UPDATE ideas SET downvotes = downvotes + 1 WHERE id = NEW.idea_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.vote_type = 'up' THEN
            UPDATE ideas SET upvotes = upvotes - 1 WHERE id = OLD.idea_id;
        ELSE
            UPDATE ideas SET downvotes = downvotes - 1 WHERE id = OLD.idea_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

COMMENT ON FUNCTION update_idea_vote_counts() IS
    'Actualiza contadores de upvotes/downvotes en ideas automáticamente. Security: search_path fijo.';

-- ================================================================
-- 5. increment_download_count
-- ================================================================
CREATE OR REPLACE FUNCTION increment_download_count()
RETURNS TRIGGER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE resources SET download_count = download_count + 1 WHERE id = NEW.resource_id;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION increment_download_count() IS
    'Incrementa el contador de descargas de un recurso. Security: search_path fijo.';

-- ================================================================
-- 6. get_table_sizes
-- ================================================================
CREATE OR REPLACE FUNCTION get_table_sizes()
RETURNS TABLE(
    table_name TEXT,
    row_count BIGINT,
    total_size TEXT,
    index_size TEXT
)
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        schemaname||'.'||tablename as table_name,
        n_tup_ins - n_tup_del as row_count,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
        pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) as index_size
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$;

COMMENT ON FUNCTION get_table_sizes() IS
    'Función de monitoreo: retorna tamaños de tablas e índices. Security: search_path fijo.';

-- ================================================================
-- VERIFICACIÓN: Listar funciones con search_path configurado
-- ================================================================
SELECT
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    CASE
        WHEN p.proconfig IS NOT NULL THEN
            (SELECT string_agg(unnest, ', ')
             FROM unnest(p.proconfig))
        ELSE 'No configurado'
    END as search_path_config,
    CASE
        WHEN p.proconfig IS NOT NULL AND
             EXISTS (SELECT 1 FROM unnest(p.proconfig) WHERE unnest LIKE 'search_path=%')
        THEN '✅ Seguro'
        ELSE '⚠️  Sin search_path'
    END as security_status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN (
    'update_updated_at_column',
    'validate_unique_vote',
    'validate_vote_structure',
    'update_idea_vote_counts',
    'increment_download_count',
    'get_table_sizes'
)
ORDER BY p.proname;

-- ================================================================
-- RESUMEN
-- ================================================================
DO $$
DECLARE
    total_fixed INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_fixed
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname IN (
        'update_updated_at_column',
        'validate_unique_vote',
        'validate_vote_structure',
        'update_idea_vote_counts',
        'increment_download_count',
        'get_table_sizes'
    )
    AND p.proconfig IS NOT NULL
    AND EXISTS (SELECT 1 FROM unnest(p.proconfig) WHERE unnest LIKE 'search_path=%');

    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║    CORRECCIÓN DE SEARCH_PATH EN FUNCIONES COMPLETADA     ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Funciones corregidas: % de 6                           ║', LPAD(total_fixed::text, 1, ' ');
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    IF total_fixed = 6 THEN
        RAISE NOTICE '║ ✅ Todas las funciones ahora tienen search_path fijo     ║';
        RAISE NOTICE '║ ✅ Los warnings del Security Advisor deben desaparecer   ║';
    ELSE
        RAISE NOTICE '║ ⚠️  Algunas funciones no se corrigieron correctamente    ║';
    END IF;
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;
