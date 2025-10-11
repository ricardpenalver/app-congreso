-- Actualizar sistema de votación a puntuaciones individuales
-- Cada ponencia tendrá su propia votación con opciones de 5, 3, 2, 1 puntos

-- 1. LIMPIAR VOTACIONES EXISTENTES
DELETE FROM votes;
DELETE FROM voting_topics;

-- 2. CREAR VOTACIÓN PARA CADA PONENCIA CON SISTEMA DE PUNTOS
INSERT INTO voting_topics (id, title, description, options, is_active, allows_multiple_votes) VALUES
('44444444-4444-4444-4444-444444444444', 'Ponencia 1', 'Valora esta ponencia', '["5 puntos", "3 puntos", "2 puntos", "1 punto"]', true, false),
('55555555-5555-5555-5555-555555555555', 'Ponencia 2', 'Valora esta ponencia', '["5 puntos", "3 puntos", "2 puntos", "1 punto"]', true, false),
('66666666-6666-6666-6666-666666666666', 'Ponencia 3', 'Valora esta ponencia', '["5 puntos", "3 puntos", "2 puntos", "1 punto"]', true, false),
('77777777-7777-7777-7777-777777777777', 'Ponencia 4', 'Valora esta ponencia', '["5 puntos", "3 puntos", "2 puntos", "1 punto"]', true, false);

-- 3. VERIFICAR LAS NUEVAS VOTACIONES
SELECT 'Sistema de puntuación creado exitosamente' as status;

-- Mostrar todas las votaciones
SELECT id, title, description, options, is_active
FROM voting_topics
ORDER BY title;