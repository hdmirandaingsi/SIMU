#!/bin/bash
# p05-actualizar-certificados-jdk.sh
#
# DESCRIPCIÓN:
#   Soluciona el error "PKIX path building failed" en JDK 8 antiguos.
#   Descarga el certificado raíz ISRG Root X1 de Let's Encrypt y lo
#   importa al almacén de certificados 'cacerts' del JDK 8 del proyecto.

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- 1. CARGAR CONFIGURACIÓN DEL ENTORNO ---
log "Cargando configuración del entorno para localizar el JDK..."
PROJECT_ENV_FILE="$HOME/.project-env"
if [ ! -f "$PROJECT_ENV_FILE" ]; then
    error "No se encontró ~/.project-env. Ejecuta los scripts de configuración previos (p03, p04)."
fi
source "$PROJECT_ENV_FILE"

# --- 2. VERIFICAR QUE JAVA_HOME ESTÁ DEFINIDO Y ES CORRECTO ---
if [ -z "$JAVA_HOME" ]; then
    error "La variable de entorno JAVA_HOME no está definida."
fi
if [ ! -d "$JAVA_HOME" ]; then
    error "El directorio JAVA_HOME ($JAVA_HOME) no existe."
fi
log "JDK del proyecto localizado en: $JAVA_HOME"

# --- 3. DEFINIR VARIABLES ---
CACERTS_FILE="$JAVA_HOME/jre/lib/security/cacerts"
# La contraseña por defecto para el almacén 'cacerts' de un JDK estándar es "changeit"
KEYSTORE_PASS="changeit"
CERT_ALIAS="isrgrootx1"
CERT_URL="https://letsencrypt.org/certs/isrgrootx1.der"
CERT_FILE="/tmp/isrgrootx1.der"

# --- 4. VERIFICAR SI EL CERTIFICADO YA ESTÁ INSTALADO (IDEMPOTENCIA) ---
log "Verificando si el certificado '$CERT_ALIAS' ya está en el almacén de confianza..."
if "$JAVA_HOME/bin/keytool" -list -keystore "$CACERTS_FILE" -storepass "$KEYSTORE_PASS" -alias "$CERT_ALIAS" > /dev/null 2>&1; then
    log "✅ El certificado '$CERT_ALIAS' ya está instalado. No se necesita ninguna acción."
    exit 0
fi
warn "El certificado '$CERT_ALIAS' no fue encontrado. Procediendo con la instalación."

# --- 5. DESCARGAR EL CERTIFICADO ---
log "Descargando el certificado desde Let's Encrypt..."
# Usamos curl con la opción -k temporalmente para descargar el certificado
# ya que el sistema base puede no confiar en el sitio de Let's Encrypt tampoco.
curl -sk -o "$CERT_FILE" "$CERT_URL"
if [ ! -f "$CERT_FILE" ]; then
    error "Falló la descarga del certificado."
fi
log "Certificado descargado en $CERT_FILE"

# --- 6. IMPORTAR EL CERTIFICADO AL ALMACÉN CACERTS ---
log "Importando el certificado al almacén de confianza del JDK ($CACERTS_FILE)..."
# El comando -importcert necesita permisos de escritura sobre el archivo cacerts.
# Usamos sudo para ejecutar solo este comando como root.
sudo "$JAVA_HOME/bin/keytool" -importcert \
    -keystore "$CACERTS_FILE" \
    -storepass "$KEYSTORE_PASS" \
    -alias "$CERT_ALIAS" \
    -file "$CERT_FILE" \
    -noprompt # Esto acepta automáticamente la confianza en el certificado

# Verificar de nuevo si se instaló
if "$JAVA_HOME/bin/keytool" -list -keystore "$CACERTS_FILE" -storepass "$KEYSTORE_PASS" -alias "$CERT_ALIAS" > /dev/null 2>&1; then
    log "✅ ¡Éxito! El certificado ha sido importado correctamente."
else
    error "❌ Falló la importación del certificado. Verifica los permisos o la contraseña del keystore."
fi

# --- 7. LIMPIAR ---
rm -f "$CERT_FILE"
log "Archivo de certificado temporal eliminado."
log "🎉 El JDK 8 ahora debería poder realizar conexiones HTTPS a sitios modernos."
