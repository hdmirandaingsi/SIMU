#!/bin/bash
# p03-instalacion-jdk-glassfish-postgresql.sh
#
# SCRIPT CORREGIDO Y MEJORADO:
# Instala un JDK 8 y GlassFish 4.1.1 en un directorio de proyecto autocontenido.
# Origen: /media/sf_CompartoVIRTUALBOX/SoftwarePRN315/
# Destino: ~/Proyectos/<NOMBRE_DEL_PROYECTO>

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- VERIFICAR EJECUCIÓN COMO USUARIO NORMAL ---
if [ "$(id -u)" -eq 0 ]; then
    error "Este script debe ejecutarse como usuario normal (ej: h-debian), NO como root."
fi

# =================================================================
# PREGUNTAR NOMBRE DEL PROYECTO
# =================================================================
echo ""
echo -e "${YELLOW}==============================================${NC}"
echo -e "${YELLOW}        🚀 INICIANDO INSTALACIÓN DEL PROYECTO ${NC}"
echo -e "${YELLOW}==============================================${NC}"
echo ""

read -p "👉 ¿Qué nombre tendrá tu proyecto? (ej: SIMU): " PROJECT_NAME

# Validación del nombre
if [[ -z "$PROJECT_NAME" ]]; then
    error "❌ El nombre del proyecto no puede estar vacío."
fi
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "❌ Nombre inválido. Usa solo letras, números, guiones (-) y guiones bajos (_)."
fi

# CORRECCIÓN: Asegurarse de que el directorio base ~/Proyectos existe
BASE_PROJECTS_DIR="$HOME/Proyectos"
mkdir -p "$BASE_PROJECTS_DIR"

PROJECT_DIR="$BASE_PROJECTS_DIR/$PROJECT_NAME"

# Verificar si la carpeta del proyecto ya existe
if [ -d "$PROJECT_DIR" ]; then
    read -p "⚠️  La carpeta '$PROJECT_DIR' ya existe. ¿Deseas sobrescribirla? (s/N): " confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        error "Operación cancelada por el usuario."
    else
        log "🗑️  Eliminando carpeta existente: $PROJECT_DIR"
        rm -rf "$PROJECT_DIR"
    fi
fi

# Crear directorio del proyecto
mkdir -p "$PROJECT_DIR" || error "No se pudo crear el directorio del proyecto: $PROJECT_DIR"
log "✅ Directorio del proyecto creado en: $PROJECT_DIR"

# =================================================================
# CONFIGURACIÓN DE RUTAS Y VALIDACIÓN DE RECURSOS
# =================================================================
SOURCE_DIR="/media/sf_CompartoVIRTUALBOX/SoftwarePRN315"
# CORRECCIÓN: Nombres de los directorios de destino definidos de forma más clara
JAVA_DEST_DIR="$PROJECT_DIR/jdk"
GLASSFISH_DEST_DIR="$PROJECT_DIR/glassfish"

# Verificar que la carpeta compartida y los archivos fuente existen
if [ ! -d "$SOURCE_DIR" ]; then
    error "❌ La carpeta compartida '$SOURCE_DIR' no existe. Verifica la configuración de VirtualBox."
fi
if [ ! -f "$SOURCE_DIR/jdk-8u112-linux-x64.tar.gz" ]; then
    error "❌ No se encontró el archivo: jdk-8u112-linux-x64.tar.gz en $SOURCE_DIR"
fi
if [ ! -f "$SOURCE_DIR/glassfish-4.1.1.zip" ]; then
    error "❌ No se encontró el archivo: glassfish-4.1.1.zip en $SOURCE_DIR"
fi
if [ ! -f "$SOURCE_DIR/gson-2.8.9.jar" ]; then
    error "❌ No se encontró el archivo: gson-2.8.9.jar en $SOURCE_DIR"
fi


log "✅ Archivos fuente encontrados en: $SOURCE_DIR"

# =================================================================
# COPIAR Y EXTRAER JDK 8u112
# =================================================================
log "Copiando y extrayendo JDK 8..."
cp "$SOURCE_DIR/jdk-8u112-linux-x64.tar.gz" "$PROJECT_DIR/"

# Crear un directorio temporal para la extracción para manejar estructuras de .tar.gz anidadas
TEMP_JDK_DIR=$(mktemp -d)
tar -xzf "$PROJECT_DIR/jdk-8u112-linux-x64.tar.gz" -C "$TEMP_JDK_DIR" || error "Falló la extracción del JDK."

# Encontrar la carpeta extraída (ej: jdk1.8.0_112) y mover su contenido
EXTRACTED_JDK_FOLDER=$(find "$TEMP_JDK_DIR" -mindepth 1 -maxdepth 1 -type d)
if [ -z "$EXTRACTED_JDK_FOLDER" ]; then
    error "❌ No se encontró ninguna carpeta dentro del .tar.gz del JDK."
fi

