-- Diagnóstico completo del problema de tags
-- Ejecutar en Supabase SQL Editor

-- 1. Ver todas las políticas actuales en la tabla tags
SELECT
    policyname,
    cmd as operation,
    permissive,
    roles,
    qual as using_check,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'tags'
ORDER BY cmd;

-- 2. Verificar estructura de la tabla
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'tags'
ORDER BY ordinal_position;

-- 3. Intentar INSERT directo (simulando lo que hace la app)
INSERT INTO tags (name, description, color, created_by)
VALUES ('test-diagnostico-2025', 'Prueba de diagnóstico', '#FF0000', NULL)
ON CONFLICT (name) DO NOTHING
RETURNING *;

-- 4. Ver si se creó
SELECT * FROM tags WHERE name = 'test-diagnostico-2025';

-- 5. Limpiar
DELETE FROM tags WHERE name = 'test-diagnostico-2025';
