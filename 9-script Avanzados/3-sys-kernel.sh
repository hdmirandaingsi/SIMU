#!/bin/bash
# p12-sys-mastery.sh
#
# USO AVANZADO Y EXCLUSIVO DEL SISTEMA DE ARCHIVOS /sys
#
# Este script demuestra la manipulación directa de los subsistemas del kernel
# y los drivers de dispositivos a través de /sys. Realiza diagnósticos de
# hardware, afinamiento de rendimiento en vivo y control de bajo nivel que
# normalmente requerirían herramientas especializadas o reinicios del sistema.
#
# REQUISITOS: Ejecutar como root para modificar parámetros del kernel.

set -euo pipefail

# --- VERIFICAR PERMISOS DE ROOT ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Este script debe ser ejecutado con privilegios de root." >&2
  exit 1
fi

# --- GESTIÓN DE ESTADO Y LIMPIEZA ---
declare -A ORIGINAL_STATES
function cleanup {
    echo -e "\n--- Restaurando estados originales del kernel ---"
    for path in "${!ORIGINAL_STATES[@]}"; do
        local value="${ORIGINAL_STATES[$path]}"
        if [[ -f "$path" ]]; then
            echo "$value" > "$path" 2>/dev/null && echo "  Restaurado: $path -> $value"
        fi
    done
    echo "--- Sistema restaurado. Saliendo. ---"
}
trap cleanup EXIT INT TERM

# Función para guardar y modificar un parámetro de forma segura
function tune_parameter {
    local path="$1"
    local new_value="$2"
    local description="$3"

    if [[ ! -f "$path" ]]; then
        echo "  Parámetro no encontrado: $path. Saltando."
        return
    fi
    
    local current_value=$(cat "$path")
    echo "$description"
    echo "  - Ruta: $path"
    echo "  - Valor Actual: $current_value"
    
    # Guardar solo si no lo hemos guardado antes
    if [[ -z "${ORIGINAL_STATES[$path]+_}" ]]; then
        ORIGINAL_STATES["$path"]="$current_value"
    fi

    if [[ "$current_value" != "$new_value" ]]; then
        echo "  - ACCIÓN: Cambiando valor a -> $new_value"
        echo "$new_value" > "$path"
    else
        echo "  - El valor ya es el óptimo. No se requiere acción."
    fi
    echo ""
}

# =============================================================================
# TÉCNICA 1: CONTROL DE ENERGÍA Y RENDIMIENTO DE LA CPU
# Manipula directamente el driver cpufreq para forzar estados de rendimiento.
# - /sys/devices/system/cpu/cpufreq/policy*/...
# =============================================================================
function cpu_performance_tuning {
    echo "--- 1. Control de Rendimiento de CPU vía /sys ---"
    local governor_files=$(find /sys/devices/system/cpu/cpufreq/ -name "scaling_governor")
    for file in $governor_files; do
        tune_parameter "$file" "performance" "Ajustando CPU Governor para máxima velocidad"
    done
}

# =============================================================================
# TÉCNICA 2: AFINAMIENTO DEL PLANIFICADOR DE I/O DEL DISCO
# Modifica el scheduler de I/O basado en el tipo de disco (SSD vs HDD).
# - /sys/block/[device]/queue/scheduler
# - /sys/block/[device]/queue/rotational
# =============================================================================
function disk_io_scheduler_tuning {
    echo "--- 2. Afinamiento del Planificador de I/O del Disco vía /sys ---"
    local main_disk=$(lsblk -d -o NAME,TYPE | grep 'disk' | head -n 1 | awk '{print $1}')
    if [[ -z "$main_disk" ]]; then echo "  No se encontró disco principal."; return; fi

    local is_rotational=$(cat "/sys/block/$main_disk/queue/rotational")
    local target_scheduler="mq-deadline" # Ideal para SSD/NVMe
    if [[ "$is_rotational" -eq 1 ]]; then
        target_scheduler="bfq" # Ideal para HDD
    fi
    
    tune_parameter "/sys/block/$main_disk/queue/scheduler" "$target_scheduler" "Ajustando Planificador de I/O para tipo de disco"
}

# =============================================================================
# TÉCNICA 3: CONTROL DE BAJO NIVEL DE DISPOSITIVOS
# Interactúa con LEDs del sistema y controla la retroiluminación.
# - /sys/class/leds/...
# - /sys/class/backlight/...
# =============================================================================
function low_level_device_control {
    echo "--- 3. Control de Dispositivos de Bajo Nivel vía /sys ---"

    # Buscar el LED del Bloqueo de Mayúsculas (capslock) y hacerlo parpadear.
    local capslock_led=$(find /sys/class/leds/ -name "*capslock" -type d | head -n 1)
    if [[ -n "$capslock_led" && -w "$capslock_led/trigger" ]]; then
        echo "Controlando LED de CapsLock..."
        # Guardar el trigger original
        ORIGINAL_STATES["$capslock_led/trigger"]=$(cat "$capslock_led/trigger")
        
        echo "  - ACCIÓN: Haciendo parpadear el LED..."
        echo "timer" > "$capslock_led/trigger"
        sleep 3
        echo "  - ACCIÓN: Restaurando comportamiento del LED..."
        echo "${ORIGINAL_STATES[$capslock_led/trigger]}" > "$capslock_led/trigger"
    else
        echo "  No se encontró un LED de CapsLock controlable."
    fi
    echo ""
}

# =============================================================================
# TÉCNICA 4: GESTIÓN DE MEMORIA VIRTUAL DEL KERNEL
# Modifica parámetros que afectan cómo el kernel maneja la memoria y el swap.
# - /sys/kernel/mm/transparent_hugepage/enabled
# =============================================================================
function virtual_memory_management {
    echo "--- 4. Gestión de Memoria Virtual del Kernel vía /sys ---"
    
    # Deshabilitar Transparent Huge Pages, una optimización recomendada para bases de datos.
    tune_parameter "/sys/kernel/mm/transparent_hugepage/enabled" "madvise" "Ajustando Transparent Huge Pages (THP)"
    tune_parameter "/sys/kernel/mm/transparent_hugepage/defrag" "madvise" "Ajustando Defragmentación de THP"
}

# --- SCRIPT PRINCIPAL ---
main() {
    echo "--- INICIANDO SCRIPT DE MANIPULACIÓN AVANZADA DE /sys ---"
    echo "ADVERTENCIA: Se modificarán parámetros del kernel en vivo."
    echo "Los cambios se revertirán al salir (Ctrl+C)."
    echo ""

    cpu_performance_tuning
    disk_io_scheduler_tuning
    low_level_device_control
    virtual_memory_management

    echo "--- Afinamiento completado. El sistema está en modo de alto rendimiento. ---"
    echo "Presiona Ctrl+C para salir y revertir todos los cambios..."
    
    # Bucle infinito para mantener los cambios activos mientras el script se ejecuta.
    while true; do
        sleep 3600
    done
}

main