mkdir -p "$JAVA_DEST_DIR"
mv "$EXTRACTED_JDK_FOLDER"/* "$JAVA_DEST_DIR/"

# Limpieza
rm -rf "$TEMP_JDK_DIR"
rm "$PROJECT_DIR/jdk-8u112-linux-x64.tar.gz"

if [ ! -f "$JAVA_DEST_DIR/bin/java" ]; then
    error "❌ JDK no se instaló correctamente en $JAVA_DEST_DIR. Falta el ejecutable 'java'."
fi
log "✅ JDK 8u112 instalado en: $JAVA_DEST_DIR"

# =================================================================
# COPIAR Y EXTRAER GLASSFISH 4.1.1
# =================================================================
log "Copiando y extrayendo GlassFish 4.1.1..."
cp "$SOURCE_DIR/glassfish-4.1.1.zip" "$PROJECT_DIR/"

TEMP_GF_DIR=$(mktemp -d)
unzip -q "$PROJECT_DIR/glassfish-4.1.1.zip" -d "$TEMP_GF_DIR" || error "Falló la descompresión de GlassFish."

# El zip oficial crea una carpeta 'glassfish4' dentro.
EXTRACTED_GF_FOLDER="$TEMP_GF_DIR/glassfish4"
if [ ! -d "$EXTRACTED_GF_FOLDER" ]; then
    error "❌ El archivo .zip de GlassFish no contiene la carpeta 'glassfish4' esperada."
fi

mkdir -p "$GLASSFISH_DEST_DIR"
mv "$EXTRACTED_GF_FOLDER"/* "$GLASSFISH_DEST_DIR/"

# Limpieza
rm -rf "$TEMP_GF_DIR"
rm "$PROJECT_DIR/glassfish-4.1.1.zip"

ASADMIN_PATH="$GLASSFISH_DEST_DIR/bin/asadmin"
if [ ! -f "$ASADMIN_PATH" ]; then
    error "❌ GlassFish no se instaló correctamente. No se encuentra 'asadmin'."
fi
chmod +x "$ASADMIN_PATH"
log "✅ GlassFish 4.1.1 instalado en: $GLASSFISH_DEST_DIR"

# =================================================================
# COPIAR LIBRERÍAS ADICIONALES
# =================================================================
log "Copiando librerías adicionales (PrimeFaces, jBCrypt)..."
mkdir -p "$PROJECT_DIR/lib"
cp "$SOURCE_DIR/primefaces-8.0.jar" "$PROJECT_DIR/lib/" || warn "No se encontró primefaces-8.0.jar"
cp "$SOURCE_DIR/jbcrypt-0.4.jar" "$PROJECT_DIR/lib/" || warn "No se encontró jbcrypt-0.4.jar"
cp "$SOURCE_DIR/gson-2.8.9.jar" "$PROJECT_DIR/lib/" || warn "No se encontró gson-2.8.9.jar"
log "✅ Librerías copiadas a $PROJECT_DIR/lib/"

# =================================================================
# CREAR ARCHIVO DE ENTORNO Y VERIFICAR
# =================================================================
log "📝 Creando el archivo de entorno del proyecto en ~/.project-env..."
PROJECT_ENV_FILE="$HOME/.project-env"

cat > "$PROJECT_ENV_FILE" << EOF
# =================================================================
# CONFIGURACIÓN DEL PROYECTO '$PROJECT_NAME' - GENERADO AUTOMÁTICAMENTE
# Cargar con: source ~/.project-env
# =================================================================
export PROJECT_NAME="$PROJECT_NAME"
export PROJECT_DIR="$PROJECT_DIR"
export JAVA_HOME="$JAVA_DEST_DIR"
export GLASSFISH_HOME="$GLASSFISH_DEST_DIR"
export PATH="\$JAVA_HOME/bin:\$GLASSFISH_HOME/bin:\$PATH"
EOF

# ⚠️ ¡IMPORTANTE! Cargar variables AHORA MISMO en este script para verificación
source "$PROJECT_ENV_FILE"

# Verificar que java y javac están disponibles en el PATH actual
if ! command -v java &> /dev/null; then
    # CORRECCIÓN: Mensaje de error más claro.
    error "❌ El comando 'java' no se encuentra en el PATH. Verifica el archivo '$PROJECT_ENV_FILE' y la instalación del JDK."
fi
if ! command -v javac &> /dev/null; then
    error "❌ El comando 'javac' no se encuentra. Asegúrate de que es un JDK, no un JRE."
fi

# Mostrar versión para confirmación
log "✅ Verificación de JDK exitosa:"
log "   Java version: $(java -version 2>&1 | head -1)"
log "   Javac version: $(javac -version 2>&1)"
log "✅ Archivo de entorno creado en: $PROJECT_ENV_FILE"
warn "   Para que esta configuración esté disponible en NUEVAS terminales, añade esta línea a tu ~/.bashrc:"
warn "   source ~/.project-env"
warn "   Puedes hacerlo automáticamente ejecutando el script p04-config-bashrc.sh"

# =================================================================
# NOTA FINAL
# =================================================================
log ""
log "🎉 ¡INSTALACIÓN DEL ENTORNO COMPLETADA CON ÉXITO!"
log "   Próximos pasos recomendados:"
log "   1. Ejecuta './p04-config-bashrc.sh' para hacer el entorno permanente."
log "   2. Abre una NUEVA terminal para que los cambios surtan efecto."
log "   3. Inicia GlassFish manualmente con: asadmin start-domain"
log "   4. Accede al panel web en: http://localhost:4848"