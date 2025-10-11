-- Actualizar votaciones para competición de ponencias
-- Crear una competición entre 4 ponencias

-- 1. LIMPIAR VOTACIONES EXISTENTES
DELETE FROM votes;
DELETE FROM voting_topics;

-- 2. CREAR NUEVA VOTACIÓN DE COMPETICIÓN
INSERT INTO voting_topics (id, title, description, options, is_active, allows_multiple_votes) VALUES
('33333333-3333-3333-3333-333333333333', 'Competición de Mejores Ponencias', 'Vota por la ponencia que consideres la mejor del congreso', '["Ponencia 1", "Ponencia 2", "Ponencia 3", "Ponencia 4"]', true, false);

-- 3. VERIFICAR LA NUEVA VOTACIÓN
SELECT 'Votación de competición creada exitosamente' as status;

-- Mostrar la nueva votación
SELECT id, title, description, options, is_active
FROM voting_topics
WHERE id = '33333333-3333-3333-3333-333333333333';