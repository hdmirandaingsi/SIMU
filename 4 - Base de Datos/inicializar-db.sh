#!/bin/bash
# inicializar-db.sh (VERSIÓN FINAL REVISADA)
#
# DESCRIPCIÓN:
#   Script AUTÓNOMO y VERIFICADO para inicializar la base de datos.
#   Este script crea la estructura de tablas con los nombres de columna EXACTOS
#   que JPA/EclipseLink genera por defecto a partir de las entidades Java.

set -e

# --- COLORES Y FUNCIONES DE LOG ---
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

# --- PASO 1: CONFIRMACIÓN Y EJECUCIÓN ---
header "Inicialización de la Base de Datos '$DB_NAME'"
warn "Se borrarán y recrearán todas las tablas de la aplicación."
read -p "Presiona Enter para continuar o Ctrl+C para cancelar..."

log "Aplicando esquema y datos iniciales..."

ADMIN_HASHED_PASS='$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'

sudo -u "$PG_USER" psql -v ON_ERROR_STOP=1 -d "$DB_NAME" <<EOF

-- =========== PASO 1: LIMPIAR TABLAS ANTERIORES ===========
\echo '--- Borrando tablas antiguas (si existen)...'
DROP TABLE IF EXISTS viajes CASCADE;
DROP TABLE IF EXISTS transacciones CASCADE;
DROP TABLE IF EXISTS tarjetas CASCADE;
DROP TABLE IF EXISTS ruta_parada CASCADE;
DROP TABLE IF EXISTS autobuses CASCADE;
DROP TABLE IF EXISTS rutas CASCADE;
DROP TABLE IF EXISTS paradas CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- =========== PASO 2: CREAR ESQUEMA DE TABLAS CORRECTO ===========
\echo '--- Creando estructura de tablas compatible con la aplicación Java...'

CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE usuarios (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    nombrecompleto VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    fecha_registro TIMESTAMP NOT NULL, -- VERIFICADO: Coincide con @Column(name = "fecha_registro")
    rol_id BIGINT NOT NULL,
    CONSTRAINT fk_usuario_rol FOREIGN KEY (rol_id) REFERENCES roles (id)
);

CREATE TABLE tarjetas (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL UNIQUE,
    saldo NUMERIC(10, 2) NOT NULL,
    fecha_creacion TIMESTAMP NOT NULL, -- VERIFICADO: Coincide con @Column(name = "fecha_creacion")
    CONSTRAINT fk_tarjeta_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
);

CREATE TABLE transacciones (
    id BIGSERIAL PRIMARY KEY,
    tarjeta_id BIGINT NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    monto NUMERIC(10, 2) NOT NULL,
    fecha TIMESTAMP NOT NULL,
    descripcion VARCHAR(255),
    CONSTRAINT fk_transaccion_tarjeta FOREIGN KEY (tarjeta_id) REFERENCES tarjetas (id) ON DELETE CASCADE
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
    CONSTRAINT fk_rp_ruta FOREIGN KEY (ruta_id) REFERENCES rutas (id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_parada FOREIGN KEY (parada_id) REFERENCES paradas (id) ON DELETE CASCADE
);

CREATE TABLE autobuses (
    id BIGSERIAL PRIMARY KEY,
    matricula VARCHAR(20) NOT NULL UNIQUE,
    capacidad INT NOT NULL,
    modelo VARCHAR(100),
    ruta_id BIGINT,
    CONSTRAINT fk_autobus_ruta FOREIGN KEY (ruta_id) REFERENCES rutas (id) ON DELETE SET NULL
);

CREATE TABLE viajes (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    ruta_id BIGINT,
    autobus_id BIGINT NOT NULL,
    fecha_hora TIMESTAMP NOT NULL, -- VERIFICADO: Coincide con @Column(name = "fecha_hora")
    costo_pasaje NUMERIC(10, 2) NOT NULL, -- VERIFICADO: Coincide con @Column(name = "costo_pasaje")
    CONSTRAINT fk_viaje_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
    CONSTRAINT fk_viaje_ruta FOREIGN KEY (ruta_id) REFERENCES rutas (id) ON DELETE SET NULL,
    CONSTRAINT fk_viaje_autobus FOREIGN KEY (autobus_id) REFERENCES autobuses (id) ON DELETE CASCADE
);

-- =========== PASO 3: INSERTAR DATOS INICIALES ===========
\echo '--- Insertando datos iniciales (Roles y usuario Administrador)...'

INSERT INTO roles (nombre) VALUES ('PASAJERO'), ('ADMINISTRADOR'), ('OPERADOR');

INSERT INTO usuarios (username, password, nombrecompleto, email, fecha_registro, rol_id)
VALUES (
    'admin',
    '${ADMIN_HASHED_PASS}',
    'Administrador del Sistema',
    'admin@simu.com',
    NOW(),
    (SELECT id FROM roles WHERE nombre = 'ADMINISTRADOR')
);

-- =========== PASO 4: ASIGNAR PERMISOS ===========
\echo '--- Asignando propiedad de las tablas al usuario de la aplicación (transporte_user)...'

-- Otorgar propiedad de todas las tablas en el esquema 'public'
DO $$
DECLARE
    tbl_name TEXT;
BEGIN
    FOR tbl_name IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    LOOP
        EXECUTE 'ALTER TABLE ' || quote_ident(tbl_name) || ' OWNER TO transporte_user;';
    END LOOP;
END $$;

-- Otorgar propiedad de todas las secuencias (para los IDs autoincrementales)
DO $$
DECLARE
    seq_name TEXT;
BEGIN
    FOR seq_name IN (SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public')
    LOOP
        EXECUTE 'ALTER SEQUENCE ' || quote_ident(seq_name) || ' OWNER TO transporte_user;';
    END LOOP;
END $$;

EOF

log "¡Proceso de inicialización completado!"
log "Usuario creado: admin / Contraseña: admin123"
header "La base de datos está lista para ser usada por la aplicación."