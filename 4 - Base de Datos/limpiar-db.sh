#!/bin/bash
# limpiar-db.sh
# Borra y recrea el esquema 'public' de la base de datos para forzar una
# reinstalación limpia del esquema por parte de JPA.

set -e

DB_NAME="transporte_db"
DB_USER="transporte_user"

echo "INFO: Limpiando completamente la base de datos '$DB_NAME'..."

sudo -u postgres psql -d "$DB_NAME" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO $DB_USER;"

echo "OK: Base de datos '$DB_NAME' limpiada y lista para un nuevo despliegue."