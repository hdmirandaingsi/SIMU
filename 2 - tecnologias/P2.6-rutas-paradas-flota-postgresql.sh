#!/bin/bash
# P2.6-rutas-paradas-flota-postgresql.sh
# Inserta datos de demostración en la base de datos.
# Es seguro ejecutarlo varias veces gracias a "ON CONFLICT".

set -euo pipefail

# --- COLORES Y LOGS ---
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- CONFIGURACIÓN ---
DB_NAME="transporte_db"
SEED_FILE="/tmp/seed_data.sql"

# --- VERIFICAR ROOT ---
if [ "$(id -u)" -ne 0 ]; then
    error "Este script debe ejecutarse como root. Usa: sudo ./P2.6-rutas-paradas-flota-postgresql.sh"
fi

log "Generando script SQL para poblar la base de datos en $SEED_FILE..."

# --- Inicio del bloque cat ---
cat > "$SEED_FILE" << EOF
-- === DATOS INICIALES Y DE DEMOSTRACIÓN ===

-- Insertar roles
INSERT INTO roles (nombre) VALUES ('ADMINISTRADOR'), ('PASAJERO')
ON CONFLICT (nombre) DO NOTHING;

-- Insertar usuario admin
INSERT INTO usuarios (username, password, nombre_completo, email, rol_id)
SELECT 'administrador', '\$2a\$10\$E5zJ4E7w/P1.G.3.D8h5UuW4yqJ5.P8.A6bC7oI5.eW9.A5.L9.zW', 'Administrador del Sistema', 'admin@sistema.com', id
FROM roles WHERE nombre = 'ADMINISTRADOR'
ON CONFLICT (username) DO NOTHING;

-- Insertar Rutas
INSERT INTO rutas (nombre, descripcion) VALUES
('R44', 'Recorrido San Salvador - Santa Tecla por Bulevar Constitución'),
('R5', 'Recorrido Colonia Escalón - Centro'),
('R101', 'Recorrido San Salvador - Aeropuerto Comalapa'),
('R42', 'Microbuses San Salvador - Mejicanos'),
('R11', 'Recorrido San Jacinto - Metrocentro'),
('R5-B', 'Recorrido Colonia San Benito - Centro')
ON CONFLICT (nombre) DO NOTHING;

-- Insertar Paradas
INSERT INTO paradas (nombre, latitud, longitud) VALUES
('Parada Constitución', 13.7145831, -89.2140131),
('Parada Salvador del Mundo', 13.700833, -89.225833),
('Parada Metrocentro', 13.7025, -89.208611),
('Parada Plaza Barrios', 13.698611, -89.191389),
('Parada San Jacinto', 13.689722, -89.186944),
('Parada Santa Tecla', 13.676944, -89.288889),
('Parada Aeropuerto', 13.441111, -89.055833),
('Parada Mejicanos', 13.733333, -89.2),
('Parada Colonia Escalón', 13.711389, -89.239167),
('Parada San Benito', 13.691389, -89.243333);

-- Asignar Paradas a Rutas
WITH r44 AS (SELECT id FROM rutas WHERE nombre = 'R44'), p_const AS (SELECT id FROM paradas WHERE nombre = 'Parada Constitución'), p_salvador AS (SELECT id FROM paradas WHERE nombre = 'Parada Salvador del Mundo'), p_tecla AS (SELECT id FROM paradas WHERE nombre = 'Parada Santa Tecla')
INSERT INTO ruta_parada (ruta_id, parada_id) VALUES ((SELECT id FROM r44), (SELECT id FROM p_const)), ((SELECT id FROM r44), (SELECT id FROM p_salvador)), ((SELECT id FROM r44), (SELECT id FROM p_tecla)) ON CONFLICT DO NOTHING;
WITH r5 AS (SELECT id FROM rutas WHERE nombre = 'R5'), p_escalon AS (SELECT id FROM paradas WHERE nombre = 'Parada Colonia Escalón'), p_salvador AS (SELECT id FROM paradas WHERE nombre = 'Parada Salvador del Mundo'), p_barrios AS (SELECT id FROM paradas WHERE nombre = 'Parada Plaza Barrios')
INSERT INTO ruta_parada (ruta_id, parada_id) VALUES ((SELECT id FROM r5), (SELECT id FROM p_escalon)), ((SELECT id FROM r5), (SELECT id FROM p_salvador)), ((SELECT id FROM r5), (SELECT id FROM p_barrios)) ON CONFLICT DO NOTHING;
WITH r101 AS (SELECT id FROM rutas WHERE nombre = 'R101'), p_metro AS (SELECT id FROM paradas WHERE nombre = 'Parada Metrocentro'), p_aero AS (SELECT id FROM paradas WHERE nombre = 'Parada Aeropuerto')
INSERT INTO ruta_parada (ruta_id, parada_id) VALUES ((SELECT id FROM r101), (SELECT id FROM p_metro)), ((SELECT id FROM r101), (SELECT id FROM p_aero)) ON CONFLICT DO NOTHING;

