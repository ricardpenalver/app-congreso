-- Fix Attendees Table - Permitir registros sin autenticación
-- Este script crea una tabla temporal para testing sin auth

-- 1. CREAR TABLA TEMPORAL PARA ATTENDEES SIN RESTRICCIÓN DE AUTH
DROP TABLE IF EXISTS public_attendees CASCADE;

CREATE TABLE public_attendees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    organization_name TEXT,
    job_title TEXT,
    bio TEXT,
    registration_status TEXT DEFAULT 'pending',
    registration_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. DESACTIVAR RLS PARA LA TABLA TEMPORAL
ALTER TABLE public_attendees DISABLE ROW LEVEL SECURITY;

-- 3. CREAR TABLA TEMPORAL PARA TAGS SIN RESTRICCIONES
DROP TABLE IF EXISTS public_tags CASCADE;

CREATE TABLE public_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. DESACTIVAR RLS PARA TAGS TEMPORAL
ALTER TABLE public_tags DISABLE ROW LEVEL SECURITY;

-- 5. INSERTAR ALGUNOS DATOS DE EJEMPLO PARA VERIFICAR
INSERT INTO public_attendees (full_name, email, phone, organization_name) VALUES
('Juan Pérez', 'juan@ejemplo.com', '123456789', 'Tech Corp'),
('María García', 'maria@ejemplo.com', '987654321', 'Innovación SA');

INSERT INTO public_tags (name, color) VALUES
('Tecnología', '#FF6B6B'),
('Innovación', '#4ECDC4'),
('Desarrollo', '#45B7D1');

-- 6. VERIFICAR QUE SE CREARON CORRECTAMENTE
SELECT 'Tablas temporales creadas exitosamente' as status;
SELECT 'Attendees:', count(*) FROM public_attendees;
SELECT 'Tags:', count(*) FROM public_tags;