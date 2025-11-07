#!/bin/bash
# p07-fix-jpa-interferencia.sh
#
# PROPÓSITO:
#   Soluciona un problema específico de GlassFish 4.1 donde el servidor
#   interfiere con la inyección de DataSource para JDBC plano al intentar
#   auto-configurar JPA.
#
# SOLUCIÓN:
#   Crea un archivo 'persistence.xml' con una unidad de persistencia vacía.
#   Esto le indica a GlassFish que la persistencia ya está "manejada" y
#   desactiva su comportamiento automático, permitiendo que la inyección
#   del DataSource funcione correctamente.
#
# IDEMPOTENCIA:
#   Este script es seguro de ejecutar múltiples veces. Si el archivo
#   'persistence.xml' ya existe, no hará nada.

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header() { echo -e "\n${CYAN}--- $1 ---${NC}"; }

header "Aplicando corrección para interferencia de JPA en GlassFish 4.1"

# --- 1. CARGAR CONFIGURACIÓN DEL PROYECTO ---
log "Cargando configuración del entorno..."
PROJECT_ENV_FILE="$HOME/.project-env"
if [ ! -f "$PROJECT_ENV_FILE" ]; then
    error "No se encontró el archivo '~/.project-env'.\nAsegúrate de haber ejecutado los scripts de instalación previos."
fi
source "$PROJECT_ENV_FILE"

# Validar que la variable del directorio del proyecto se cargó
if [ -z "${PROJECT_DIR:-}" ] || [ ! -d "$PROJECT_DIR" ]; then
    error "La variable PROJECT_DIR no está definida o no es un directorio válido en '$PROJECT_ENV_FILE'."
fi

# --- 2. DEFINIR RUTAS Y VERIFICAR (IDEMPOTENCIA) ---
# Nos aseguramos de operar dentro del directorio del proyecto
cd "$PROJECT_DIR" || error "No se pudo cambiar al directorio del proyecto: $PROJECT_DIR"

META_INF_PATH="src/main/resources/META-INF"
PERSISTENCE_XML_FILE="$META_INF_PATH/persistence.xml"

log "Verificando si el archivo de configuración ya existe en: $PERSISTENCE_XML_FILE"

if [ -f "$PERSISTENCE_XML_FILE" ]; then
    log "✅ El archivo 'persistence.xml' ya existe. No se necesita ninguna acción."
    log "La corrección ya ha sido aplicada."
    exit 0
fi

# --- 3. CREAR EL ARCHIVO DE CONFIGURACIÓN ---
warn "El archivo 'persistence.xml' no fue encontrado. Procediendo a crearlo..."

# Crear el directorio si no existe (el -p es clave)
mkdir -p "$META_INF_PATH" || error "No se pudo crear el directorio: $META_INF_PATH"
log "Directorio '$META_INF_PATH' asegurado."

# Usar un 'heredoc' para escribir el contenido del archivo XML
cat > "$PERSISTENCE_XML_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<persistence version="2.1"
             xmlns="http://xmlns.jcp.org/xml/ns/persistence"
             xmlns:xsi="http://www.w.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/persistence http://xmlns.jcp.org/xml/ns/persistence/persistence_2_1.xsd">

    <!-- 
        Este archivo está intencionalmente casi vacío.
        Al definir una unidad de persistencia (incluso vacía), le decimos
        a GlassFish que no intente escanear y manejar entidades JPA
        automáticamente. Esto previene que interfiera con nuestra
        inyección de DataSource para JDBC plano y resuelve el problema
        de NullPointerException en los DAOs.
    -->
    <persistence-unit name="dummy-pu" transaction-type="JTA">
        <!-- No se especifican clases de entidad, proveedor, ni datasource -->
    </persistence-unit>

</persistence>
EOF

# Verificar que el archivo se creó correctamente
if [ -f "$PERSISTENCE_XML_FILE" ]; then
    log "✅ ¡Éxito! El archivo 'persistence.xml' ha sido creado correctamente."
else
    error "Falló la creación del archivo 'persistence.xml'. Verifica los permisos."
fi

# --- 4. INSTRUCCIONES FINALES ---
echo ""
log "================================================================"
log "🎉 ¡CORRECCIÓN APLICADA EXITOSAMENTE!"
log "================================================================"
warn "Para que este cambio surta efecto, debes reconstruir y"
warn "redesplegar tu aplicación."
echo ""
echo -e "   Ejecuta los siguientes comandos en este orden:"
echo -e "   1. ${YELLOW}./build.sh${NC}"
echo -e "   2. ${YELLOW}./deploy.sh${NC}"
echo ""
log "Después de redesplegar, el inicio de sesión debería funcionar."