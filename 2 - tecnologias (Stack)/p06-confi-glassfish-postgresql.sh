#!/bin/bash
# p06-confi-asadmin-glassfish.sh (MODIFICADO PARA POSTGRESQL)
# Configura el JDBC Connection Pool y JNDI Resource en GlassFish para PostgreSQL.

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- CARGAR CONFIGURACIÓN ---
PROJECT_ENV_FILE="$HOME/.project-env"
if [ ! -f "$PROJECT_ENV_FILE" ]; then error "No se encontró ~/.project-env."; fi
source "$PROJECT_ENV_FILE"

# === VARIABLES DE CONFIGURACIÓN (ADAPTADAS PARA POSTGRESQL) ===
ASADMIN="$GLASSFISH_HOME/bin/asadmin"
DOMAIN_NAME="domain1"
DB_JNDI="jdbc/miDB" # Mantenemos el nombre para compatibilidad con p07
DB_POOL="miPoolPostgreSQL" # Nombre más descriptivo
DB_USER="transporte_user"
DB_SERVER="localhost"
DB_NAME="transporte_db"
DB_PORT="5432"


# === PARÁMETROS DEL POOL DE CONEXIONES  ===
POOL_PING="true"                        # Habilita el 'Ping' para validar conexiones
POOL_STEADY_SIZE=8                      # Tamaño Inicial y Mínimo del Pool
POOL_MAX_SIZE=32                        # Tamaño Máximo del Pool
POOL_RESIZE_QUANTITY=2                  # Cantidad de Redimensionamiento del Pool
POOL_IDLE_TIMEOUT=300                   # Tiempo de Inactividad (segundos)
POOL_MAX_WAIT=60000                     # Tiempo Máximo de Espera (milisegundos)
# La opción "Guaranteed" en la UI significa que debemos establecer un nivel de aislamiento.
# 'read-committed' es un valor estándar y seguro.
POOL_TX_ISOLATION="read-committed"




SOURCE_DIR="/media/sf_CompartoVIRTUALBOX/SoftwarePRN315"
# ¡IMPORTANTE! Asegúrate de tener este archivo JAR en tu carpeta compartida
DRIVER_JAR_NAME="postgresql-42.2.5.jar"
DRIVER_SOURCE_PATH="$SOURCE_DIR/$DRIVER_JAR_NAME"
DRIVER_DEST_PATH="$GLASSFISH_HOME/glassfish/domains/$DOMAIN_NAME/lib/$DRIVER_JAR_NAME"

# === INSTALAR EL DRIVER JDBC DE POSTGRESQL ===
log "Verificando instalación del driver JDBC de PostgreSQL..."
if [ ! -f "$DRIVER_SOURCE_PATH" ]; then
    error "No se encontró el driver '$DRIVER_JAR_NAME' en '$SOURCE_DIR'."
fi

RESTART_REQUIRED=0
if [ ! -f "$DRIVER_DEST_PATH" ]; then
    log "Driver no encontrado. Copiándolo al dominio..."
    cp -v "$DRIVER_SOURCE_PATH" "$DRIVER_DEST_PATH"
    RESTART_REQUIRED=1
else
    log "✅ Driver JDBC de PostgreSQL ya está instalado."
fi


# === INSTALAR EL JAR DE PRIMEFACES EN EL DOMINIO (NUEVO PASO) ===
# =================================================================
log "Verificando instalación de PrimeFaces..."
PRIMEFACES_JAR_NAME="primefaces-8.0.jar"
PRIMEFACES_SOURCE_PATH="$SOURCE_DIR/$PRIMEFACES_JAR_NAME"
PRIMEFACES_DEST_PATH="$GLASSFISH_HOME/glassfish/domains/$DOMAIN_NAME/lib/$PRIMEFACES_JAR_NAME"

if [ ! -f "$PRIMEFACES_SOURCE_PATH" ]; then
    error "No se encontró el JAR de PrimeFaces '$PRIMEFACES_JAR_NAME' en '$SOURCE_DIR'."
fi

if [ ! -f "$PRIMEFACES_DEST_PATH" ]; then
    log "PrimeFaces no encontrado. Copiándolo al dominio..."
    cp -v "$PRIMEFACES_SOURCE_PATH" "$PRIMEFACES_DEST_PATH"
    RESTART_REQUIRED=1 # Forzar reinicio del servidor
else
    log "✅ PrimeFaces ya está instalado en el dominio."
fi




# === GESTIONAR ESTADO DEL DOMINIO ===
log "Gestionando estado del dominio: $DOMAIN_NAME"
# (El código para iniciar/reiniciar el dominio es idéntico)
if ! $ASADMIN list-domains | grep -q "^$DOMAIN_NAME running"; then
    $ASADMIN start-domain "$DOMAIN_NAME"; sleep 20;
elif [ "$RESTART_REQUIRED" -eq 1 ]; then
    $ASADMIN restart-domain "$DOMAIN_NAME"; sleep 20;
else
    log "✅ Dominio '$DOMAIN_NAME' ya está en ejecución."
fi

# === LIMPIEZA Y CREACIÓN DE RECURSOS JDBC (ADAPTADO) ===
log "🧹 Limpiando y creando configuraciones JDBC para PostgreSQL..."
$ASADMIN delete-jdbc-resource "$DB_JNDI" || true
$ASADMIN delete-jdbc-connection-pool "$DB_POOL" || true

# Para mantener la automatización, usamos la contraseña fija.
DB_PASS="Passw0rd123!"

log "🆕 Creando pool JDBC: $DB_POOL"
$ASADMIN create-jdbc-connection-pool \
    --restype javax.sql.DataSource \
    --datasourceclassname org.postgresql.ds.PGSimpleDataSource \
    --ping="$POOL_PING" \
    --steadypoolsize="$POOL_STEADY_SIZE" \
    --maxpoolsize="$POOL_MAX_SIZE" \
    --poolresize="$POOL_RESIZE_QUANTITY" \
    --idletimeout="$POOL_IDLE_TIMEOUT" \
    --maxwait="$POOL_MAX_WAIT" \
    --transactionisolationlevel="$POOL_TX_ISOLATION" \
    --property "user=${DB_USER}:password=${DB_PASS}:serverName=${DB_SERVER}:portNumber=${DB_PORT}:databaseName=${DB_NAME}" \
    "$DB_POOL"


log "🆕 Creando recurso JNDI: $DB_JNDI"
$ASADMIN create-jdbc-resource --poolname "$DB_POOL" "$DB_JNDI"

# === VERIFICACIÓN FINAL CON PING ===
log "🔬 Verificando la conexión a PostgreSQL con PING..."
$ASADMIN ping-connection-pool "$DB_POOL"
log "✅ ¡Ping al Connection Pool exitoso! La conexión a PostgreSQL funciona."

log "🎉 ¡CONFIGURACIÓN DE GLASSFISH COMPLETADA!"
