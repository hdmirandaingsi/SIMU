#!/bin/bash
# p12-app-smoke-test.sh
#
# SCRIPT DE PRUEBAS DE HUMO (SMOKE TEST) AVANZADO PARA LA APLICACIÓN
#
# Utiliza 'curl' para simular interacciones de usuario, verificar la
# disponibilidad de endpoints clave y validar el flujo de registro.
# Es la herramienta profesional y segura para esta tarea.

set -euo pipefail

# --- CONFIGURACIÓN ---
BASE_URL="http://localhost:8080/SIMU"
LOGIN_PAGE="/login.xhtml"
REGISTER_PAGE="/registro.xhtml"
COOKIE_JAR="/tmp/app_test_cookies.txt"
TIMEOUT=10 # Segundos de espera máxima por respuesta

# --- COLORES Y LOGS ---
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
fail() { echo -e "${RED}[FALLÓ]${NC} $1"; exit 1; }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

# --- LIMPIEZA ---
# Asegurarse de que no queden cookies de ejecuciones anteriores
rm -f "$COOKIE_JAR"
# trap se asegura de que el archivo de cookies se borre al salir
trap 'rm -f "$COOKIE_JAR"' EXIT

# =============================================================================
# FUNCIÓN DE PRUEBA GENÉRICA
# Encapsula la lógica de curl para hacer las pruebas más legibles.
# Parámetros: 1: Nombre de la prueba, 2: URL, 3: Texto esperado en la página
# =============================================================================
function test_endpoint() {
    local test_name="$1"
    local url="$2"
    local expected_text="$3"
    
    info "Ejecutando prueba: '$test_name'..."
    
    # curl -s (silencioso), -L (sigue redirecciones), --cookie-jar (guarda cookies),
    # --cookie (envía cookies), --max-time (timeout), -o /dev/null (no mostrar cuerpo),
    # -w '%{http_code}' (solo mostrar código de estado HTTP).
    http_code=$(curl -s -L --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
                     --max-time "$TIMEOUT" -o /dev/null -w '%{http_code}' "$url")

    if [ "$http_code" != "200" ]; then
        fail "Endpoint '$url' devolvió un código de estado inesperado: $http_code (se esperaba 200)."
    fi

    # Ahora, obtener el cuerpo de la página para verificar el contenido
    body=$(curl -s -L --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" "$url")

    if ! echo "$body" | grep -q "$expected_text"; then
        fail "La página en '$url' no contiene el texto esperado: '$expected_text'."
    fi

    ok "'$test_name' completada con éxito."
}

# =============================================================================
# FUNCIÓN PARA SIMULAR EL REGISTRO (PETICIÓN POST)
# =============================================================================
function test_registration_flow() {
    info "Ejecutando prueba de flujo de registro..."
    
    # 1. Visitar la página de registro para obtener el JSESSIONID y el ViewState de JSF
    info "  Paso 1: Obteniendo el formulario de registro..."
    register_page_body=$(curl -s -L --cookie-jar "$COOKIE_JAR" "${BASE_URL}${REGISTER_PAGE}")
    
    # Extraer el javax.faces.ViewState (¡CRÍTICO para que JSF funcione!)
    view_state=$(echo "$register_page_body" | grep 'javax.faces.ViewState' | sed -n 's/.*value="\([^"]*\)".*/\1/p')

    if [ -z "$view_state" ]; then
        fail "No se pudo extraer el javax.faces.ViewState de la página de registro. ¿Es una página JSF válida?"
    fi
    info "  ViewState obtenido: ${view_state:0:20}..."

    # 2. Simular un envío de formulario con datos de prueba (petición POST)
    info "  Paso 2: Enviando datos de registro (POST)..."
    # Datos de un usuario aleatorio para cada prueba
    random_user="testuser_$(date +%s)"
    
    # El flag -d construye el cuerpo de la petición POST. URL-encoding es manejado por curl.
    # El flag -H añade cabeceras, esencial para peticiones POST de formularios web.
    # El flag -v (verbose) es útil para depurar, muestra toda la comunicación.
    post_response_code=$(curl -s -L -o /dev/null -w '%{http_code}' \
        --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "j_idt8:j_idt8" \
        -d "nombre=${random_user}" \
        -d "email=${random_user}@example.com" \
        -d "password=Password123" \
        -d "javax.faces.ViewState=${view_state}" \
        -d "j_idt8:j_idt15=Registrar" \
        "${BASE_URL}${REGISTER_PAGE}")

    # Después de un registro exitoso, la mayoría de aplicaciones redirigen al login o al dashboard.
    # Un código 302 (Found/Redirect) o 200 (OK) son aceptables.
    if [[ "$post_response_code" != "302" && "$post_response_code" != "200" ]]; then
        fail "El envío del formulario de registro devolvió un código inesperado: $post_response_code."
    fi

    ok "Flujo de registro completado con éxito."
}


# --- SCRIPT PRINCIPAL ---
main() {
    echo "--- INICIANDO PRUEBAS DE HUMO DE LA APLICACIÓN '$BASE_URL' ---"
    
    # PRUEBA 1: Verificar que la página de login carga correctamente
    test_endpoint "Carga de la página de Login" \
                  "${BASE_URL}${LOGIN_PAGE}" \
                  "Iniciar Sesión" # Asume que tu página de login tiene este texto

    # PRUEBA 2: Verificar que la página de registro carga correctamente
    test_endpoint "Carga de la página de Registro" \
                  "${BASE_URL}${REGISTER_PAGE}" \
                  "Crear Cuenta" # Asume que tu página de registro tiene este texto
                  
    # PRUEBA 3: Simular el flujo completo de registro de un usuario
    test_registration_flow

    echo ""
    ok "--- TODAS LAS PRUEBAS SE COMPLETARON EXITOSAMENTE ---"
}

main