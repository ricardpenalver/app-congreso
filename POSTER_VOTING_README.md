# 📊 Sistema de Votación de Posters

## 🎯 Descripción

Sistema completo de votación para posters del congreso que permite a los asistentes votar por hasta 3 posters, visualizar los resultados en tiempo real y ampliar las imágenes para ver más detalles.

## ✨ Características Principales

### Para Asistentes
- ✅ **Votación múltiple**: Cada usuario puede votar por hasta 3 posters
- ✅ **Interfaz visual atractiva**: Cards con miniaturas, títulos, autores y organizaciones
- ✅ **Vista previa ampliada**: Modal para ver imágenes en tamaño completo
- ✅ **Contador de votos**: Indicador visual de votos restantes
- ✅ **Prevención de votos duplicados**: Sistema de device fingerprinting
- ✅ **Confirmación visual**: Pantalla de confirmación con resumen de votos

### Para Administradores
- 📊 **Resultados en tiempo real**: Actualización automática cada 10 segundos
- 🏆 **Ranking visual**: Ordenado por número de votos con badge de ganador
- 📈 **Gráficos de barras**: Visualización de porcentajes
- 🔄 **Auto-refresh**: Actualización automática sin parpadeo
- 🌐 **Acceso público**: URL directa para proyección en pantallas

## 🗄️ Estructura de Base de Datos

### Tabla: `posters`
```sql
- id (UUID, PK)
- title (TEXT, NOT NULL)
- subtitle (TEXT)
- author_name (TEXT, NOT NULL)
- author_organization (TEXT)
- thumbnail_url (TEXT, NOT NULL)
- full_image_url (TEXT, NOT NULL)
- description (TEXT)
- display_order (INTEGER)
- is_active (BOOLEAN)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Tabla: `poster_votes`
```sql
- id (UUID, PK)
- attendee_id (UUID, FK -> attendees)
- poster_id (UUID, FK -> posters)
- device_fingerprint (TEXT)
- voted_at (TIMESTAMP)
```

### Vista: `public_poster_results`
```sql
SELECT
  p.id, p.title, p.subtitle, p.author_name,
  p.author_organization, p.thumbnail_url, p.display_order,
  COUNT(pv.id) as total_votes
FROM posters p
LEFT JOIN poster_votes pv ON p.id = pv.poster_id
WHERE p.is_active = true
GROUP BY p.id
ORDER BY total_votes DESC, p.display_order ASC
```

## 🔧 Instalación

### 1. Ejecutar el script SQL en Supabase

```bash
# Conectar a Supabase y ejecutar el script
psql -h <supabase-host> -U postgres -d postgres -f poster_voting_schema.sql
```

O desde el editor SQL de Supabase:
1. Ir a SQL Editor
2. Abrir el archivo `poster_voting_schema.sql`
3. Ejecutar el script completo

### 2. Configurar los datos de los posters

Los posters de ejemplo se pueden reemplazar ejecutando:

```sql
-- Eliminar datos de ejemplo
DELETE FROM posters WHERE author_name LIKE 'Autor%';

-- Insertar posters reales
INSERT INTO posters (title, subtitle, author_name, author_organization, thumbnail_url, full_image_url, description, display_order) VALUES
('Título Real del Poster 1', 'Subtítulo descriptivo', 'Nombre del Autor 1', 'Universidad ABC', 'https://tu-dominio.com/poster1-thumb.jpg', 'https://tu-dominio.com/poster1-full.jpg', 'Descripción completa del poster', 1),
('Título Real del Poster 2', 'Subtítulo descriptivo', 'Nombre del Autor 2', 'Universidad XYZ', 'https://tu-dominio.com/poster2-thumb.jpg', 'https://tu-dominio.com/poster2-full.jpg', 'Descripción completa del poster', 2);
-- ... más posters
```

### 3. Verificar que index.html está actualizado

El archivo `index.html` ya incluye todas las funcionalidades necesarias:
- ✅ Pantalla de votación de posters
- ✅ Pantalla de confirmación
- ✅ Pantalla de resultados
- ✅ Modal de ampliación de imágenes
- ✅ Estilos CSS completos
- ✅ JavaScript funcional

## 📱 Uso

### Para Asistentes

1. **Acceder a la votación**:
   - Desde el menú principal → "Votar Posters" 📊

2. **Seleccionar posters**:
   - Click en una card para votar/desvotarla
   - Máximo 3 votos permitidos
   - Las cards no seleccionables se desactivan cuando se alcanza el límite

3. **Ver detalles**:
   - Click en el icono 🔍 para ampliar la imagen
   - Ver título completo, subtítulo, autor, organización y descripción

4. **Enviar votos**:
   - Al seleccionar 3 posters, se muestra un diálogo de confirmación
   - Los votos se envían a Supabase
   - Se muestra pantalla de confirmación con resumen

5. **Restricciones**:
   - Cada dispositivo puede votar solo una vez
   - No se pueden cambiar los votos una vez enviados
   - Los votos se vinculan al device fingerprint

### Para Administradores

1. **Ver resultados en tiempo real**:
   - URL: `https://tu-dominio.com/?poster-results`
   - O: `https://tu-dominio.com/#poster-results`

