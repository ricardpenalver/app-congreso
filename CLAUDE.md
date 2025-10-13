# 📋 CLAUDE.md - Documentación del Proyecto

## 🎯 Información del Proyecto

**Nombre:** App del Congreso
**Tipo:** Aplicación Web para Gestión de Conferencias
**Estado:** En Desarrollo Activo
**Tecnologías:** HTML5, CSS3, JavaScript ES6+, Supabase PostgreSQL

## 🏗️ Arquitectura

### Stack Tecnológico
- **Frontend:** Vanilla HTML/CSS/JavaScript
- **Backend:** Supabase (PostgreSQL + API REST)
- **Base de Datos:** PostgreSQL con Row Level Security
- **Almacenamiento:** Supabase Storage + localStorage (fallback)
- **Autenticación:** Supabase Auth (preparado)

### Estructura de Archivos
```
/Users/rilihouse/PROYECTOS/CLAUDE CODE/
├── index.html              # Aplicación principal (SPA)
├── congress_app_schema.sql  # Esquema completo de BD
├── .env                    # Variables de entorno
├── README.md               # Documentación del usuario
├── CLAUDE.md               # Esta documentación
└── .claude/                # Configuración Claude Code
```

## 🗄️ Base de Datos

### Esquema Principal
- **attendees** - Perfiles de asistentes
- **sessions** - Agenda y cronogramas
- **speakers** - Información de ponentes
- **voting_topics** + **votes** - Sistema de votaciones
- **tags** + **ideas** - Sistema de etiquetas
- **networking_connections** - Red de contactos
- **notifications** - Sistema de alertas
- **resources** - Materiales descargables
- **feedback** - Encuestas y evaluaciones

### Características de BD
- 25+ tablas interconectadas
- Row Level Security habilitado
- Índices optimizados para rendimiento
- Triggers para contadores automáticos
- Vistas para consultas complejas

## 🎨 Interfaz de Usuario

### Diseño
- **Responsive Design** - Optimizado móvil-first
- **Progressive Enhancement** - Funciona sin JavaScript
- **Accesibilidad** - Contraste y navegación por teclado
- **Tema Visual** - Gradientes morados/azules (#667eea, #764ba2)

### Navegación
```
Home Screen
├── 📅 Agenda (implementada)
├── 📝 Registro (implementada)
├── 🗳️ Votación (implementada)
└── 🏷️ Etiquetas (implementada)
```

## ⚙️ Funcionalidades

### ✅ Implementadas
1. **Agenda del Congreso**
   - Vista de 3 días completos
   - Filtros por día
   - Información de sesiones, ponentes, ubicaciones
   - Tipos: keynote, charla, taller, descanso, networking

2. **Registro de Asistentes**
   - Formulario completo
   - Validación client-side
   - Almacenamiento en Supabase + localStorage fallback
   - Feedback visual al usuario

3. **Sistema de Votaciones Competitivo**
   - 4 ponencias en competencia
   - Sistema de puntuación: 5, 3, 2, 1 puntos
   - Validación de puntuaciones únicas (no se pueden repetir)
   - Selección múltiple con botón único de envío
   - Pantalla de confirmación post-voto
   - Actualización visual en tiempo real

4. **Pantalla de Resultados en Tiempo Real** ⭐ NUEVO
   - Acceso mediante parámetro URL: `?results` o `#results`
   - Auto-refresh cada 5 segundos sin parpadeo
   - Gráficos de barras animados con gradiente
   - Cálculo de porcentajes sobre total de puntos otorgados
   - Badge dorado animado "🏆 GANADOR" para primer lugar
   - Visualización de porcentajes siempre visible (dentro/fuera de barra según tamaño)
   - Distribución detallada de votos (5, 3, 2, 1 puntos)
   - Timestamp de última actualización
   - Optimizado para proyección en pantallas públicas

5. **Etiquetas e Ideas**
   - Input de texto libre
   - Almacenamiento híbrido
   - Display visual con colores

### 🔄 En Desarrollo
- Información detallada de ponentes
- Sistema de notificaciones push
- Mapas y ubicaciones del venue
- Networking entre asistentes
- Recursos descargables
- Encuestas de feedback
- PWA (Progressive Web App)
- Modo offline completo

## 🔧 Configuración Técnica

### Variables de Entorno (.env)
```env
SUPABASE_URL=tu_url_del_proyecto_aqui
SUPABASE_ANON_KEY=tu_clave_anonima_aqui
```

### Configuración Supabase (index.html:717-718)
```javascript
const supabaseUrl = 'your_supabase_project_url_here';
const supabaseKey = 'your_supabase_anon_key_here';
```

### Comandos de Desarrollo
```bash
# Servidor local con Python
python -m http.server 8000

# Servidor local con Node.js
npx serve .

# Servidor local con PHP
php -S localhost:8000
```

## 🔐 Seguridad

### Implementada
- Row Level Security en todas las tablas
- Políticas granulares de acceso
- Validación de entrada client-side
- Escapado de HTML para prevenir XSS

### Por Implementar
- Autenticación de usuarios
- Rate limiting
- Validación server-side
- Audit logging

## 📊 Rendimiento

### Optimizaciones Actuales
- Índices estratégicos en BD
- Lazy loading de datos
- Fallback a localStorage
- CSS/JS minificado en producción

### Métricas Objetivo
- First Contentful Paint < 2s
- Time to Interactive < 3s
- Lighthouse Score > 90

## 🧪 Testing

### Estrategia Actual
- Testing manual en múltiples dispositivos
- Verificación de funcionalidad offline
- Pruebas de fallback localStorage

### Por Implementar
- Unit tests (Jest)
- Integration tests
- E2E tests (Playwright)
- Performance testing

## 🚀 Deployment

### Opciones Recomendadas
1. **Vercel** - Deploy automático desde Git
2. **Netlify** - Con formularios integrados
3. **Supabase Hosting** - Todo en un ecosistema
4. **GitHub Pages** - Para pruebas rápidas

### Preparación para Producción
- [ ] Minificar CSS/JS
- [ ] Optimizar imágenes
- [ ] Configurar CDN
- [ ] SSL/HTTPS
- [ ] Monitoreo de errores

## 📱 Características Móviles

### Implementadas
- Viewport responsive
- Touch-friendly buttons (min 44px)
- Navegación por gestos
- Formularios móvil-optimizados

### Planificadas
- Service Worker para PWA
- Install prompt
- Offline notifications
- Background sync

## 🔄 Estado del Proyecto

### Completado (80%)
- ✅ Arquitectura base
- ✅ Esquema de base de datos
- ✅ UI/UX principal
- ✅ Funcionalidades core
- ✅ Integración Supabase

### En Progreso (15%)
- 🔄 Funcionalidades avanzadas
- 🔄 Testing
- 🔄 Optimización

### Pendiente (5%)
- ⏳ PWA setup
- ⏳ Deployment
- ⏳ Documentación final

## 📞 Información de Contacto

**Proyecto:** App del Congreso
**Desarrollado con:** Claude Code
**Última actualización:** 2025-10-09
**Versión:** 1.0.0-beta

---

*Esta documentación se actualiza automáticamente con cada cambio significativo al proyecto.*