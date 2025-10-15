#!/bin/bash
# p02-instalar-postgresql.sh
# Instala PostgreSQL 13+ en Debian 11 y crea un usuario y base de datos para la aplicación.
# Diseñado para ser idempotente: se puede ejecutar múltiples veces.
# ADVERTENCIA: Usa una contraseña fija para el usuario de la app. ¡No usar en producción!

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# =================================================================
# CONFIGURACIÓN DE POSTGRESQL
# =================================================================
DB_USER="transporte_user"
DB_PASS="Passw0rd123!" # ⚠️ Contraseña fija para desarrollo.
DB_NAME="transporte_db"

# =================================================================
# VERIFICAR PERMISOS DE ROOT
# =================================================================
if [ "$(id -u)" -ne 0 ]; then
    error "Este script debe ejecutarse como root. Usa: sudo ./p02-instalar-postgresql.sh"
fi

log "🚀 Iniciando instalación y configuración de PostgreSQL en Debian 11..."

# =================================================================
# INSTALAR POSTGRESQL (si no está instalado)
# =================================================================
if ! command -v psql &> /dev/null; then
    log "Instalando PostgreSQL y herramientas de cliente (psql)..."
    apt update
    apt install -y postgresql postgresql-contrib
    log "✅ PostgreSQL instalado."
else
    log "✅ PostgreSQL ya está instalado."
fi

# =================================================================
# ASEGURAR QUE EL SERVICIO ESTÉ ACTIVO
# =================================================================
log "Asegurando que el servicio de PostgreSQL esté activo y habilitado..."
systemctl start postgresql
systemctl enable postgresql

# =================================================================
# CREAR USUARIO Y BASE DE DATOS (IDEMPOTENTE)
# =================================================================
log "Configurando usuario '$DB_USER' y base de datos '$DB_NAME'..."

# Verificar si el usuario ya existe
if sudo -u postgres psql -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    log "✅ El usuario '$DB_USER' ya existe."
else
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
    log "✅ Usuario '$DB_USER' creado."
fi

# Verificar si la base de datos ya existe
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    log "✅ La base de datos '$DB_NAME' ya existe."
else
    # Crear la base de datos y asignarla al usuario creado
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
    log "✅ Base de datos '$DB_NAME' creada y asignada a '$DB_USER'."
fi

# =================================================================
# VERIFICAR CONEXIÓN Y ESTADO
# =================================================================
if ss -tuln | grep -q ':5432 '; then
    log "✅ PostgreSQL está escuchando en el puerto 5432."
else
    warn "⚠️ PostgreSQL no parece estar escuchando en el puerto 5432. Revisa los logs."
    warn "   Ejecuta: journalctl -u postgresql -n 50"
fi

log "🔍 Probando conexión a la base de datos con psql..."
# Usamos PGPASSWORD para evitar el prompt de contraseña
if PGPASSWORD="$DB_PASS" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null; then
    log "✅ Conexión exitosa a la base de datos '$DB_NAME' con el usuario '$DB_USER'."
else
    warn "⚠️ No se pudo conectar a la base de datos. Verifica:"
    warn "   - Contraseña para '$DB_USER'"
    warn "   - La configuración de autenticación en 'pg_hba.conf' (aunque la de Debian por defecto suele funcionar)"
fi

# =================================================================
# MENSAJE FINAL
# =================================================================
log ""
log "🎉 ¡PostgreSQL está listo para usar!"
log "   - Servidor: localhost"
log "   - Puerto: 5432"
log "   - Base de Datos: $DB_NAME"
log "   - Usuario: $DB_USER"
log "   - Contraseña: $DB_PASS"
log ""
log "💡 GlassFish podrá conectarse a esta instancia usando el driver JDBC de PostgreSQL."