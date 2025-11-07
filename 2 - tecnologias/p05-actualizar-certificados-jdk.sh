#!/bin/bash
# p05-actualizar-certificados-jdk.sh
#
# DESCRIPCIÓN:
#   Soluciona el error "PKIX path building failed" en JDK 8 antiguos.
#   Descarga el certificado raíz ISRG Root X1 de Let's Encrypt y lo
#   importa al almacén de certificados 'cacerts' del JDK 8 del proyecto.
#
# CORRECCIÓN:
#   Añadida la instalación automática de 'curl' si no está presente.

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- 1. VERIFICAR PERMISOS DE ROOT ---
# Se necesitan permisos de root para instalar curl (si es necesario) y para modificar el keystore.
if [ "$(id -u)" -ne 0 ]; then
    error "Este script debe ejecutarse como root. Usa: sudo ./p05-actualizar-certificados-jdk.sh"
fi

# --- 2. VERIFICAR E INSTALAR DEPENDENCIAS (curl) ---
log "Verificando dependencias necesarias (curl)..."
if ! command -v curl &> /dev/null; then
    warn "El comando 'curl' no está instalado. Instalándolo ahora..."
    apt-get update
    apt-get install -y curl
    log "✅ 'curl' instalado correctamente."
else
    log "✅ 'curl' ya está instalado."
fi

# --- 3. CARGAR CONFIGURACIÓN DEL ENTORNO ---
log "Cargando configuración del entorno para localizar el JDK..."
# Necesitamos encontrar el usuario que ejecutó sudo para leer su .project-env
if [ -n "$SUDO_USER" ]; then
    PROJECT_ENV_FILE="/home/$SUDO_USER/.project-env"
else
    # Si se ejecuta como root directamente
    PROJECT_ENV_FILE="$HOME/.project-env"
fi

if [ ! -f "$PROJECT_ENV_FILE" ]; then
    error "No se encontró '$PROJECT_ENV_FILE'. Ejecuta los scripts de configuración previos (p03, p04) como usuario normal."
fi
# Importante: source debe ejecutarse sin sudo para que las variables se carguen correctamente
source "$PROJECT_ENV_FILE"

# --- 4. VERIFICAR QUE JAVA_HOME ESTÁ DEFINIDO Y ES CORRECTO ---
if [ -z "${JAVA_HOME:-}" ]; then
    error "La variable de entorno JAVA_HOME no está definida en '$PROJECT_ENV_FILE'."
fi
if [ ! -d "$JAVA_HOME" ]; then
    error "El directorio JAVA_HOME ('$JAVA_HOME') no existe."
fi
log "JDK del proyecto localizado en: $JAVA_HOME"

# --- 5. DEFINIR VARIABLES ---
CACERTS_FILE="$JAVA_HOME/jre/lib/security/cacerts"
KEYSTORE_PASS="changeit"
CERT_ALIAS="isrgrootx1"
CERT_URL="https://letsencrypt.org/certs/isrgrootx1.der"
CERT_FILE="/tmp/isrgrootx1.der"

# Validar que el archivo cacerts existe
if [ ! -f "$CACERTS_FILE" ]; then
    error "No se encontró el archivo de certificados '$CACERTS_FILE'. La instalación del JDK parece corrupta."
fi

# --- 6. VERIFICAR SI EL CERTIFICADO YA ESTÁ INSTALADO (IDEMPOTENCIA) ---
log "Verificando si el certificado '$CERT_ALIAS' ya está en el almacén de confianza..."
# Usamos el keytool del JDK del proyecto
KEYTOOL_CMD="$JAVA_HOME/bin/keytool"

if "$KEYTOOL_CMD" -list -keystore "$CACERTS_FILE" -storepass "$KEYSTORE_PASS" -alias "$CERT_ALIAS" > /dev/null 2>&1; then
    log "✅ El certificado '$CERT_ALIAS' ya está instalado. No se necesita ninguna acción."
    exit 0
fi
warn "El certificado '$CERT_ALIAS' no fue encontrado. Procediendo con la instalación."

# --- 7. DESCARGAR EL CERTIFICADO ---
log "Descargando el certificado desde Let's Encrypt..."
# Usamos curl con -k para evitar problemas de validación de certificado al descargar el propio certificado.
curl -sk -o "$CERT_FILE" "$CERT_URL"
if [ ! -f "$CERT_FILE" ]; then
    error "Falló la descarga del certificado."
fi
log "Certificado descargado en $CERT_FILE"

# --- 8. IMPORTAR EL CERTIFICADO AL ALMACÉN CACERTS ---
log "Importando el certificado al almacén de confianza del JDK ($CACERTS_FILE)..."
# Ya estamos como root, no necesitamos sudo aquí.
"$KEYTOOL_CMD" -importcert \
    -keystore "$CACERTS_FILE" \
    -storepass "$KEYSTORE_PASS" \
    -alias "$CERT_ALIAS" \
    -file "$CERT_FILE" \
    -noprompt # Acepta automáticamente la confianza en el certificado

# Verificar de nuevo si se instaló
if "$KEYTOOL_CMD" -list -keystore "$CACERTS_FILE" -storepass "$KEYSTORE_PASS" -alias "$CERT_ALIAS" > /dev/null 2>&1; then
    log "✅ ¡Éxito! El certificado ha sido importado correctamente."
else
    # Si falla, damos ownership al usuario para que pueda reintentar sin sudo si es necesario.
    chown "$SUDO_USER:$SUDO_USER" "$CACERTS_FILE" 2>/dev/null
    error "❌ Falló la importación del certificado. Verifica los permisos de '$CACERTS_FILE' o la contraseña del keystore."
fi

# --- 9. LIMPIAR ---
rm -f "$CERT_FILE"
log "Archivo de certificado temporal eliminado."
log "🎉 El JDK 8 ahora debería poder realizar conexiones HTTPS a sitios modernos."