#!/bin/bash

# p01-debian11-package-manager
# Este script automatiza la configuración del archivo /etc/apt/sources.list
# y limpia cualquier configuración de repositorio adicional para garantizar un estado limpio.
# ADVERTENCIA: Ejecutar este script requiere permisos de superusuario (sudo).

set -e # Termina el script inmediatamente si un comando falla.

echo "--- Configurando los repositorios de APT para Debian 11 (Bullseye) ---"

# 1. Verificar si el script se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Este script debe ser ejecutado con privilegios de root."
  echo "Por favor, ejecútalo usando: sudo ./p00-debian11-package-manager.sh"
  exit 1
fi

# 2. Crear una copia de seguridad del archivo original
echo "[PASO 1/4] Creando una copia de seguridad en /etc/apt/sources.list.bak..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 3. Sobrescribir el archivo sources.list con la nueva configuración
echo "[PASO 2/4] Escribiendo la nueva configuración en /etc/apt/sources.list..."
tee /etc/apt/sources.list > /dev/null <<'EOF'
# Repositorio principal de Debian 11 (Bullseye)
deb http://deb.debian.org/debian/ bullseye main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye main contrib non-free

# Actualizaciones de seguridad
deb http://security.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security/ bullseye-security main contrib non-free

# Actualizaciones importantes (point releases)
deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free
EOF

# ======================= NUEVO PASO AGREGADO =======================
# 4. Limpiar configuraciones de repositorios adicionales
echo "[PASO 3/4] Limpiando configuraciones antiguas de /etc/apt/sources.list.d/..."
# Esto elimina cualquier archivo .list residual (como los de Microsoft) que pueda causar conflictos.
# El -f (force) evita errores si el directorio ya está vacío.
rm -f /etc/apt/sources.list.d/*
# ===================================================================

# 5. Actualizar la lista de paquetes automáticamente
echo "[PASO 4/4] Actualizando la lista de paquetes  "
apt update

# 5. Actualizar la lista de paquetes automáticamente
echo "[PASO 4/4] instlacion tree  "
 
sudo apt install tree


echo ""
echo "--- ¡Configuración completada exitosamente! ---"
echo "El archivo /etc/apt/sources.list ha sido actualizado y los repositorios adicionales han sido limpiados."
echo "Se recomienda ejecutar 'sudo apt upgrade' para instalar las actualizaciones pendientes."