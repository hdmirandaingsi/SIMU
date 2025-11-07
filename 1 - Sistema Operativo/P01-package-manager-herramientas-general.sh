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


echo "--- Iniciando la instalación de Visual Studio Code ---"

# 1. Actualizar el índice de paquetes e instalar dependencias necesarias.
#    - apt-transport-https: permite usar repositorios sobre HTTPS.
#    - curl: para descargar archivos desde la línea de comandos.
#    - gpg: para manejar las llaves de seguridad de los repositorios.
echo "Paso 1: Actualizando paquetes e instalando dependencias..."
sudo apt-get update
sudo apt-get install -y apt-transport-https curl gpg

# 2. Descargar e importar la llave GPG de Microsoft.
#    Esto es un paso de seguridad para verificar que los paquetes son auténticos.
echo "Paso 2: Importando la llave GPG de Microsoft..."
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg

# 3. Añadir el repositorio oficial de Visual Studio Code a las fuentes de APT.
#    Se especifica que debe usar la llave importada en el paso anterior.
echo "Paso 3: Añadiendo el repositorio de VS Code..."
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

# 4. Actualizar nuevamente el índice de paquetes para incluir el nuevo repositorio
#    y finalmente instalar Visual Studio Code.
echo "Paso 4: Instalando Visual Studio Code..."
sudo apt-get update
sudo apt-get install -y code
sudo apt-get install curl
sudo apt-get install jq
echo "--- ¡Visual Studio Code se ha instalado correctamente! ---"
echo "Puedes ejecutarlo escribiendo 'code' en la terminal o buscándolo en tu menú de aplicaciones."
echo ""
echo "--- ¡Configuración completada exitosamente! ---"
echo "El archivo /etc/apt/sources.list ha sido actualizado y los repositorios adicionales han sido limpiados."
echo "Se recomienda ejecutar 'sudo apt upgrade' para instalar las actualizaciones pendientes."