2. **Proyectar en pantalla**:
   - Abrir la URL de resultados en modo pantalla completa (F11)
   - Los resultados se actualizan automáticamente cada 10 segundos
   - Sin parpadeo ni interrupciones visuales

3. **Actualizar manualmente**:
   - Click en el botón "🔄 Actualizar Resultados"

## 🎨 Personalización

### Cambiar el número máximo de votos

En `index.html`, línea ~3936:
```javascript
let posterVotingState = {
    selectedPosters: new Set(),
    maxVotes: 3, // Cambiar aquí (por ejemplo, a 5)
    allPosters: []
};
```

### Cambiar intervalo de auto-refresh

En `index.html`, línea ~4319:
```javascript
// Auto-refresh cada 10 segundos
setInterval(() => {
    loadPosterResults();
}, 10000); // Cambiar a 5000 para 5 segundos, 30000 para 30 segundos, etc.
```

### Personalizar colores

En `index.html`, variables CSS (líneas 12-25):
```css
--color-primary: #00D9C0;
--color-secondary: #006B7D;
/* Cambiar según la paleta de colores del evento */
```

## 🔐 Seguridad

### Row Level Security (RLS)

- ✅ **Tabla `posters`**: Solo lectura para usuarios, escritura solo para admins
- ✅ **Tabla `poster_votes`**: Inserción permitida, validación por triggers
- ✅ **Triggers de validación**: Máximo 3 votos por dispositivo
- ✅ **Constraints únicos**: Prevención de votos duplicados

### Validaciones implementadas

1. **Trigger `validate_max_poster_votes`**:
   - Verifica que no se exceda el límite de 3 votos por dispositivo
   - Se ejecuta antes de cada INSERT en `poster_votes`

2. **Constraints UNIQUE**:
   - `(attendee_id, poster_id)`: Previene votos duplicados por usuario autenticado
   - `(device_fingerprint, poster_id)`: Previene votos duplicados por dispositivo anónimo

3. **Device Fingerprinting**:
   - Genera un hash único basado en características del navegador
   - Almacenado en localStorage y usado para validar votos

## 📊 Consultas Útiles

### Ver todos los votos
```sql
SELECT
  p.title,
  COUNT(pv.id) as votos
FROM posters p
LEFT JOIN poster_votes pv ON p.id = pv.poster_id
WHERE p.is_active = true
GROUP BY p.id, p.title
ORDER BY votos DESC;
```

### Ver votos por dispositivo
```sql
SELECT
  device_fingerprint,
  COUNT(*) as total_votos
FROM poster_votes
WHERE device_fingerprint IS NOT NULL
GROUP BY device_fingerprint
ORDER BY total_votos DESC;
```

### Resetear votos (CUIDADO)
```sql
-- SOLO EN DESARROLLO O PARA REINICIAR VOTACIÓN
DELETE FROM poster_votes;
```

### Desactivar un poster
```sql
UPDATE posters
SET is_active = false
WHERE id = 'uuid-del-poster';
```

## 🐛 Troubleshooting

### Los posters no se cargan
1. Verificar conexión a Supabase en la consola del navegador
2. Verificar que la tabla `posters` existe y tiene datos
3. Verificar políticas RLS en Supabase

### No se pueden enviar votos
1. Verificar políticas RLS en `poster_votes`
2. Verificar que el trigger `validate_max_poster_votes` existe
3. Revisar errores en la consola del navegador

### Error "Maximum 3 votes reached"
1. El usuario ya votó por 3 posters desde ese dispositivo
2. Limpiar localStorage del navegador: `localStorage.clear()`
3. O eliminar los votos de ese dispositivo en la BD (solo desarrollo)

### Imágenes no se muestran
1. Verificar URLs en la tabla `posters`
2. Verificar que las imágenes son accesibles públicamente
3. Revisar CORS si están en un dominio diferente

## 📈 Métricas y Analytics

### KPIs recomendados
- Total de votos emitidos
- Número de dispositivos únicos que votaron
- Poster más votado
- Distribución de votos por poster
- Tasa de participación (votos / asistentes)

### Query para dashboard
```sql
SELECT
  (SELECT COUNT(*) FROM poster_votes) as total_votos,
  (SELECT COUNT(DISTINCT device_fingerprint) FROM poster_votes) as dispositivos_unicos,
  (SELECT COUNT(*) FROM posters WHERE is_active = true) as posters_activos,
  (SELECT title FROM public_poster_results LIMIT 1) as poster_ganador
```

## 🚀 Próximas Mejoras

- [ ] Autenticación de usuarios (Supabase Auth)
- [ ] Comentarios en posters
- [ ] Categorías de posters
- [ ] Filtros por categoría/autor
- [ ] Export de resultados a CSV/PDF
- [ ] Notificaciones push cuando se publica el ganador
- [ ] Galería de posters con búsqueda
- [ ] Modo offline con sincronización posterior

## 📞 Soporte

Para reportar bugs o solicitar features:
- Crear un issue en el repositorio
- Contactar al equipo de desarrollo

---

**Versión**: 1.0.0
**Última actualización**: 2025-10-21
**Compatibilidad**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
