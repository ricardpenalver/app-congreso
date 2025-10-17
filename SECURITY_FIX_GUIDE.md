# 🔐 Guía de Solución de Problemas de Seguridad

## 🚨 Problema Detectado

Supabase detectó problemas de seguridad porque tienes **Row Level Security (RLS)** habilitado pero con políticas que requieren autenticación de usuarios, mientras que tu aplicación funciona de forma **anónima** (sin login).

## ✅ Solución Implementada

He creado el archivo `security_policies_fix.sql` que contiene políticas de seguridad adaptadas para acceso anónimo controlado.

## 📋 Pasos para Aplicar la Solución

### 1. Acceder a Supabase Dashboard

1. Ve a [https://app.supabase.com](https://app.supabase.com)
2. Selecciona tu proyecto
3. En el menú lateral, haz clic en **SQL Editor**

### 2. Ejecutar el Script de Corrección

1. Abre el archivo `security_policies_fix.sql`
2. Copia todo el contenido
3. Pégalo en el SQL Editor de Supabase
4. Haz clic en **RUN** (o presiona Ctrl/Cmd + Enter)

### 3. Verificar los Resultados

El script incluye consultas de verificación al final que mostrarán:

- ✅ Tablas con RLS habilitado
- ✅ Políticas activas en cada tabla
- ✅ Permisos configurados

## 🎯 Cambios Realizados

### Tablas Afectadas

| Tabla | Cambio Aplicado |
|-------|-----------------|
| `votes` | ✅ Lectura y escritura pública |
| `voting_topics` | ✅ Lectura pública (ya existía) |
| `tags` | ✅ Lectura y escritura pública |
| `ideas` | ✅ Lectura y escritura pública |
| `idea_votes` | ✅ Lectura y escritura pública |
| `sessions` | ✅ Lectura pública (ya existía) |
| `speakers` | ✅ Lectura pública (ya existía) |

### Políticas Creadas

**Votaciones:**
- `Anyone can view all votes` - Lectura pública
- `Anyone can create votes` - Escritura pública
- `Anyone can update votes` - Actualización pública

**Tags:**
- `Anyone can create tags` - Escritura pública

**Ideas:**
- `Anyone can create ideas` - Escritura pública
- `Anyone can update ideas` - Actualización pública

**Votos en Ideas:**
- `Anyone can create idea votes` - Escritura pública
- `Anyone can update idea votes` - Actualización pública

## ⚠️ Consideraciones de Seguridad

### ✅ Apropiado Para

- ✅ Aplicaciones de eventos públicos
- ✅ Votaciones abiertas
- ✅ Recopilación de ideas públicas
- ✅ Encuestas anónimas

### ❌ NO Apropiado Para

- ❌ Datos sensibles o privados
- ❌ Información personal identificable
- ❌ Sistemas con requisitos de auditoría estrictos
- ❌ Aplicaciones que requieren trazabilidad de usuarios

## 🛡️ Medidas de Protección Adicionales

### 1. Rate Limiting (ya implementado en el código)

El código actual usa `localStorage` para prevenir votos duplicados desde el mismo dispositivo.

### 2. Validación en el Frontend

```javascript
// Ya implementado en index.html
const hasVoted = localStorage.getItem('has_voted_topic_id');
if (hasVoted) {
    alert('Ya has votado en esta encuesta');
    return;
}
```

### 3. Monitoreo Recomendado

Considera implementar:
- **CAPTCHA** para prevenir bots
- **Rate limiting por IP** en Supabase Edge Functions
- **Logs de auditoría** para detectar abusos
- **Límites de tiempo** en votaciones (start_time/end_time)

## 🔄 Alternativa: Implementar Autenticación (Futuro)

Si en el futuro necesitas autenticación:

### Opción 1: Autenticación Social
```javascript
// Google, Facebook, etc.
const { user, error } = await supabase.auth.signInWithOAuth({
    provider: 'google'
});
```

### Opción 2: Autenticación con Email
```javascript
// Email + Password
const { user, error } = await supabase.auth.signUp({
    email: 'user@example.com',
    password: 'secure-password'
});
```

### Opción 3: Magic Links
```javascript
// Link de acceso enviado por email
const { error } = await supabase.auth.signInWithOtp({
    email: 'user@example.com'
});
```

## 📊 Testing

### Verificar que todo funciona

1. **Test de Lectura:**
```sql
SELECT * FROM sessions LIMIT 5;
```

2. **Test de Votación:**
```sql
INSERT INTO votes (voting_topic_id, selected_options)
VALUES ('tu-topic-id', '{"option": 0}');
```

3. **Test de Tags:**
```sql
INSERT INTO tags (name, description)
VALUES ('test-tag', 'Prueba de tag anónimo');
```

## 🆘 Soporte

### Si los problemas persisten

1. **Verifica RLS está habilitado:**
```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

2. **Verifica políticas activas:**
```sql
SELECT * FROM pg_policies
WHERE schemaname = 'public';
```

3. **Revisa logs en Supabase:**
   - Dashboard → Logs → API Logs
   - Busca errores 403 (Forbidden) o 401 (Unauthorized)

## 📝 Resumen

| Estado | Descripción |
|--------|-------------|
| ✅ **Archivo creado** | `security_policies_fix.sql` |
| 📋 **Acción requerida** | Ejecutar el SQL en Supabase Dashboard |
| ⏱️ **Tiempo estimado** | 2-3 minutos |
| 🎯 **Resultado** | Aplicación funcionando sin errores de seguridad |

---

**Última actualización:** 2025-10-17
**Versión:** 1.0.0
