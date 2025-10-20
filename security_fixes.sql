-- Security Advisor Fixes
-- Correcciones para políticas RLS faltantes e incompletas
-- Fecha: 2025-10-19
-- Versión: 1.1.0

-- ================================================================
-- 1. POLÍTICAS PARA TABLA ORGANIZATIONS
-- ================================================================
-- Problema: RLS habilitado pero sin políticas definidas

-- Lectura pública de organizaciones
CREATE POLICY "Organizations are publicly readable" ON organizations
    FOR SELECT USING (true);

-- Solo administradores pueden crear organizaciones (preparado para futura implementación de roles)
-- Por ahora, cualquier usuario autenticado puede crear
CREATE POLICY "Authenticated users can create organizations" ON organizations
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Solo se pueden actualizar las organizaciones si eres miembro (preparado para futura lógica)
-- Por ahora, solo usuarios autenticados
CREATE POLICY "Authenticated users can update organizations" ON organizations
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- ================================================================
-- 2. POLÍTICAS PARA TABLA NOTIFICATION_TEMPLATES
-- ================================================================
-- Problema: Solo tiene política de lectura implícita, faltan INSERT/UPDATE/DELETE

-- Los templates son de solo lectura para usuarios normales
-- Solo administradores pueden modificar (preparado para roles futuros)
CREATE POLICY "Notification templates are publicly readable" ON notification_templates
    FOR SELECT USING (true);

-- ================================================================
-- 3. POLÍTICAS PARA TABLA IDEA_TAGS
-- ================================================================
-- Problema: RLS habilitado pero sin políticas

-- Lectura pública de relaciones idea-tag
CREATE POLICY "Idea tags are publicly readable" ON idea_tags
    FOR SELECT USING (true);

-- Usuarios pueden crear tags para sus propias ideas
CREATE POLICY "Users can tag their own ideas" ON idea_tags
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM ideas
            WHERE ideas.id = idea_tags.idea_id
            AND ideas.submitted_by = auth.uid()
        )
    );

-- Usuarios pueden eliminar tags de sus propias ideas
CREATE POLICY "Users can remove tags from their ideas" ON idea_tags
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM ideas
            WHERE ideas.id = idea_tags.idea_id
            AND ideas.submitted_by = auth.uid()
        )
    );

-- ================================================================
-- 4. POLÍTICAS FALTANTES PARA RESOURCES
-- ================================================================
-- Problema: Solo hay SELECT, faltan INSERT/UPDATE/DELETE

-- Usuarios autenticados pueden subir recursos públicos
CREATE POLICY "Authenticated users can create public resources" ON resources
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL
        AND auth.uid() = uploaded_by
    );

-- Usuarios pueden actualizar sus propios recursos
CREATE POLICY "Users can update their own resources" ON resources
    FOR UPDATE USING (auth.uid() = uploaded_by);

-- Usuarios pueden eliminar sus propios recursos
CREATE POLICY "Users can delete their own resources" ON resources
    FOR DELETE USING (auth.uid() = uploaded_by);

-- ================================================================
-- 5. POLÍTICAS PARA USUARIOS ANÓNIMOS
-- ================================================================
-- Problema: Muchas políticas dependen de auth.uid() pero la app
-- permite acceso sin autenticación actualmente

-- IMPORTANTE: Estas políticas permiten acceso anónimo temporal
-- Se deben eliminar/modificar cuando se implemente autenticación completa

-- Permitir registro de asistentes sin autenticación previa
CREATE POLICY "Anyone can register as attendee" ON attendees
    FOR INSERT WITH CHECK (true);

-- Permitir votación anónima (temporal - cambiar cuando haya auth)
CREATE POLICY "Anonymous users can vote" ON votes
    FOR INSERT WITH CHECK (attendee_id IS NULL OR auth.uid() = attendee_id);

-- Permitir creación de ideas sin autenticación (temporal)
CREATE POLICY "Anonymous users can submit ideas" ON ideas
    FOR INSERT WITH CHECK (submitted_by IS NULL OR auth.uid() = submitted_by);

-- Permitir creación de tags sin autenticación (temporal)
CREATE POLICY "Anonymous users can create tags" ON tags
    FOR INSERT WITH CHECK (created_by IS NULL OR auth.uid() = created_by);

