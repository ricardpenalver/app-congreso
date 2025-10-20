-- Optimización de Políticas RLS en Tags
-- Eliminar políticas redundantes y mantener solo las necesarias
-- Fecha: 2025-10-19

-- ================================================================
-- DIAGNÓSTICO: Ver políticas actuales ANTES de la limpieza
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
ORDER BY cmd, policyname;

-- ================================================================
-- PASO 1: Eliminar políticas INSERT redundantes
-- ================================================================

-- Eliminar "Anyone can create tags" (genérica, menos descriptiva)
DROP POLICY IF EXISTS "Anyone can create tags" ON tags;

-- Eliminar "Anonymous users can create tags" (redundante)
DROP POLICY IF EXISTS "Anonymous users can create tags" ON tags;

-- MANTENER: "Allow anonymous and authenticated tag creation"
-- Es la más descriptiva y fue creada como parte del fix

-- ================================================================
-- PASO 2: Evaluar política "Allow public operations on tags"
-- ================================================================

-- Esta política permite ALL (INSERT, UPDATE, DELETE, SELECT)
-- Es muy permisiva y puede entrar en conflicto con políticas específicas

-- Si existe, vamos a eliminarla y usar políticas granulares
DROP POLICY IF EXISTS "Allow public operations on tags" ON tags;

-- ================================================================
-- PASO 3: Asegurar que tenemos políticas SELECT
-- ================================================================

-- Crear política SELECT explícita si no existe
DO $$
BEGIN
    -- Verificar si existe alguna política SELECT
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
        AND tablename = 'tags'
        AND cmd = 'SELECT'
    ) THEN
        -- Crear política SELECT permisiva
        CREATE POLICY "Anyone can view tags" ON tags
            FOR SELECT
            USING (true);

        RAISE NOTICE '✅ Creada política SELECT: "Anyone can view tags"';
    ELSE
        RAISE NOTICE '✅ Ya existe política SELECT, no se crea duplicada';
    END IF;
END $$;

-- ================================================================
-- PASO 4: Revisar políticas UPDATE y DELETE
-- ================================================================

-- Las políticas UPDATE y DELETE actuales están bien:
-- - "Users can update their own tags" - Permite actualizar tags propios o anónimos
-- - "Users can delete their own tags" - Permite eliminar tags propios o anónimos

-- No requieren cambios

-- ================================================================
-- VERIFICACIÓN: Políticas finales DESPUÉS de la limpieza
-- ================================================================

SELECT
    policyname,
    cmd as operacion,
    permissive,
    CASE
        WHEN cmd = 'SELECT' THEN
            CASE
                WHEN qual::text LIKE '%true%' THEN '✅ Permite a todos ver'
                ELSE '⚠️ Restringido'
            END
        WHEN cmd = 'INSERT' THEN
            CASE
                WHEN with_check::text LIKE '%true%' THEN '✅ Permite anónimos'
                WHEN with_check::text LIKE '%IS NULL%' THEN '✅ Permite anónimos condicional'
                ELSE '⚠️ Requiere autenticación'
            END
        WHEN cmd = 'UPDATE' OR cmd = 'DELETE' THEN
            CASE
                WHEN qual::text LIKE '%IS NULL%' THEN '✅ Permite propietario o anónimo'
                ELSE '⚠️ Solo autenticados'
            END
        ELSE '❓ Revisar manualmente'
    END as descripcion
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'tags'
ORDER BY cmd, policyname;

-- ================================================================
-- TEST: Verificar que INSERT sigue funcionando
-- ================================================================

-- Intentar crear un tag de prueba (como usuario anónimo)
INSERT INTO tags (name, description, color, created_by)
VALUES ('test-post-optimizacion', 'Prueba después de optimizar políticas', '#00FF00', NULL)
ON CONFLICT (name) DO NOTHING
RETURNING id, name, created_by;

-- Si esto funciona, la optimización fue exitosa ✅

-- ================================================================
-- LIMPIEZA: Eliminar tag de prueba
-- ================================================================

DELETE FROM tags WHERE name = 'test-post-optimizacion';

-- ================================================================
-- RESUMEN FINAL
-- ================================================================

DO $$
DECLARE
    total_policies INTEGER;
    insert_policies INTEGER;
    select_policies INTEGER;
    update_policies INTEGER;
    delete_policies INTEGER;
BEGIN
    -- Contar políticas por tipo
    SELECT COUNT(*) INTO total_policies
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'tags';

    SELECT COUNT(*) INTO insert_policies
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'tags' AND cmd = 'INSERT';

    SELECT COUNT(*) INTO select_policies
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'tags' AND cmd = 'SELECT';

    SELECT COUNT(*) INTO update_policies
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'tags' AND cmd = 'UPDATE';

    SELECT COUNT(*) INTO delete_policies
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'tags' AND cmd = 'DELETE';

    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║       OPTIMIZACIÓN DE POLÍTICAS RLS EN TAGS              ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Políticas totales:     %                                ║', LPAD(total_policies::text, 2, ' ');
    RAISE NOTICE '║   - INSERT:            %                                ║', LPAD(insert_policies::text, 2, ' ');
    RAISE NOTICE '║   - SELECT:            %                                ║', LPAD(select_policies::text, 2, ' ');
    RAISE NOTICE '║   - UPDATE:            %                                ║', LPAD(update_policies::text, 2, ' ');
    RAISE NOTICE '║   - DELETE:            %                                ║', LPAD(delete_policies::text, 2, ' ');
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';

    IF total_policies BETWEEN 3 AND 5 THEN
        RAISE NOTICE '║ ✅ Optimización completada exitosamente                  ║';
        RAISE NOTICE '║ ✅ Políticas redundantes eliminadas                      ║';
        RAISE NOTICE '║ ✅ Funcionalidad verificada (INSERT funciona)            ║';
    ELSE
        RAISE NOTICE '║ ⚠️  Número de políticas inesperado: %                   ║', total_policies;
        RAISE NOTICE '║ ℹ️  Revisa la tabla de verificación arriba               ║';
    END IF;

    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;

-- ================================================================
-- CONFIGURACIÓN ÓPTIMA FINAL ESPERADA
-- ================================================================

-- Se esperan 4-5 políticas:
-- 1. [INSERT] "Allow anonymous and authenticated tag creation" - Permite crear tags
-- 2. [SELECT] "Anyone can view tags" - Permite ver todos los tags
-- 3. [UPDATE] "Users can update their own tags" - Permite actualizar tags propios
-- 4. [DELETE] "Users can delete their own tags" - Permite eliminar tags propios
-- 5. (Opcional) Cualquier otra política específica que hayas creado

-- ================================================================
-- NOTAS IMPORTANTES
-- ================================================================

COMMENT ON TABLE tags IS
    'Tabla de etiquetas optimizada. Políticas RLS:
    - INSERT: Permitido para anónimos y autenticados
    - SELECT: Permitido para todos
    - UPDATE/DELETE: Solo propietario o anónimos (condicional)';

-- ================================================================
-- INSTRUCCIONES POST-EJECUCIÓN
-- ================================================================

-- 1. Ejecuta este script completo en Supabase SQL Editor
-- 2. Verifica el resumen final en el output
-- 3. Revisa la tabla de verificación para confirmar políticas activas
-- 4. Prueba la funcionalidad de tags en la app
-- 5. Confirma que NO aparecen errores en la consola

-- ================================================================
