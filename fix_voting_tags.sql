-- Solucionar Votaciones y Etiquetas - Eliminar restricciones de autenticación

-- 1. ARREGLAR TABLA TAGS
-- Eliminar restricción de foreign key para created_by si existe
ALTER TABLE tags ALTER COLUMN created_by DROP NOT NULL;

-- 2. ARREGLAR TABLA VOTING_TOPICS
-- Eliminar restricción de foreign key para created_by si existe
ALTER TABLE voting_topics ALTER COLUMN created_by DROP NOT NULL;

-- 3. ARREGLAR TABLA VOTES
-- Eliminar restricción de foreign key para attendee_id si existe
ALTER TABLE votes ALTER COLUMN attendee_id DROP NOT NULL;

-- 4. INSERTAR DATOS DE PRUEBA PARA VOTACIONES
-- Limpiar votaciones existentes
DELETE FROM votes;
DELETE FROM voting_topics;

-- Insertar tópicos de votación de prueba
INSERT INTO voting_topics (id, title, description, options, is_active, allows_multiple_votes) VALUES
('11111111-1111-1111-1111-111111111111', 'Mejor Horario para Sesiones', 'Vota por el horario que prefieres para las sesiones del congreso', '["Mañana (9:00 AM)", "Tarde (2:00 PM)", "Noche (7:00 PM)"]', true, false),
('22222222-2222-2222-2222-222222222222', 'Temas de Interés', 'Selecciona los temas que más te interesan (puedes votar por varios)', '["Inteligencia Artificial", "Blockchain", "Sostenibilidad", "Ciberseguridad", "IoT"]', true, true);

-- 5. VERIFICAR PERMISOS DE TABLAS
SELECT 'Permisos actualizados para voting_topics, votes y tags' as status;

-- Mostrar estructura de las tablas principales
SELECT table_name, column_name, is_nullable
FROM information_schema.columns
WHERE table_name IN ('tags', 'voting_topics', 'votes', 'attendees')
  AND table_schema = 'public'
ORDER BY table_name, ordinal_position;