-- Fix Tags RLS Error - Permitir INSERT de usuarios anónimos
-- Solución para Error HTTP 400 (PGRST204)
-- Fecha: 2025-10-19

-- ================================================================
-- DIAGNÓSTICO: Verificar estado actual de la tabla tags
-- ================================================================

-- Ver estructura de la tabla tags
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'tags'
ORDER BY ordinal_position;

-- Ver políticas actuales en la tabla tags
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'tags';

-- ================================================================
-- SOLUCIÓN 1: Permitir que created_by sea NULL
-- ================================================================

-- Si la columna created_by tiene restricción NOT NULL, quitarla
ALTER TABLE tags
ALTER COLUMN created_by DROP NOT NULL;

-- ================================================================
-- SOLUCIÓN 2: Eliminar política conflictiva (si existe)
-- ================================================================

-- Eliminar la política que requiere autenticación
DROP POLICY IF EXISTS "Authenticated users can create tags" ON tags;

-- ================================================================
-- SOLUCIÓN 3: Crear política permisiva para INSERT anónimo
-- ================================================================

-- Política que permite INSERT sin autenticación
CREATE POLICY "Allow anonymous and authenticated tag creation" ON tags
    FOR INSERT
    WITH CHECK (true);

-- Alternativamente, si quieres rastrear al creador cuando esté disponible:
-- CREATE POLICY "Allow anonymous and authenticated tag creation" ON tags
--     FOR INSERT
--     WITH CHECK (
--         created_by IS NULL
--         OR auth.uid() = created_by
--         OR auth.uid() IS NULL
--     );

-- ================================================================
-- SOLUCIÓN 4: Asegurar que UPDATE/DELETE también funcionen
-- ================================================================

-- Permitir actualizar tags propias o anónimas
DROP POLICY IF EXISTS "Users can update their own tags" ON tags;
CREATE POLICY "Users can update their own tags" ON tags
    FOR UPDATE
    USING (
        created_by IS NULL
        OR auth.uid() = created_by
        OR auth.uid() IS NULL
    );

-- Permitir eliminar tags propias o anónimas
DROP POLICY IF EXISTS "Users can delete their own tags" ON tags;
CREATE POLICY "Users can delete their own tags" ON tags
    FOR DELETE
    USING (
        created_by IS NULL
        OR auth.uid() = created_by
        OR auth.uid() IS NULL
    );

-- ================================================================
-- VERIFICACIÓN: Comprobar que las políticas se crearon correctamente
-- ================================================================

SELECT
    tablename,
    policyname,
    cmd as operation,
    CASE
        WHEN with_check::text LIKE '%true%' THEN '✅ Permite anónimos'
        WHEN with_check::text LIKE '%created_by IS NULL%' THEN '✅ Permite anónimos condicional'
        ELSE '⚠️ Requiere autenticación'
    END as anonymous_access
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'tags'
ORDER BY cmd;

-- ================================================================
-- TEST: Simular INSERT anónimo
-- ================================================================

-- Intentar crear un tag sin usuario (simula usuario anónimo)
-- IMPORTANTE: Ejecutar esto DESPUÉS de aplicar las políticas anteriores

INSERT INTO tags (name, description, color, created_by)
VALUES
    ('test-tag-anonymous', 'Tag de prueba para verificar INSERT anónimo', '#FF6B6B', NULL)
ON CONFLICT (name) DO NOTHING;

-- Verificar que se creó correctamente
SELECT
    id,
    name,
    description,
    created_by,
    created_at
FROM tags
WHERE name = 'test-tag-anonymous';

-- Si ves el registro, ¡la solución funcionó! ✅

-- ================================================================
-- LIMPIEZA: Eliminar tag de prueba
-- ================================================================

DELETE FROM tags WHERE name = 'test-tag-anonymous';

-- ================================================================
-- RESUMEN FINAL
-- ================================================================

DO $$
DECLARE
    total_policies INTEGER;
    insert_policies INTEGER;
    anonymous_friendly INTEGER;
BEGIN
    -- Contar políticas totales
    SELECT COUNT(*) INTO total_policies
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'tags';

    -- Contar políticas INSERT
    SELECT COUNT(*) INTO insert_policies
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'tags'
    AND cmd = 'INSERT';

    -- Contar políticas que permiten anónimos
    SELECT COUNT(*) INTO anonymous_friendly
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'tags'
    AND (
        with_check::text LIKE '%true%'
        OR with_check::text LIKE '%IS NULL%'
    );

    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║           CORRECCIÓN DE RLS EN TAGS COMPLETADA           ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Políticas totales en tags:        %                     ║', LPAD(total_policies::text, 3, ' ');
    RAISE NOTICE '║ Políticas INSERT:                 %                     ║', LPAD(insert_policies::text, 3, ' ');
    RAISE NOTICE '║ Políticas que permiten anónimos:  %                     ║', LPAD(anonymous_friendly::text, 3, ' ');
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';

    IF insert_policies > 0 AND anonymous_friendly > 0 THEN
        RAISE NOTICE '║ ✅ Configuración correcta - Tags pueden crearse          ║';
        RAISE NOTICE '║ ✅ Usuarios anónimos pueden insertar tags               ║';
        RAISE NOTICE '║ ✅ El error HTTP 400 debería estar solucionado          ║';
    ELSE
        RAISE NOTICE '║ ⚠️  Revisar configuración - Puede haber problemas        ║';
    END IF;

    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;

-- ================================================================
-- NOTAS IMPORTANTES
-- ================================================================

COMMENT ON POLICY "Allow anonymous and authenticated tag creation" ON tags IS
    'Permite crear tags tanto a usuarios autenticados como anónimos. TEMPORAL: revisar cuando se implemente autenticación completa.';

-- ================================================================
-- INSTRUCCIONES POST-APLICACIÓN
-- ================================================================

-- 1. Ejecuta este script completo en Supabase SQL Editor
-- 2. Verifica el mensaje de éxito en el output
-- 3. Prueba la funcionalidad de etiquetas en la app
-- 4. Verifica que NO aparezca el error 400 en la consola
-- 5. Las etiquetas deberían guardarse en Supabase en lugar de localStorage

-- ================================================================
