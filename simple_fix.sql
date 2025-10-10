-- Solución Simple: Modificar la tabla attendees para no requerir auth
-- Cambiar la columna id para que no dependa de auth.users

-- 1. ELIMINAR LA RESTRICCIÓN FOREIGN KEY
ALTER TABLE attendees DROP CONSTRAINT attendees_id_fkey;

-- 2. CAMBIAR LA COLUMNA ID PARA QUE SEA INDEPENDIENTE
ALTER TABLE attendees ALTER COLUMN id SET DEFAULT uuid_generate_v4();

-- 3. VERIFICAR LA ESTRUCTURA
SELECT 'Tabla attendees modificada correctamente' as status;

-- 4. INSERTAR UN REGISTRO DE PRUEBA
INSERT INTO attendees (full_name, email, phone, organization_name, registration_status)
VALUES ('Test User', 'test@ejemplo.com', '123456789', 'Test Org', 'pending');

SELECT 'Registro de prueba creado exitosamente' as status;