-- ================================================================
-- 6. MEJORAS DE SEGURIDAD ADICIONALES
-- ================================================================

-- Índice para mejorar rendimiento de políticas RLS
CREATE INDEX IF NOT EXISTS idx_ideas_submitted_by_rls ON ideas(submitted_by) WHERE submitted_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_resources_uploaded_by ON resources(uploaded_by) WHERE uploaded_by IS NOT NULL;

-- Función para validar que los votos sean únicos por sesión/usuario
CREATE OR REPLACE FUNCTION validate_unique_vote()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- Trigger para validar votos únicos
DROP TRIGGER IF EXISTS trigger_validate_unique_vote ON votes;
CREATE TRIGGER trigger_validate_unique_vote
    BEFORE INSERT OR UPDATE ON votes
    FOR EACH ROW EXECUTE FUNCTION validate_unique_vote();

-- ================================================================
-- 7. POLÍTICAS MEJORADAS PARA VOTACIÓN COMPETITIVA
-- ================================================================

-- Asegurar que los votos tengan estructura válida
CREATE OR REPLACE FUNCTION validate_vote_structure()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- Trigger para validar estructura de votos
DROP TRIGGER IF EXISTS trigger_validate_vote_structure ON votes;
CREATE TRIGGER trigger_validate_vote_structure
    BEFORE INSERT OR UPDATE ON votes
    FOR EACH ROW EXECUTE FUNCTION validate_vote_structure();

-- ================================================================
-- 8. VISTA SEGURA PARA RESULTADOS DE VOTACIÓN
-- ================================================================

-- Vista que excluye información sensible de votantes
CREATE OR REPLACE VIEW public_voting_results AS
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

-- Política para vista pública
CREATE POLICY "Public voting results are readable" ON voting_topics
    FOR SELECT USING (is_active = true);

-- ================================================================
-- 9. POLÍTICAS PARA RESOURCE_DOWNLOADS
-- ================================================================
-- Mejorar políticas existentes

-- Permitir registrar descargas sin autenticación (para tracking anónimo)
CREATE POLICY "Anyone can track downloads" ON resource_downloads
    FOR INSERT WITH CHECK (true);

-- ================================================================
-- 10. COMENTARIOS Y DOCUMENTACIÓN
-- ================================================================

COMMENT ON POLICY "Organizations are publicly readable" ON organizations IS
    'Permite lectura pública de organizaciones para listados y referencias';

COMMENT ON POLICY "Idea tags are publicly readable" ON idea_tags IS
    'Permite ver qué tags están asociados a cada idea';

COMMENT ON POLICY "Anonymous users can vote" ON votes IS
    'TEMPORAL: Permitir votación anónima. ELIMINAR cuando se implemente autenticación completa';

COMMENT ON POLICY "Anonymous users can submit ideas" ON ideas IS
    'TEMPORAL: Permitir ideas anónimas. MODIFICAR cuando se implemente autenticación completa';

-- ================================================================
-- NOTAS DE IMPLEMENTACIÓN
-- ================================================================
--
-- IMPORTANTE: Este script contiene políticas TEMPORALES para usuarios anónimos
--
-- Políticas a REVISAR cuando se implemente autenticación:
-- 1. "Anyone can register as attendee" - Debería requerir email verification
-- 2. "Anonymous users can vote" - Debería requerir autenticación
-- 3. "Anonymous users can submit ideas" - Debería requerir autenticación
-- 4. "Anonymous users can create tags" - Debería requerir autenticación
--
-- Políticas a AGREGAR en el futuro:
-- 1. Roles de administrador para notification_templates
-- 2. Roles de moderador para ideas (aprobar/rechazar)
-- 3. Límites de rate-limiting para prevenir spam
-- 4. Políticas de soft-delete para auditoría
--
-- ================================================================

-- Verificación final: Listar todas las tablas con RLS y sus políticas
DO $$
DECLARE
    r RECORD;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '=== VERIFICACIÓN DE POLÍTICAS RLS ===';
    FOR r IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
        AND rowsecurity = true
        ORDER BY tablename
    LOOP
        SELECT COUNT(*) INTO policy_count
        FROM pg_policies
        WHERE schemaname = 'public'
        AND tablename = r.tablename;

        RAISE NOTICE 'Tabla: % | Políticas: %', r.tablename, policy_count;
    END LOOP;
END $$;
