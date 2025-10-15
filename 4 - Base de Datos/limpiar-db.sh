#!/bin/bash
# limpiar-db.sh
#
# DESCRIPCIÓN:
#   Limpia TODOS los datos de las tablas de la aplicación en la base de datos,
#   pero DEJA LA ESTRUCTURA (columnas, tipos, etc.) INTACTA.
#   Utiliza el comando TRUNCATE para un borrado rápido y eficiente, y
#   reinicia los contadores de ID.
#
# USO:
#   Ideal para cuando quieres empezar a probar con datos frescos sin tener
#   que pasar por todo el proceso de inicialización de nuevo.

set -e # Termina el script si un comando falla

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\032'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
header() { echo -e "\n${CYAN}====== $1 ======${NC}"; }

# --- CONFIGURACIÓN ---
DB_NAME="transporte_db"
PG_USER="postgres"

# --- PASO 1: CONFIRMACIÓN DEL USUARIO ---
header "Limpieza de Datos de la Base de Datos '$DB_NAME'"
warn "Esta acción borrará TODOS LOS DATOS (usuarios, rutas, viajes, etc.) de las tablas."
warn "La estructura de las tablas NO será eliminada. Los IDs se reiniciarán."
read -p "Presiona Enter para continuar o Ctrl+C para cancelar..."

# --- PASO 2: EJECUTAR COMANDO TRUNCATE ---
log "Iniciando limpieza de datos..."

# Usamos un bloque "here document" para pasar el comando SQL a psql
# TRUNCATE ... RESTART IDENTITY CASCADE;
# - TRUNCATE: Borra todas las filas de las tablas especificadas.
# - RESTART IDENTITY: Reinicia las secuencias de ID (para que los nuevos registros empiecen en 1).
# - CASCADE: Trunca también las tablas que tienen claves foráneas a las tablas listadas.
sudo -u "$PG_USER" psql -d "$DB_NAME" <<EOF
\set QUIET on
TRUNCATE
    roles,
    usuarios,
    tarjetas,
    transacciones,
    paradas,
    rutas,
    autobuses,
    viajes,
    ruta_parada
RESTART IDENTITY CASCADE;
\set QUIET off
EOF

log "¡Limpieza de datos completada!"
warn "Recuerda que ahora la base de datos está vacía. Necesitarás insertar datos iniciales (como los roles y el usuario admin) si quieres que la aplicación funcione."
warn "Puedes usar 'p00-inicializar-db.sh' para un reseteo completo, o insertar los datos manualmente."

header "¡BASE DE DATOS LIMPIA!"