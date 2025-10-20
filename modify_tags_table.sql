-- Modificar tabla tags para permitir etiquetas repetidas (jerarquía por frecuencia)
-- Esto permite que múltiples usuarios envíen la misma palabra clave

-- 1. Eliminar la restricción UNIQUE en la columna name
ALTER TABLE tags DROP CONSTRAINT IF EXISTS tags_name_key;

-- 2. Mantener el índice para rendimiento pero sin UNIQUE
DROP INDEX IF EXISTS idx_tags_name;
CREATE INDEX idx_tags_name ON tags(name);

-- 3. Agregar un nuevo índice para contar frecuencias
CREATE INDEX idx_tags_name_count ON tags(name) WHERE created_by IS NULL;

-- Verificación
SELECT
    'Restricción UNIQUE eliminada - ahora se pueden repetir etiquetas' as status,
    COUNT(*) as total_tags_actual
FROM tags;
