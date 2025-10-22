# 🌐 Configuración Automática de Proxy

## 📋 Resumen

Este repositorio incluye un sistema de **configuración automática de proxy** que detecta la red en la que te encuentras y configura Git automáticamente.

## 🎯 Funcionamiento

### Detección Automática de Red

El script `.git-proxy-auto.sh` detecta automáticamente si estás en:

- **🏢 Red Corporativa** → Configura proxy: `http://proxy.espublico.it:8080`
- **🏠 Red Externa** (casa, WiFi público, etc.) → Conexión directa sin proxy

### Métodos de Detección

1. **Verificación de accesibilidad del proxy** → Intenta conectarse al proxy corporativo
2. **Verificación de gateway** → Comprueba si la puerta de enlace es la corporativa (`192.168.29.254`)

## 🔧 Integración con Cursor

Configurado en `.claude/settings.local.json`:

```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "./.git-proxy-auto.sh && git pull"
      }
    ]
  }
]
```

**Al iniciar Cursor:**
1. ✅ Detecta automáticamente tu red
2. ✅ Configura el proxy si es necesario
3. ✅ Ejecuta `git pull` para sincronizar

## 🚀 Uso Manual

### Ejecutar detección automática:
```bash
./.git-proxy-auto.sh
```

### Ver configuración actual del proxy:
```bash
git config --local --list | grep proxy
```

### Forzar proxy manualmente (si es necesario):
```bash
git config --local http.proxy http://proxy.espublico.it:8080
git config --local https.proxy http://proxy.espublico.it:8080
```

### Quitar proxy manualmente:
```bash
git config --local --unset http.proxy
git config --local --unset https.proxy
```

## 📁 Archivos de Configuración

| Archivo | Alcance | ¿Se sincroniza con Git? |
|---------|---------|------------------------|
| `.git-proxy-auto.sh` | Este proyecto | ✅ Sí (para compartir con el equipo) |
| `.claude/settings.local.json` | Solo tu equipo | ❌ No (en `.gitignore`) |
| `.git/config` (proxy) | Solo tu equipo | ❌ No (configuración local) |

## 🔐 Privacidad y Seguridad

- ✅ La configuración del proxy es **local** y no se sube a GitHub
- ✅ El script es **compartible** para que todo el equipo lo use
- ✅ Tus ajustes de Cursor son **privados** (`.gitignore`)

## 🏠 Trabajar desde Casa

**No necesitas hacer nada especial.** El script detectará automáticamente que no estás en la red corporativa y usará conexión directa.

## 🆘 Solución de Problemas

### Problema: Git no conecta desde la red corporativa
```bash
# Ejecuta manualmente el script
./.git-proxy-auto.sh

# Verifica que el proxy esté configurado
git config --local --list | grep proxy

# Prueba la conexión
git fetch origin --verbose
```

### Problema: Git no conecta desde casa
```bash
# Ejecuta el script para quitar el proxy
./.git-proxy-auto.sh

# Verifica que NO haya proxy configurado
git config --local --list | grep proxy
# (no debería mostrar nada)

# Prueba la conexión
git fetch origin --verbose
```

## 📞 Contacto

Si tienes problemas con la configuración del proxy, contacta con el equipo de IT.

---

*Última actualización: 22/10/2025*

