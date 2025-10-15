#!/bin/bash
set -euo pipefail

# =================================================================
# SCRIPT: p08-gestion-usuarios-db.sh (VERSIÓN 3 - COMPATIBLE CON JPA)
#
# DESCRIPCIÓN:
#   Herramienta de línea de comandos para gestionar usuarios y roles
#   directamente en la base de datos PostgreSQL, adaptada para la
#   estructura Many-to-One creada por la aplicación Java (JPA).
# =================================================================

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\032'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- CONFIGURACIÓN ---
DB_NAME="transporte_db"
PG_USER="postgres"

# --- FUNCIÓN PARA EJECUTAR COMANDOS SQL ---
run_sql() {
    local query="$1"
    sudo -u "$PG_USER" psql -d "$DB_NAME" -c "$query"
}

# --- FUNCIONES DEL MENÚ ---

function list_users() {
    echo -e "\n${CYAN}--- Listando Usuarios ---${NC}"
    # CORRECCIÓN: La consulta ahora une directamente usuarios con roles a través de `rol_id`
    # y usa el nombre de columna correcto 'email'.
    local query="SELECT u.id, u.username, u.nombrecompleto, u.email, r.nombre AS rol FROM usuarios u JOIN roles r ON u.rol_id = r.id ORDER BY u.id;"
    run_sql "$query"
}

function list_roles() {
    echo -e "\n${CYAN}--- Listando Roles Disponibles ---${NC}"
    run_sql "SELECT id, nombre FROM roles ORDER BY id;"
}

function create_user() {
    echo -e "\n${CYAN}--- Creando Nuevo Usuario ---${NC}"
    read -p "Nombre de Usuario (username): " username
    read -p "Nombre Completo: " nombre
    read -p "Email: " email
    
    list_roles
    read -p "ID del Rol a asignar: " role_id
    
    # Validar que el rol existe
    local role_exists=$(sudo -u "$PG_USER" psql -d "$DB_NAME" -t -c "SELECT 1 FROM roles WHERE id = $role_id;" | tr -d '[:space:]')
    if [ "$role_exists" != "1" ]; then
        error "El ID de rol '$role_id' no es válido."
        return
    fi

    # Contraseña por defecto 'admin123' hasheada con BCrypt
    local hashed_pass='$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'

    log "Creando usuario '$username' con la contraseña 'admin123'..."
    # CORRECCIÓN: La sentencia INSERT ahora incluye `username`, `fecharegistro` y `rol_id`.
    local query="INSERT INTO usuarios (username, password, nombrecompleto, email, fecharegistro, rol_id) VALUES ('$username', '$hashed_pass', '$nombre', '$email', NOW(), $role_id);"
    run_sql "$query"
    log "¡Usuario creado exitosamente!"
}

function change_user_role() {
    echo -e "\n${CYAN}--- Cambiar Rol de un Usuario ---${NC}"
    list_users
    read -p "ID del Usuario a modificar: " user_id

    # Validar que el usuario existe
    local user_exists=$(sudo -u "$PG_USER" psql -d "$DB_NAME" -t -c "SELECT 1 FROM usuarios WHERE id = $user_id;" | tr -d '[:space:]')
    if [ "$user_exists" != "1" ]; then
        error "El ID de usuario '$user_id' no es válido."
        return
    fi
    
    list_roles
    read -p "ID del NUEVO Rol a asignar: " role_id

    # Validar que el rol existe
    local role_exists=$(sudo -u "$PG_USER" psql -d "$DB_NAME" -t -c "SELECT 1 FROM roles WHERE id = $role_id;" | tr -d '[:space:]')
    if [ "$role_exists" != "1" ]; then
        error "El ID de rol '$role_id' no es válido."
        return
    fi

    log "Cambiando el rol del usuario ID $user_id al rol ID $role_id..."
    # CORRECCIÓN: La operación ahora es un UPDATE en la columna `rol_id`.
    run_sql "UPDATE usuarios SET rol_id = $role_id WHERE id = $user_id;"
    log "¡Rol cambiado exitosamente!"
}


# --- MENÚ PRINCIPAL ---
while true; do
    echo -e "\n${YELLOW}===== GESTIÓN DE USUARIOS Y ROLES (BD - Compatible con JPA) =====${NC}"
    PS3=$'\n'"Selecciona una opción: "
    # CORRECCIÓN: Se actualizó el menú de opciones
    options=(
        "Listar todos los usuarios y su rol"
        "Listar roles disponibles"
        "Crear un nuevo usuario (contraseña: admin123)"
        "Cambiar el rol de un usuario"
        "Salir"
    )
    select opt in "${options[@]}"; do
        case $opt in
            "Listar todos los usuarios y su rol")
                list_users
                break
                ;;
            "Listar roles disponibles")
                list_roles
                break
                ;;
            "Crear un nuevo usuario (contraseña: admin123)")
                create_user
                break
                ;;
            "Cambiar el rol de un usuario")
                change_user_role
                break
                ;;
            "Salir")
                echo "Saliendo..."
                exit 0
                ;;
            *) echo "Opción inválida $REPLY";;
        esac
    done
done