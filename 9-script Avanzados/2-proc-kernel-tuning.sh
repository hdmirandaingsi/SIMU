#!/bin/bash
# p11-proc-mastery.sh
#
# USO AVANZADO Y EXCLUSIVO DEL SISTEMA DE ARCHIVOS /proc
#
# Este script realiza un análisis forense en tiempo real de los procesos
# del sistema, calculando métricas de rendimiento complejas, decodificando
# estados de red de bajo nivel y extrayendo información sensible directamente
# de la memoria del kernel tal como se expone en /proc.
#
# REQUISITOS: Ejecutar como root para un acceso completo y para interactuar
# con parámetros del kernel en /proc/sys.

set -euo pipefail

# --- VERIFICAR PERMISOS DE ROOT ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Este script debe ser ejecutado con privilegios de root." >&2
  exit 1
fi

# =============================================================================
# TÉCNICA 1: ANÁLISIS PROFUNDO Y CÁLCULO DE MÉTRICAS DE PROCESOS
# Extrae y calcula datos de rendimiento que no están disponibles directamente.
# - /proc/[PID]/stat: Datos crudos de tiempo de CPU.
# - /proc/uptime: Tiempo de actividad del sistema para cálculos de %.
# - /proc/[PID]/status: Información detallada de memoria.
# - /proc/[PID]/environ: Variables de entorno del proceso en vivo.
# =============================================================================
function deep_process_analysis {
    local process_name=$1
    echo "--- 1. Análisis Forense del Proceso: '$process_name' ---"
    
    local pid=$(pgrep -f "$process_name" | head -n 1)
    if [[ -z "$pid" ]]; then
        echo "  Proceso '$process_name' no encontrado." >&2
        echo ""
        return
    fi
    echo "  Proceso encontrado con PID: $pid"

    local proc_dir="/proc/$pid"

    # 1a. Cálculo de uso de CPU en tiempo real (Técnica Avanzada).
    echo "  Calculando uso de CPU en vivo (intervalo de 1 seg)..."
    local stat1=($(cat "$proc_dir/stat"))
    local uptime1=$(awk '{print $1}' /proc/uptime)
    sleep 1
    local stat2=($(cat "$proc_dir/stat"))
    local uptime2=$(awk '{print $1}' /proc/uptime)
    
    # Campos 14 (utime) y 15 (stime) del fichero /stat
    local utime_diff=$(( ${stat2[13]} - ${stat1[13]} ))
    local stime_diff=$(( ${stat2[14]} - ${stat1[14]} ))
    local total_time_diff=$(( utime_diff + stime_diff ))
    local uptime_diff=$(echo "$uptime2 - $uptime1" | bc)
    local clk_tck=$(getconf CLK_TCK)
    local cpu_usage=$(echo "scale=2; 100 * ($total_time_diff / $clk_tck) / $uptime_diff" | bc)
    echo "    Uso de CPU actual: $cpu_usage %"

    # 1b. Desglose detallado de la memoria desde /proc/[PID]/status.
    echo "  Desglose del uso de memoria..."
    # Usamos awk para extraer y formatear múltiples valores a la vez.
    awk '
        /VmPeak|VmSize|VmRSS|VmData/ {
            printf "    - %-15s %s %s\n", $1, $2, $3
        }
    ' "$proc_dir/status"

    # 1c. Inspección de los descriptores de archivo abiertos.
    local fd_count=$(ls -1 "$proc_dir/fd" | wc -l)
    echo "  Número de descriptores de archivo abiertos: $fd_count"

    # 1d. Extracción del entorno del proceso en ejecución.
    # /proc/[PID]/environ es una cadena separada por nulos, 'tr' lo hace legible.
    echo "  Primeras 5 variables de entorno del proceso en vivo:"
    tr '\0' '\n' < "$proc_dir/environ" | head -n 5 | sed 's/^/    - /' || echo "    (No se pudo leer el entorno)"
    echo ""
}

# =============================================================================
# TÉCNICA 2: DECODIFICACIÓN DE CONEXIONES DE RED DE BAJO NIVEL
# Lee y decodifica el archivo /proc/net/tcp para mostrar conexiones activas
# sin usar herramientas de alto nivel como 'netstat' o 'ss'.
# =============================================================================
function low_level_network_decoding {
    echo "--- 2. Decodificación de Conexiones TCP desde /proc/net/tcp ---"
    
    echo "  Formato: [Dirección Local:Puerto] -> [Dirección Remota:Puerto] (Estado)"
    # Leer el archivo, saltar la cabecera, y usar awk para la magia de decodificación.
    awk '
    function hex_to_dec(h) { return sprintf("%d", "0x" h) }
    function hex_to_ip(h) {
        return hex_to_dec(substr(h,7,2)) "." \
               hex_to_dec(substr(h,5,2)) "." \
               hex_to_dec(substr(h,3,2)) "." \
               hex_to_dec(substr(h,1,2))
    }
    NR > 1 {
        split($2, local, ":");
        split($3, remote, ":");
        states["01"]="ESTABLISHED"; states["0A"]="LISTEN";
        
        local_ip = hex_to_ip(local[1]);
        local_port = hex_to_dec(local[2]);
        remote_ip = hex_to_ip(remote[1]);
        remote_port = hex_to_dec(remote[2]);
        state = states[$4] ? states[$4] : "UNKNOWN(" $4 ")";

        printf("  - [%s:%d] -> [%s:%d] (%s)\n", local_ip, local_port, remote_ip, remote_port, state);
    }
    ' /proc/net/tcp | head -n 10
    echo ""
}

# =============================================================================
# TÉCNICA 3: INTERACCIÓN DIRECTA CON EL KERNEL
# Escribir en archivos de /proc/sys para modificar el comportamiento del kernel
# en tiempo real.
# - /proc/sys/vm/drop_caches: Liberar la caché de memoria del sistema.
# - /proc/loadavg: Carga media del sistema.
# =============================================================================
function kernel_interaction {
    echo "--- 3. Interacción en Vivo con el Kernel vía /proc/sys ---"

    echo "  Analizando caché de memoria antes de la limpieza..."
    # Extraer la memoria en caché y los buffers de /proc/meminfo.
    local mem_before=$(awk '/^Cached:|^Buffers:/ {sum += $2} END {print sum}' /proc/meminfo)

    echo "  Enviando señal para liberar la pagecache, dentries e inodes..."
    # Escribir '3' es la operación de limpieza más agresiva.
    # 'sync' asegura que todos los datos en buffer se escriban a disco primero.
    sync
    echo 3 > /proc/sys/vm/drop_caches

    local mem_after=$(awk '/^Cached:|^Buffers:/ {sum += $2} END {print sum}' /proc/meminfo)
    local mem_freed=$(( (mem_before - mem_after) / 1024 ))
    echo "    Memoria liberada: $mem_freed MB"

    echo "  Leyendo la carga media del sistema desde /proc/loadavg..."
    local load_avg=$(awk '{printf "1min: %s, 5min: %s, 15min: %s", $1, $2, $3}' /proc/loadavg)
    echo "    $load_avg"
    echo ""
}


# --- SCRIPT PRINCIPAL ---
main() {
    # Verificar si las herramientas necesarias están instaladas
    for cmd in pgrep bc awk getconf; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: El comando '$cmd' es necesario pero no está instalado." >&2
            exit 1
        fi
    done
    
    # Simular la búsqueda de los procesos de tu stack de aplicación
    deep_process_analysis "glassfish"
    deep_process_analysis "postgres"

    low_level_network_decoding
    kernel_interaction

    echo "--- Demostración avanzada de /proc completada ---"
}

main