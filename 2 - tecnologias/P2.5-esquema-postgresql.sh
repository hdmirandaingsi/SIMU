#!/bin/bash
# P2.5-esquema-postgresql.sh (VERSIÓN IDEMPOTENTE)
# Borra y recrea la estructura completa de tablas. Deja la base de datos limpia.

set -euo pipefail

# --- COLORES Y LOGS ---
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- CONFIGURACIÓN ---
DB_NAME="transporte_db"
DB_USER="transporte_user"
SCHEMA_FILE="/tmp/schema.sql"

# --- VERIFICAR ROOT ---
if [ "$(id -u)" -ne 0 ]; then
    error "Este script debe ejecutarse como root. Usa: sudo ./P2.5-esquema-postgresql.sh"
fi

log "Generando script SQL para BORRAR y RECREAR el esquema en $SCHEMA_FILE..."

# --- Inicio del bloque cat ---
cat > "$SCHEMA_FILE" << EOF
-- Script para crear el esquema de la base de datos "transporte_db"
-- Es idempotente: borra las tablas existentes antes de volver a crearlas.

DROP TABLE IF EXISTS viajes CASCADE;
DROP TABLE IF EXISTS transacciones CASCADE;
DROP TABLE IF EXISTS tarjetas CASCADE;
DROP TABLE IF EXISTS ruta_parada CASCADE;
DROP TABLE IF EXISTS autobuses CASCADE;
DROP TABLE IF EXISTS rutas CASCADE;
DROP TABLE IF EXISTS paradas CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS tarifas CASCADE;

CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE usuarios (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rol_id BIGINT NOT NULL,
    CONSTRAINT fk_rol FOREIGN KEY(rol_id) REFERENCES roles(id)
);

CREATE TABLE tarjetas (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL UNIQUE,
    saldo NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_tarjeta FOREIGN KEY(usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE TABLE transacciones (
    id BIGSERIAL PRIMARY KEY,
    tarjeta_id BIGINT NOT NULL,
    tipo_transaccion VARCHAR(50) NOT NULL,
    monto NUMERIC(10, 2) NOT NULL,
    fecha_transaccion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descripcion VARCHAR(255),
    CONSTRAINT fk_tarjeta_transaccion FOREIGN KEY(tarjeta_id) REFERENCES tarjetas(id)
);

CREATE TABLE paradas (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    latitud NUMERIC(10, 7),
    longitud NUMERIC(10, 7)
);

CREATE TABLE rutas (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE ruta_parada (
    ruta_id BIGINT NOT NULL,
    parada_id BIGINT NOT NULL,
    PRIMARY KEY (ruta_id, parada_id),
    CONSTRAINT fk_ruta FOREIGN KEY(ruta_id) REFERENCES rutas(id) ON DELETE CASCADE,
    CONSTRAINT fk_parada FOREIGN KEY(parada_id) REFERENCES paradas(id) ON DELETE CASCADE
);

CREATE TABLE autobuses (
    id BIGSERIAL PRIMARY KEY,
    matricula VARCHAR(20) NOT NULL UNIQUE,
    capacidad INTEGER NOT NULL,
    modelo VARCHAR(100),
    ruta_id BIGINT,
    CONSTRAINT fk_ruta_autobus FOREIGN KEY(ruta_id) REFERENCES rutas(id)
);

CREATE TABLE tarifas (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    precio NUMERIC(10, 2) NOT NULL
);

CREATE TABLE viajes (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    ruta_id BIGINT,
    autobus_id BIGINT NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    costo_pasaje NUMERIC(10, 2) NOT NULL,
    CONSTRAINT fk_usuario_viaje FOREIGN KEY(usuario_id) REFERENCES usuarios(id),
    CONSTRAINT fk_ruta_viaje FOREIGN KEY(ruta_id) REFERENCES rutas(id),
    CONSTRAINT fk_autobus_viaje FOREIGN KEY(autobus_id) REFERENCES autobuses(id)
);

-- === ASIGNACIÓN DE PERMISOS ===
GRANT ALL ON ALL TABLES IN SCHEMA public TO ${DB_USER};
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};

EOF
# --- Fin del bloque cat ---

sed -i "s|DB_USER_PLACEHOLDER|${DB_USER}|g" "$SCHEMA_FILE"

log "Ejecutando script SQL en la base de datos '$DB_NAME'..."
sudo -u postgres psql -d "$DB_NAME" -f "$SCHEMA_FILE"

log "✅ Esquema de base de datos limpio y recreado."

rm "$SCHEMA_FILE"
log "Limpiando archivo temporal."