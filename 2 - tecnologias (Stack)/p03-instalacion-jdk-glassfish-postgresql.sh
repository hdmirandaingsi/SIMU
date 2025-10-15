#!/bin/bash

# =================================================================
# SCRIPT DEFINITIVO: INSTALACIÓN DE JDK 8u112 + GLASSFISH 4.1.1 EN PROYECTO PERSONALIZADO
# Archivos fuente: jdk-8u112-linux-x64.tar.gz y glassfish-4.1.1.zip
# Origen: /media/sf_CompartoVIRTUALBOX/SoftwarePRN315/
# Destino: ~/Documents/<NOMBRE_DEL_PROYECTO>
# RECOMENDACIÓN: NO usar systemd. Iniciar GlassFish manualmente con asadmin.
# =================================================================

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Verificar ejecución como usuario normal (NO como root)
if [ "$(id -u)" -eq 0 ]; then
    error "Este script debe ejecutarse como usuario normal (h-debian), NO como root."
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

# Validación: no vacío, solo letras, números, guiones y guiones bajos
if [[ -z "$PROJECT_NAME" ]]; then
    error "❌ El nombre del proyecto no puede estar vacío."
fi

if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "❌ Nombre inválido. Usa solo letras, números, guiones (-) y guiones bajos (_)."
fi

PROJECT_DIR="$HOME/Proyectos/$PROJECT_NAME"

# Verificar si ya existe la carpeta
if [ -d "$PROJECT_DIR" ]; then
    read -p "⚠️  La carpeta '$PROJECT_DIR' ya existe. ¿Deseas sobrescribirla? (s/N): " confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        error "Operación cancelada por el usuario."
    else
        rm -rf "$PROJECT_DIR"
        log "🗑️  Carpeta existente eliminada: $PROJECT_DIR"
    fi
fi

# Crear directorio del proyecto
mkdir -p "$PROJECT_DIR" || error "No se pudo crear el directorio del proyecto: $PROJECT_DIR"
log "✅ Directorio del proyecto creado: $PROJECT_DIR"


# =================================================================
# CONFIGURACIÓN DE RUTAS Validad recursos
# =================================================================
SOURCE_DIR="/media/sf_CompartoVIRTUALBOX/SoftwarePRN315"
JAVA_DIR="$PROJECT_DIR/jdk1.8.0_112"
GLASSFISH_DIR="$PROJECT_DIR/glassfish4"

# Verificar que la carpeta compartida existe
if [ ! -d "$SOURCE_DIR" ]; then
    error "❌ La carpeta compartida '$SOURCE_DIR' no existe. Verifica que Guest Additions estén instalados y la carpeta esté compartida en VirtualBox."
fi

# Verificar archivos fuente
if [ ! -f "$SOURCE_DIR/jdk-8u112-linux-x64.tar.gz" ]; then
    error "❌ No se encontró el archivo: jdk-8u112-linux-x64.tar.gz"
fi

if [ ! -f "$SOURCE_DIR/glassfish-4.1.1.zip" ]; then
    error "❌ No se encontró el archivo: glassfish-4.1.1.zip.  
           Descarga el archivo oficial desde:  
           https://download.oracle.com/glassfish/4.1.1/release/glassfish-4.1.1.zip"
fi

log "✅ Archivos fuente encontrados en: $SOURCE_DIR"

# =================================================================
# COPIAR ARCHIVOS A LA CARPETA DEL PROYECTO (CON PERMISOS)
# =================================================================
log "Copiando archivos a $PROJECT_DIR..."

cp -v "$SOURCE_DIR/jdk-8u112-linux-x64.tar.gz" "$PROJECT_DIR/" || error "Falló la copia del JDK"
cp -v "$SOURCE_DIR/glassfish-4.1.1.zip" "$PROJECT_DIR/" || error "Falló la copia de GlassFish"
cp -v "$SOURCE_DIR/primefaces-8.0.jar" "$PROJECT_DIR/" || warn "No se encontró primefaces-8.0.jar. Asegúrate de haberlo copiado a $SOURCE_DIR."

