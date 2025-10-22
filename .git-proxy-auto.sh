#!/bin/bash
# Script para configurar automáticamente el proxy de Git según la red

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuración del proxy corporativo
PROXY_HOST="proxy.espublico.it"
PROXY_PORT="8080"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

# Función para detectar si estamos en la red corporativa
is_corporate_network() {
    # Método 1: Verificar si el proxy es accesible
    if nc -z -w 2 $PROXY_HOST $PROXY_PORT 2>/dev/null; then
        return 0
    fi
    
    # Método 2: Verificar la gateway (red corporativa usa 192.168.29.254)
    GATEWAY=$(netstat -rn | grep default | grep -v "fe80" | head -1 | awk '{print $2}')
    if [[ "$GATEWAY" == "192.168.29.254" ]]; then
        return 0
    fi
    
    return 1
}

# Función para configurar el proxy
configure_proxy() {
    git config --local http.proxy "$PROXY_URL"
    git config --local https.proxy "$PROXY_URL"
    echo -e "${GREEN}✅ Proxy configurado: $PROXY_URL${NC}"
}

# Función para quitar el proxy
remove_proxy() {
    git config --local --unset http.proxy 2>/dev/null
    git config --local --unset https.proxy 2>/dev/null
    echo -e "${GREEN}✅ Proxy deshabilitado (conexión directa)${NC}"
}

# Detectar y configurar automáticamente
if is_corporate_network; then
    echo -e "${YELLOW}🏢 Red corporativa detectada${NC}"
    configure_proxy
else
    echo -e "${YELLOW}🏠 Red externa detectada${NC}"
    remove_proxy
fi