-- Insertar Autobuses
INSERT INTO autobuses (matricula, modelo, capacidad, ruta_id) VALUES
('AB12-345', 'Yutong ZK6122H9', 55, (SELECT id FROM rutas WHERE nombre = 'R44')),
('MB34-567', 'Yutong ZK6122H9', 55, (SELECT id FROM rutas WHERE nombre = 'R44')),
('P78-901', 'Mercedes-Benz Marco Polo', 48, (SELECT id FROM rutas WHERE nombre = 'R101')),
('N56-789', 'Hyundai County', 29, (SELECT id FROM rutas WHERE nombre = 'R42')),
('A11-223', 'Toyota Coaster', 30, (SELECT id FROM rutas WHERE nombre = 'R11')),
('MB99-887', 'Yutong ZK6852HG', 35, (SELECT id FROM rutas WHERE nombre = 'R5'))
ON CONFLICT (matricula) DO NOTHING;

-- Insertar usuarios pasajeros
INSERT INTO usuarios (username, password, nombre_completo, email, rol_id) SELECT 'juanperez', '\$2a\$10\$E5zJ4E7w/P1.G.3.D8h5UuW4yqJ5.P8.A6bC7oI5.eW9.A5.L9.zW', 'Juan Pérez', 'juan.perez@email.com', id FROM roles WHERE nombre = 'PASAJERO' ON CONFLICT (username) DO NOTHING;
INSERT INTO usuarios (username, password, nombre_completo, email, rol_id) SELECT 'mariagomez', '\$2a\$10\$E5zJ4E7w/P1.G.3.D8h5UuW4yqJ5.P8.A6bC7oI5.eW9.A5.L9.zW', 'Maria Gómez', 'maria.gomez@email.com', id FROM roles WHERE nombre = 'PASAJERO' ON CONFLICT (username) DO NOTHING;
INSERT INTO usuarios (username, password, nombre_completo, email, rol_id) SELECT 'carloslopez', '\$2a\$10\$E5zJ4E7w/P1.G.3.D8h5UuW4yqJ5.P8.A6bC7oI5.eW9.A5.L9.zW', 'Carlos López', 'carlos.lopez@email.com', id FROM roles WHERE nombre = 'PASAJERO' ON CONFLICT (username) DO NOTHING;
INSERT INTO usuarios (username, password, nombre_completo, email, rol_id) SELECT 'anarodriguez', '\$2a\$10\$E5zJ4E7w/P1.G.3.D8h5UuW4yqJ5.P8.A6bC7oI5.eW9.A5.L9.zW', 'Ana Rodriguez', 'ana.rodriguez@email.com', id FROM roles WHERE nombre = 'PASAJERO' ON CONFLICT (username) DO NOTHING;
INSERT INTO usuarios (username, password, nombre_completo, email, rol_id) SELECT 'pedromartinez', '\$2a\$10\$E5zJ4E7w/P1.G.3.D8h5UuW4yqJ5.P8.A6bC7oI5.eW9.A5.L9.zW', 'Pedro Martinez', 'pedro.martinez@email.com', id FROM roles WHERE nombre = 'PASAJERO' ON CONFLICT (username) DO NOTHING;
INSERT INTO usuarios (username, password, nombre_completo, email, rol_id) SELECT 'lauragarcia', '\$2a\$10\$E5zJ4E7w/P1.G.3.D8h5UuW4yqJ5.P8.A6bC7oI5.eW9.A5.L9.zW', 'Laura Garcia', 'laura.garcia@email.com', id FROM roles WHERE nombre = 'PASAJERO' ON CONFLICT (username) DO NOTHING;

-- Crear tarjetas para los pasajeros
INSERT INTO tarjetas (usuario_id, saldo) SELECT id, 10.00 FROM usuarios WHERE rol_id = (SELECT id FROM roles WHERE nombre = 'PASAJERO') ON CONFLICT (usuario_id) DO NOTHING;

EOF
# --- Fin del bloque cat ---

log "Poblando la base de datos '$DB_NAME' con datos de demostración..."
sudo -u postgres psql -d "$DB_NAME" -f "$SEED_FILE"

log "✅ Base de datos poblada con datos de demostración."

rm "$SEED_FILE"
log "Limpiando archivo temporal."