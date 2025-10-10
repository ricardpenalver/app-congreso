# 🎉 App del Congreso

Una aplicación web completa para la gestión de congresos y conferencias, construida con HTML, CSS, JavaScript y Supabase.

## 🚀 Funcionalidades

### ✅ Implementadas
- **📅 Agenda Completa** - Cronograma de 3 días con sesiones, ponentes y ubicaciones
- **📝 Registro de Asistentes** - Formulario completo con integración a Supabase
- **🗳️ Sistema de Votación** - Votaciones interactivas con conteo en tiempo real
- **🏷️ Sistema de Etiquetas** - Palabras clave y ideas compartidas por usuarios
- **🗄️ Base de Datos Supabase** - Esquema completo con RLS y optimizaciones

### 🔄 En Desarrollo
- **👥 Información de Ponentes** - Perfiles detallados y biografías
- **🔔 Notificaciones** - Recordatorios de sesiones
- **🗺️ Mapas y Ubicaciones** - Planos del venue
- **🤝 Networking** - Intercambio de contactos
- **📎 Recursos** - Documentos descargables
- **📊 Encuestas** - Feedback de sesiones
- **📱 PWA** - Instalable como app nativa
- **🔄 Modo Offline** - Funcionalidad sin internet

## 🛠️ Configuración

### 1. Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com)
2. Ejecuta el archivo `congress_app_schema.sql` en el SQL Editor
3. Copia tu URL del proyecto y clave anónima
4. Actualiza el archivo `.env`:

```env
SUPABASE_URL=tu_url_del_proyecto_aqui
SUPABASE_ANON_KEY=tu_clave_anonima_aqui
```

5. Actualiza las credenciales en `index.html` (líneas 717-718):

```javascript
const supabaseUrl = 'tu_url_del_proyecto_aqui';
const supabaseKey = 'tu_clave_anonima_aqui';
```

### 2. Ejecutar la App

1. Abre `index.html` en tu navegador
2. O usa un servidor local:

```bash
# Con Python
python -m http.server 8000

# Con Node.js
npx serve .

# Con PHP
php -S localhost:8000
```

## 📁 Estructura del Proyecto

```
├── index.html              # Aplicación principal
├── congress_app_schema.sql  # Esquema de base de datos
├── .env                    # Variables de entorno
├── README.md               # Este archivo
└── .claude/                # Configuración de Claude Code
```

## 🗄️ Esquema de Base de Datos

El proyecto incluye un esquema completo con:

- **Asistentes** - Perfiles y registro
- **Sesiones** - Agenda y cronogramas
- **Ponentes** - Información de speakers
- **Votaciones** - Sistema de voting
- **Tags** - Etiquetas e ideas
- **Networking** - Conexiones entre usuarios
- **Notificaciones** - Sistema de alerts
- **Recursos** - Archivos y materiales
- **Feedback** - Encuestas y evaluaciones

## 🔐 Seguridad

- Row Level Security (RLS) habilitado
- Políticas de acceso granulares
- Datos sensibles protegidos
- Autenticación de usuarios

## 📱 Características Móviles

- Diseño responsive
- Touch-friendly UI
- Optimizado para móviles
- PWA ready (próximamente)

## 🚀 Próximas Funcionalidades

- Autenticación de usuarios
- Push notifications
- Modo offline completo
- Sincronización de datos
- Analytics del congreso
- Exportación de datos

## 📞 Soporte

Para reportar issues o solicitar funcionalidades, crea un issue en el repositorio del proyecto.