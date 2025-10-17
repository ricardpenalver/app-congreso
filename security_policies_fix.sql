-- SECURITY POLICIES FIX FOR ANONYMOUS ACCESS
-- Este archivo corrige las políticas RLS para permitir acceso anónimo controlado
-- Ejecutar en Supabase SQL Editor

-- ============================================================================
-- PASO 1: ELIMINAR POLÍTICAS RESTRICTIVAS EXISTENTES
-- ============================================================================

-- Eliminar políticas que requieren autenticación
DROP POLICY IF EXISTS "Users can view their own votes" ON votes;
DROP POLICY IF EXISTS "Users can create votes" ON votes;
DROP POLICY IF EXISTS "Users can update their own votes" ON votes;
DROP POLICY IF EXISTS "Authenticated users can create tags" ON tags;
DROP POLICY IF EXISTS "Users can create ideas" ON ideas;
DROP POLICY IF EXISTS "Users can update their own ideas" ON ideas;
DROP POLICY IF EXISTS "Users can create idea votes" ON idea_votes;
DROP POLICY IF EXISTS "Users can update their own idea votes" ON idea_votes;

-- ============================================================================
-- PASO 2: CREAR POLÍTICAS PERMISIVAS PARA ACCESO ANÓNIMO
-- ============================================================================

-- VOTING SYSTEM - Permitir votación anónima
-- voting_topics: Lectura pública (ya existe, OK)
-- votes: Permitir inserción y lectura anónima

CREATE POLICY "Anyone can view all votes" ON votes
    FOR SELECT USING (true);

CREATE POLICY "Anyone can create votes" ON votes
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update votes" ON votes
    FOR UPDATE USING (true);

-- TAGS SYSTEM - Permitir creación anónima de tags
CREATE POLICY "Anyone can create tags" ON tags
    FOR INSERT WITH CHECK (true);

-- IDEAS SYSTEM - Permitir ideas anónimas
CREATE POLICY "Anyone can create ideas" ON ideas
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update ideas" ON ideas
    FOR UPDATE USING (true);

-- IDEA VOTES - Permitir votos anónimos en ideas
CREATE POLICY "Anyone can create idea votes" ON idea_votes
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update idea votes" ON idea_votes
    FOR UPDATE USING (true);

-- ============================================================================
-- PASO 3: ACTUALIZAR TABLAS PARA PERMITIR NULL EN attendee_id
-- ============================================================================

-- Modificar votos para permitir votos anónimos
ALTER TABLE votes ALTER COLUMN attendee_id DROP NOT NULL;

-- Modificar ideas para permitir ideas anónimas
ALTER TABLE ideas ALTER COLUMN submitted_by DROP NOT NULL;

-- Modificar idea_votes para permitir votos anónimos
ALTER TABLE idea_votes ALTER COLUMN attendee_id DROP NOT NULL;

-- Modificar tags para permitir tags anónimas
ALTER TABLE tags ALTER COLUMN created_by DROP NOT NULL;

-- ============================================================================
-- PASO 4: ELIMINAR CONSTRAINT ÚNICO QUE IMPIDE VOTOS MÚLTIPLES ANÓNIMOS
-- ============================================================================

-- Nota: Si quieres permitir votos anónimos múltiples, descomenta esto:
-- ALTER TABLE votes DROP CONSTRAINT IF EXISTS votes_voting_topic_id_attendee_id_key;
-- ALTER TABLE idea_votes DROP CONSTRAINT IF EXISTS idea_votes_idea_id_attendee_id_key;

-- Si quieres limitar un voto por IP o dispositivo, necesitarás implementar
-- lógica adicional en el frontend con localStorage

-- ============================================================================
-- PASO 5: VERIFICACIÓN
-- ============================================================================

-- Verificar que RLS está habilitado
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('votes', 'voting_topics', 'tags', 'ideas', 'idea_votes');

-- Verificar políticas activas
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('votes', 'voting_topics', 'tags', 'ideas', 'idea_votes');

-- ============================================================================
-- RESULTADO ESPERADO
-- ============================================================================
-- ✅ voting_topics: Lectura pública (ya existía)
-- ✅ votes: Lectura, escritura y actualización pública
-- ✅ tags: Lectura y escritura pública
-- ✅ ideas: Lectura, escritura y actualización pública
-- ✅ idea_votes: Lectura, escritura y actualización pública
-- ✅ sessions, speakers, session_speakers: Lectura pública (ya existían)

-- ============================================================================
-- IMPORTANTE: SEGURIDAD
-- ============================================================================
-- ADVERTENCIA: Estas políticas permiten acceso público sin autenticación.
-- Esto es apropiado para:
-- ✅ Aplicaciones de eventos públicos
-- ✅ Votaciones abiertas
-- ✅ Recopilación de ideas públicas
--
-- NO es apropiado para:
-- ❌ Datos sensibles o privados
-- ❌ Información personal identificable
-- ❌ Sistemas con requisitos de auditoría estrictos
--
-- RECOMENDACIONES ADICIONALES:
-- 1. Implementar rate limiting en el frontend
-- 2. Usar localStorage para prevenir votos duplicados
-- 3. Considerar implementar CAPTCHA para prevenir spam
-- 4. Monitorear uso de la API para detectar abusos
-- 5. Implementar autenticación en el futuro si es necesario
