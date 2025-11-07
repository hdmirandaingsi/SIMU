#!/bin/bash
# =================================================================
# SCRIPT IDEMPOTENTE: CONFIGURACIÓN PERMANENTE DEL ENTORNO
# Propósito:
# 1. Carga la configuración desde ~/.project-env (creado por p02).
# 2. Verifica que la configuración es válida.
# 3. Añade la línea para cargar el entorno a ~/.bashrc SI NO EXISTE.
# Es seguro ejecutar este script múltiples veces.
# =================================================================
set -euo pipefail

# --- Colores y Funciones de Log ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Variables Principales ---
PROJECT_ENV_FILE="$HOME/.project-env"
BASHRC_FILE="$HOME/.bashrc"
# Línea exacta que buscaremos y añadiremos. Usar $HOME es más robusto.
CONFIG_LINE='source "$HOME/.project-env"'

# === 1. VERIFICAR QUE EL ARCHIVO DE ENTORNO EXISTE ===
log "🔎 Buscando archivo de entorno en: $PROJECT_ENV_FILE"
if [ ! -f "$PROJECT_ENV_FILE" ]; then
    error "❌ No se encontró el archivo '$PROJECT_ENV_FILE'.\n   Asegúrate de haber ejecutado primero el script de instalación (p02)."
fi
log "✅ Archivo de entorno encontrado."

# === 2. CARGAR Y VALIDAR EL ENTORNO ===
log "📦 Cargando y validando la configuración del proyecto..."
source "$PROJECT_ENV_FILE"

# Validar que las variables esenciales se cargaron y no están vacías
if [ -z "${PROJECT_NAME:-}" ] || [ -z "${JAVA_HOME:-}" ] || [ -z "${GLASSFISH_HOME:-}" ]; then
    error "❌ El archivo '$PROJECT_ENV_FILE' parece estar vacío o corrupto."
fi

# Validar que las rutas apuntan a directorios reales
if [ ! -d "$JAVA_HOME" ] || [ ! -f "$JAVA_HOME/bin/java" ]; then
    error "❌ La ruta JAVA_HOME en tu configuración no es válida o no contiene Java:\n   Valor actual: '$JAVA_HOME'"
fi

if [ ! -d "$GLASSFISH_HOME" ] || [ ! -f "$GLASSFISH_HOME/bin/asadmin" ]; then
    error "❌ La ruta GLASSFISH_HOME en tu configuración no es válida o no contiene asadmin:\n   Valor actual: '$GLASSFISH_HOME'"
fi

log "✅ Configuración cargada y validada para el proyecto: ${YELLOW}$PROJECT_NAME${NC}"
log "   - JAVA_HOME: $JAVA_HOME"
log "   - GLASSFISH_HOME: $GLASSFISH_HOME"

# === 3. CONFIGURAR ~/.bashrc DE FORMA IDEMPOTENTE ===
log "🔧 Verificando la configuración permanente en tu ~/.bashrc..."

# Usamos grep -qFx para una búsqueda silenciosa (-q), de cadena fija (-F) y de línea completa (-x)
if grep -qFx "$CONFIG_LINE" "$BASHRC_FILE"; then
    log "✅ Tu archivo ~/.bashrc ya está configurado correctamente. No se necesita hacer nada."
else
    warn "⚠️  Tu ~/.bashrc no carga el entorno del proyecto. Añadiendo la configuración..."
    
    # Añadimos la línea al final del archivo .bashrc
    echo -e "\n# Cargar entorno del proyecto (Añadido por p04-config-bashrc.sh)" >> "$BASHRC_FILE"
    echo "$CONFIG_LINE" >> "$BASHRC_FILE"
    
    log "✅ Línea de configuración añadida exitosamente a '$BASHRC_FILE'."
fi

# === 4. INSTRUCCIONES FINALES ===
echo ""
log "🎉 ¡Configuración completada con éxito!"
warn "Para que los cambios se apliquen en ${YELLOW}ESTA MISMA${NC} terminal, ejecuta el comando:"
echo -e "   ${YELLOW}source ~/.bashrc${NC}"
warn "Cualquier ${YELLOW}nueva terminal${NC} que abras ya tendrá el entorno cargado automáticamente."
