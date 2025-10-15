#!/bin/bash
# p10-dev-mastery.sh
#
# USO AVANZADO Y EXCLUSIVO DEL SISTEMA DE ARCHIVOS /dev
#
# Este script demuestra técnicas avanzadas para interactuar con dispositivos
# virtuales en /dev, realizando tareas de benchmarking, criptografía,
# manipulación de datos y comunicación de red a bajo nivel.
#
# REQUISITOS: Ejecutar como root para acceso a ciertos dispositivos y
# para la creación de archivos en directorios protegidos.

set -euo pipefail

# --- VERIFICAR PERMISOS DE ROOT ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Este script debe ser ejecutado con privilegios de root." >&2
  exit 1
fi

# =============================================================================
# TÉCNICA 1: BENCHMARKING DE SISTEMA COMBINANDO DISPOSITIVOS
# Mide el rendimiento de la CPU en compresión y el I/O del disco.
# - /dev/zero: Fuente infinita de bytes nulos (datos de entrada).
# - /dev/null: El agujero negro (descarte de datos de salida).
# - /dev/sda (o similar): Dispositivo de bloque raw para I/O directo.
# =============================================================================
function system_benchmark {
    echo "--- 1. Benchmark de CPU y Disco usando /dev ---"
    
    # Mide la velocidad de la CPU para comprimir datos generados al vuelo.
    # El rendimiento aquí está limitado puramente por la velocidad del procesador.
    echo "Benchmarking CPU (compresión gzip)..."
    local cpu_speed=$(dd if=/dev/zero bs=1M count=1024 2>/dev/null | gzip -c | dd of=/dev/null 2>&1 | tail -n 1 | awk '{print $(NF-1) " " $NF}')
    echo "  Velocidad de compresión de CPU: $cpu_speed"

    # Mide la velocidad de escritura CRUDA del disco, saltando la caché del sistema.
    # Esto es mucho más preciso que un 'dd' normal para medir el rendimiento real del hardware.
    local main_disk=$(lsblk -d -o NAME,TYPE | grep 'disk' | head -n 1 | awk '{print $1}')
    echo "Benchmarking I/O de disco en /dev/$main_disk (escritura directa)..."
    # oflag=direct es la clave para saltar la caché del kernel (page cache).
    local disk_write_speed=$(dd if=/dev/zero of=/tmp/raw_disk_test bs=1M count=256 oflag=direct conv=fdatasync 2>&1 | tail -n 1 | awk '{print $(NF-1) " " $NF}')
    rm -f /tmp/raw_disk_test
    echo "  Velocidad de escritura directa en disco: $disk_write_speed"
    echo ""
}

# =============================================================================
# TÉCNICA 2: CRIPTOGRAFÍA Y GESTIÓN DE VOLÚMENES SEGUROS
# Crea un contenedor de archivos cifrado utilizando LUKS.
# - /dev/random: Fuente de aleatoriedad de alta calidad para claves.
# - /dev/urandom: Fuente de aleatoriedad más rápida para operaciones no críticas.
# - /dev/loopX: Dispositivos de bucle para montar archivos como si fueran discos.
# =============================================================================
function secure_volume_creation {
    echo "--- 2. Creación de Volumen Cifrado con /dev ---"
    local container_file="/tmp/secure_vault.img"
    local container_size_mb=128
    local mapped_name="crypted_vault"
    
    # 1. Crear un archivo contenedor vacío usando datos de /dev/zero.
    echo "Creando archivo contenedor de ${container_size_mb}MB..."
    dd if=/dev/zero of="$container_file" bs=1M count=$container_size_mb status=none

    # 2. Generar una clave criptográficamente segura desde /dev/random.
    # /dev/random puede bloquearse si no hay suficiente entropía, demostrando su calidad.
    echo "Generando clave segura desde /dev/random (esto puede tardar unos segundos)..."
    local key_file="/tmp/vault.key"
    head -c 64 /dev/random > "$key_file"
    echo "  Clave generada en $key_file."

    # 3. Formatear el contenedor como un volumen cifrado LUKS usando la clave.
    echo "Formateando contenedor con LUKS..."
    # --batch-mode evita prompts interactivos
    cryptsetup luksFormat "$container_file" "$key_file" --batch-mode

    # 4. Abrir el contenedor LUKS y mapearlo a un dispositivo virtual en /dev/mapper.
    echo "Mapeando el contenedor a /dev/mapper/$mapped_name..."
    cryptsetup luksOpen "$container_file" "$mapped_name" --key-file "$key_file"

    # 5. Formatear el dispositivo virtual con un sistema de archivos.
    echo "Creando sistema de archivos ext4 en el volumen cifrado..."
    mkfs.ext4 "/dev/mapper/$mapped_name" > /dev/null 2>&1

    echo "  ¡Éxito! Volumen cifrado disponible en /dev/mapper/$mapped_name."
    
    # Limpieza (el usuario puede montarlo si lo desea)
    echo "Cerrando el volumen cifrado para la limpieza..."
    cryptsetup luksClose "$mapped_name"
    rm -f "$container_file" "$key_file"
    echo "  Contenedor cerrado y archivos temporales eliminados."
    echo ""
}

