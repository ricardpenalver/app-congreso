-- Fix RLS Policies for Testing - App del Congreso
-- Este archivo soluciona los problemas de permisos para testing sin autenticación

-- 1. DESACTIVAR RLS TEMPORALMENTE PARA TABLAS PRINCIPALES
ALTER TABLE attendees DISABLE ROW LEVEL SECURITY;
ALTER TABLE tags DISABLE ROW LEVEL SECURITY;
ALTER TABLE votes DISABLE ROW LEVEL SECURITY;
ALTER TABLE ideas DISABLE ROW LEVEL SECURITY;

-- 2. CREAR POLÍTICAS PÚBLICAS PARA TESTING

-- Políticas para attendees (sin autenticación)
DROP POLICY IF EXISTS "Users can view all confirmed attendees" ON attendees;
DROP POLICY IF EXISTS "Users can update their own profile" ON attendees;

CREATE POLICY "Allow public operations on attendees" ON attendees FOR ALL USING (true) WITH CHECK (true);

-- Políticas para tags (sin autenticación)
DROP POLICY IF EXISTS "Tags are publicly readable" ON tags;
DROP POLICY IF EXISTS "Authenticated users can create tags" ON tags;

CREATE POLICY "Allow public operations on tags" ON tags FOR ALL USING (true) WITH CHECK (true);

-- Políticas para votes (sin autenticación)
DROP POLICY IF EXISTS "Users can view their own votes" ON votes;
DROP POLICY IF EXISTS "Users can create votes" ON votes;
DROP POLICY IF EXISTS "Users can update their own votes" ON votes;

CREATE POLICY "Allow public operations on votes" ON votes FOR ALL USING (true) WITH CHECK (true);

-- Políticas para ideas (sin autenticación)
DROP POLICY IF EXISTS "Ideas are publicly readable" ON ideas;
DROP POLICY IF EXISTS "Users can create ideas" ON ideas;
DROP POLICY IF EXISTS "Users can update their own ideas" ON ideas;

CREATE POLICY "Allow public operations on ideas" ON ideas FOR ALL USING (true) WITH CHECK (true);

-- 3. REACTIVAR RLS CON NUEVAS POLÍTICAS
ALTER TABLE attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;

-- 4. VERIFICAR QUE LAS TABLAS ESTÉN CONFIGURADAS CORRECTAMENTE
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('attendees', 'tags', 'votes', 'ideas');

-- Mensaje de confirmación
SELECT 'RLS policies updated successfully for testing without authentication' as status;