# Dar permisos completos a los archivos copiados
chmod 755 "$PROJECT_DIR/jdk-8u112-linux-x64.tar.gz"
chmod 755 "$PROJECT_DIR/glassfish-4.1.1.zip"

log "✅ Archivos copiados y con permisos correctos."

# =================================================================
# INSTALAR JDK 8u112 DENTRO DEL PROYECTO
# =================================================================
log "Instalando JDK 8u112 en $JAVA_DIR..."

mkdir -p "$JAVA_DIR" || error "No se pudo crear el directorio de JDK"

# Extraer y detectar estructura real
tar -xzf "$PROJECT_DIR/jdk-8u112-linux-x64.tar.gz" -C "$PROJECT_DIR" || error "Falló la extracción del JDK"

# Buscar la carpeta JDK real (por si tiene ./ o estructura extraña)
JDK_SUBDIR=$(find "$PROJECT_DIR" -maxdepth 2 -name "jdk1.8.0_112" -type d | head -1)

if [ -z "$JDK_SUBDIR" ]; then
    error "❌ No se encontró la carpeta jdk1.8.0_112 después de descomprimir."
fi

mv "$JDK_SUBDIR"/* "$JAVA_DIR/" 2>/dev/null
rmdir "$JDK_SUBDIR" 2>/dev/null

# Verificar instalación
if [ ! -f "$JAVA_DIR/bin/java" ] || [ ! -f "$JAVA_DIR/bin/javac" ]; then
    error "❌ JDK no instalado correctamente. Falta bin/java o bin/javac."
fi

log "✅ JDK 8u112 instalado en: $JAVA_DIR"



# =================================================================
# INSTALAR GLASSFISH 4.1.1 DENTRO DEL PROYECTO (USANDO .ZIP OFICIAL)
# =================================================================
log "Instalando GlassFish 4.1.1 en $GLASSFISH_DIR..."

# Limpiar si ya existe
rm -rf "$GLASSFISH_DIR"
mkdir -p "$GLASSFISH_DIR"

# Asegurar permisos
chmod 644 "$PROJECT_DIR/glassfish-4.1.1.zip" || warn "No se pudieron ajustar permisos del .zip"

# Verificar que el ZIP contiene la estructura oficial
if ! unzip -l "$PROJECT_DIR/glassfish-4.1.1.zip" | grep -q "glassfish4/bin/asadmin"; then
    error "❌ El archivo glassfish-4.1.1.zip NO contiene la estructura esperada.  
           Descarga el archivo oficial desde:  
           https://download.oracle.com/glassfish/4.1.1/release/glassfish-4.1.1.zip  "
fi

# Descomprimir en un directorio temporal dentro de $GLASSFISH_DIR
TEMP_GLASSFISH="$GLASSFISH_DIR/tmp_glassfish"
rm -rf "$TEMP_GLASSFISH"
mkdir -p "$TEMP_GLASSFISH"

cd "$TEMP_GLASSFISH"
unzip -q "$PROJECT_DIR/glassfish-4.1.1.zip" || error "Falló la descompresión de GlassFish 4.1.1"

# Ahora verificamos qué estructura tenemos
if [ -d "$TEMP_GLASSFISH/glassfish4" ]; then
    # El ZIP contiene directamente "glassfish4" → moverlo al nivel superior
    mv "$TEMP_GLASSFISH/glassfish4"/* "$GLASSFISH_DIR/" 2>/dev/null
    rmdir "$TEMP_GLASSFISH/glassfish4" 2>/dev/null
else
    error "❌ El archivo zip no contiene la carpeta 'glassfish4'. Archivo corrupto o incorrecto."
fi

# Eliminar temporal
rm -rf "$TEMP_GLASSFISH"

# Verificar que asadmin está en la ubicación correcta final
ASADMIN_FINAL="$GLASSFISH_DIR/bin/asadmin"
if [ ! -f "$ASADMIN_FINAL" ]; then
    error "❌ No se encontró asadmin en $ASADMIN_FINAL.  
           El archivo glassfish-4.1.1.zip no es el oficial de Oracle o la extracción falló."
fi

# Hacerlo ejecutable
if [ ! -x "$ASADMIN_FINAL" ]; then
    log "🔧 Ajustando permisos de ejecución a asadmin..."
    chmod +x "$ASADMIN_FINAL"
fi

# Crear enlace simbólico para accesibilidad (opcional, pero útil)
ln -sf "$ASADMIN_FINAL" "$GLASSFISH_DIR/bin/asadmin" 2>/dev/null || warn "Enlace ya existe"

log "✅ GlassFish 4.1.1 instalado correctamente en: $GLASSFISH_DIR"








# =================================================================
# DAR PERMISOS COMPLETOS A TODO EL PROYECTO
# =================================================================
log "Dando permisos completos a todo el proyecto..."
chmod -R 755 "$PROJECT_DIR"
chown -R $(whoami):$(whoami) "$PROJECT_DIR"
log "✅ Permisos aplicados: lectura, escritura y ejecución para el usuario."
 


log "📝 Creando el archivo de entorno del proyecto en ~/project-env..."
PROJECT_ENV_FILE="$HOME/project-env"

cat > "$PROJECT_ENV_FILE" << EOF
# =================================================================
# CONFIGURACIÓN DEL PROYECTO '$PROJECT_NAME' - GENERADO AUTOMÁTICAMENTE
# =================================================================
export PROJECT_NAME="$PROJECT_NAME"
export PROJECT_DIR="$PROJECT_DIR"
export JAVA_HOME="$JAVA_DIR"
export GLASSFISH_HOME="$GLASSFISH_DIR"
export PATH="$JAVA_HOME/bin:\$GLASSFISH_HOME/bin:\$PATH"
EOF

# ⚠️ ¡IMPORTANTE! Cargar variables AHORA MISMO en este script para verificación
source "$PROJECT_ENV_FILE"

# Verificar que java y javac están disponibles
if ! command -v java &> /dev/null; then
    error "❌ JDK no configurado correctamente. Verifica el archivo ~/project-env-jdk8"
fi

if ! command -v javac &> /dev/null; then
    error "❌ javac no encontrado. Asegúrate de que es un JDK, no un JRE."
fi

# Mostrar versión para confirmación
log "✅ JDK verificado: $(java -version 2>&1 | head -1)"
log "✅ javac verificado: $(javac -version 2>&1)"
log "✅ Archivo de entorno creado en: $PROJECT_ENV_FILE"
warn "   Para que esta configuración esté disponible en nuevas terminales, añade esta línea a tu ~/.bashrc:"
warn "   source ~/project-env"


# === 13. COPIAR PRIMEFACES JAR A LA CARPETA LIB DEL PROYECTO (PARA USO EN DESPLIEGUE) ===
log "📦 Copiando primefaces-8.0.jar a la carpeta lib del proyecto (para futura compilación)..."

PRIMEFACES_JAR="$PROJECT_DIR/primefaces-8.0.jar"
if [ -f "$PRIMEFACES_JAR" ]; then
    mkdir -p "$PROJECT_DIR/lib"
    cp -v "$PRIMEFACES_JAR" "$PROJECT_DIR/lib/" || warn "No se pudo copiar primefaces-8.0.jar a lib/"
    log "✅ primefaces-8.0.jar copiado a: $PROJECT_DIR/lib/"
else
    warn "⚠️  No se encontró primefaces-8.0.jar en $SOURCE_DIR. Debes agregarlo manualmente al proyecto en WEB-INF/lib/ antes de compilar."
fi

 

# =================================================================
# NOTA FINAL: NO SE CREA SERVICIO SYSTEMD — USO MANUAL RECOMENDADO
# =================================================================
log "⚠️  GLASSFISH 4.1.1 NO USA SERVICIO SYSTEMD EN LINUX MODERNO."
log "   ✅ Inicia GlassFish manualmente con:"
log "      cd $GLASSFISH_DIR/bin && ./asadmin start-domain --verbose &"
log "   ✅ Detén GlassFish con:"
log "      cd $GLASSFISH_DIR/bin && ./asadmin stop-domain"
log "   ✅ Accede al panel web en: http://localhost:4848"
log ""
log "🎉 INSTALACIÓN COMPLETADA CON ÉXITO. ¡LISTO PARA USAR!"