# =============================================================================
# TÉCNICA 3: COMUNICACIÓN DE RED A BAJO NIVEL (RAW SOCKETS VIRTUALES)
# Establece una conexión TCP a un servidor HTTP y realiza una petición GET
# sin usar curl, wget o netcat, solo a través del dispositivo /dev/tcp de Bash.
# Esto demuestra el poder del shell para manejar protocolos de red directamente.
# =============================================================================
function low_level_network_communication {
    echo "--- 3. Petición HTTP a bajo nivel con /dev/tcp ---"
    local host="example.com"
    local port=80

    echo "Abriendo conexión TCP a $host:$port a través de un descriptor de archivo..."
    # 'exec' redirige el descriptor de archivo 3 a un socket TCP/IP.
    # El bloque <>/dev/tcp/... abre la conexión para lectura y escritura.
    # El 'timeout' evita que el script se cuelgue si la conexión no se establece.
    if ! timeout 5s exec 3<>/dev/tcp/$host/$port; then
        echo "  Error: No se pudo conectar a $host:$port." >&2
        return 1
    fi
    
    echo "Enviando cabeceras HTTP a través del descriptor de archivo 3..."
    # Escribimos una petición HTTP/1.1 directamente al socket.
    # El -e en echo interpreta los \r\n (CRLF) necesarios para HTTP.
    echo -e "GET / HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n" >&3

    echo "Leyendo respuesta del servidor (primeras 10 líneas)..."
    # Leemos la respuesta línea por línea desde el mismo descriptor de archivo.
    # 'timeout' evita que el script se cuelgue si el servidor no responde.
    timeout 5s cat <&3 | head -n 10 | sed 's/^/  /' || echo "  No se recibió respuesta completa o la conexión falló."

    # Cierra el descriptor de archivo, lo que a su vez cierra la conexión TCP.
    exec 3<&-
    exec 3>&-
    echo "  Conexión cerrada."
    echo ""
}

# =============================================================================
# TÉCNICA 4: MANIPULACIÓN DE TERMINALES VIRTUALES (TTY)
# Envía un mensaje a otra terminal del sistema.
# Útil para scripts de notificación o administración remota.
# - /dev/pts/X: Pseudo-terminales correspondientes a sesiones de shell activas.
# =============================================================================
function terminal_manipulation {
    echo "--- 4. Envío de mensajes entre terminales con /dev/pts ---"

    # Identificar otras terminales activas (excluyendo la actual).
    local current_tty=$(tty)
    # 'who' nos dice qué usuarios están en qué terminales.
    local other_ttys=$(who | awk '{print $2}' | grep -v "${current_tty##*/}" | sort -u)

    if [[ -z "$other_ttys" ]]; then
        echo "  No se encontraron otras terminales activas para enviar un mensaje."
        echo ""
        return
    fi

    local target_tty=$(echo "$other_ttys" | head -n 1)
    echo "Enviando un mensaje de prueba a la terminal /dev/$target_tty..."
    
    # Escribir directamente al dispositivo de la terminal hace que el mensaje aparezca allí.
    echo -e "\n\n*** Mensaje enviado desde el script p10-dev-mastery.sh en ($current_tty) ***\n" > "/dev/$target_tty"

    echo "  Mensaje enviado. Revisa la otra terminal."
    echo ""
}

# --- SCRIPT PRINCIPAL ---
main() {
    # Verificar si las herramientas necesarias están instaladas
    for cmd in dd gzip lsblk cryptsetup mkfs.ext4 who timeout; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: El comando '$cmd' es necesario pero no está instalado." >&2
            exit 1
        fi
    done

    system_benchmark
    secure_volume_creation
    low_level_network_communication
    terminal_manipulation

    echo "--- Demostración avanzada de /dev completada ---"
}

main