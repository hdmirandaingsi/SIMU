#!/bin/bash
# p07-MVC-estructura-carpetas-archivos.sh
#
# DESCRIPCIÓN:
#   Genera la estructura COMPLETA de carpetas y archivos para el proyecto
#   SISTEMA_TRANSPORTE. Esta versión crea TODOS los archivos vacíos,
#   dejando un esqueleto de proyecto limpio para ser llenado por el desarrollador.

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- 1. CARGAR CONFIGURACIÓN DEL ENTORNO ---
log "Cargando configuración del entorno..."
PROJECT_ENV_FILE="$HOME/.project-env"
if [ ! -f "$PROJECT_ENV_FILE" ]; then
    error "No se encontró ~/.project-env. Ejecuta los scripts de configuración previos."
fi
source "$PROJECT_ENV_FILE"

# --- VALIDAR VARIABLES CARGADAS DEL ENTORNO ---
if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_DIR" ]; then
    error "Las variables PROJECT_NAME o PROJECT_DIR no están definidas en ~/.project-env."
fi

log "Configurando proyecto: $PROJECT_NAME en $PROJECT_DIR"

# --- VARIABLES DE CONFIGURACIÓN ---
PACKAGE_ROOT="com.$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"
BASE_PACKAGE_PATH="src/main/java/$(echo "$PACKAGE_ROOT" | tr '.' '/')"
RESOURCES_PATH="src/main/resources"
WEBAPP_PATH="src/main/webapp"
SOURCE_DIR="/media/sf_CompartoVIRTUALBOX/SoftwarePRN315"
PRIMEFACES_JAR="$SOURCE_DIR/primefaces-8.0.jar"
JBCRYPT_JAR="$SOURCE_DIR/jbcrypt-0.4.jar"

# --- 2. VERIFICAR PREREQUISITOS ---
log "Verificando prerequisitos..."
if [ ! -f "$PRIMEFACES_JAR" ]; then
    error "No se encontró primefaces-8.0.jar en: $PRIMEFACES_JAR"
fi
if [ ! -f "$JBCRYPT_JAR" ]; then
    error "No se encontró jbcrypt-0.4.jar en: $JBCRYPT_JAR. Descárgalo y cópialo allí."
fi

# --- 3. CREACIÓN DE LA ESTRUCTURA BASE DEL PROYECTO ---
log "Iniciando la creación del proyecto: $PROJECT_NAME en $PROJECT_DIR"
cd "$HOME"
mkdir -p "$PROJECT_DIR/$BASE_PACKAGE_PATH"
mkdir -p "$PROJECT_DIR/$RESOURCES_PATH/META-INF"
mkdir -p "$PROJECT_DIR/$WEBAPP_PATH/WEB-INF/lib"
mkdir -p "$PROJECT_DIR/$WEBAPP_PATH/resources/css"
mkdir -p "$PROJECT_DIR/$WEBAPP_PATH/resources/js"
mkdir -p "$PROJECT_DIR/$WEBAPP_PATH/resources/images"

cd "$PROJECT_DIR" || error "No se pudo cambiar al directorio del proyecto."

# --- 4. GENERACIÓN DE ESTRUCTURA DE PAQUETES Y ARCHIVOS VACÍOS ---
log "Generando estructura de paquetes y archivos placeholder..."

# Estructura de paquetes Java
MODULES=("usuarios" "billetera" "viajes" "flota" "rutas" "historial" "reportes" "shared")
SUB_PACKAGES_MVC=("bean" "dao" "entity" "service")
SUB_PACKAGES_SHARED=("exception" "security" "util")
for module in "${MODULES[@]}"; do
    if [ "$module" == "shared" ]; then
        for sub_pkg in "${SUB_PACKAGES_SHARED[@]}"; do mkdir -p "$BASE_PACKAGE_PATH/$module/$sub_pkg"; done
    else
        for sub_pkg in "${SUB_PACKAGES_MVC[@]}"; do mkdir -p "$BASE_PACKAGE_PATH/$module/$sub_pkg"; done
        if [[ "$module" == "viajes" || "$module" == "reportes" ]]; then mkdir -p "$BASE_PACKAGE_PATH/$module/dto"; fi
    fi
done

# Creación de todos los archivos .java vacíos
touch "$BASE_PACKAGE_PATH/usuarios/bean/GestionUsuariosBean.java"
touch "$BASE_PACKAGE_PATH/usuarios/bean/LoginBean.java"
touch "$BASE_PACKAGE_PATH/usuarios/bean/RegistroBean.java"
touch "$BASE_PACKAGE_PATH/usuarios/dao/RolDAO.java"
touch "$BASE_PACKAGE_PATH/usuarios/dao/UsuarioDAO.java"
touch "$BASE_PACKAGE_PATH/usuarios/entity/Rol.java"
touch "$BASE_PACKAGE_PATH/usuarios/entity/Usuario.java"
touch "$BASE_PACKAGE_PATH/usuarios/service/UsuarioService.java"
touch "$BASE_PACKAGE_PATH/billetera/bean/BilleteraBean.java"
touch "$BASE_PACKAGE_PATH/billetera/dao/TarjetaDAO.java"
touch "$BASE_PACKAGE_PATH/billetera/dao/TransaccionDAO.java"
touch "$BASE_PACKAGE_PATH/billetera/entity/Tarjeta.java"
touch "$BASE_PACKAGE_PATH/billetera/entity/TipoTransaccion.java"
touch "$BASE_PACKAGE_PATH/billetera/entity/Transaccion.java"
touch "$BASE_PACKAGE_PATH/billetera/service/BilleteraService.java"
touch "$BASE_PACKAGE_PATH/billetera/service/PasarelaPagoService.java"
touch "$BASE_PACKAGE_PATH/viajes/bean/MapaTiempoRealBean.java"
touch "$BASE_PACKAGE_PATH/viajes/bean/PlanificadorBean.java"
touch "$BASE_PACKAGE_PATH/viajes/dto/UbicacionAutobusDTO.java"
touch "$BASE_PACKAGE_PATH/viajes/entity/Viaje.java"
touch "$BASE_PACKAGE_PATH/viajes/service/MonitoreoGPSService.java"
touch "$BASE_PACKAGE_PATH/viajes/service/PlanificacionService.java"
touch "$BASE_PACKAGE_PATH/flota/bean/GestionAutobusesBean.java"
touch "$BASE_PACKAGE_PATH/flota/dao/AutobusDAO.java"
touch "$BASE_PACKAGE_PATH/flota/entity/Autobus.java"
touch "$BASE_PACKAGE_PATH/flota/service/FlotaService.java"
touch "$BASE_PACKAGE_PATH/rutas/bean/GestionParadasBean.java"
touch "$BASE_PACKAGE_PATH/rutas/bean/GestionRutasBean.java"
touch "$BASE_PACKAGE_PATH/rutas/dao/ParadaDAO.java"
touch "$BASE_PACKAGE_PATH/rutas/dao/RutaDAO.java"
touch "$BASE_PACKAGE_PATH/rutas/dao/TarifaDAO.java"
touch "$BASE_PACKAGE_PATH/rutas/entity/Parada.java"
touch "$BASE_PACKAGE_PATH/rutas/entity/Ruta.java"
touch "$BASE_PACKAGE_PATH/rutas/entity/Tarifa.java"
touch "$BASE_PACKAGE_PATH/rutas/service/AdministracionRutasService.java"
touch "$BASE_PACKAGE_PATH/historial/bean/HistorialBean.java"
touch "$BASE_PACKAGE_PATH/historial/service/ConsultaHistorialService.java"
touch "$BASE_PACKAGE_PATH/reportes/bean/DashboardBean.java"
touch "$BASE_PACKAGE_PATH/reportes/dto/IngresosPorRutaDTO.java"
touch "$BASE_PACKAGE_PATH/reportes/dto/PasajerosHoraPicoDTO.java"
touch "$BASE_PACKAGE_PATH/reportes/service/AnaliticaService.java"
touch "$BASE_PACKAGE_PATH/shared/exception/BusinessLogicException.java"
touch "$BASE_PACKAGE_PATH/shared/security/AuthFilter.java"
touch "$BASE_PACKAGE_PATH/shared/util/DateUtil.java"
touch "$BASE_PACKAGE_PATH/shared/util/FacesUtil.java"




# --- 4b. GENERACIÓN DE LA CAPA REST (JAX-RS) ---
log "Generando estructura de la capa REST (JAX-RS)..."
# Crear la carpeta base de la API
mkdir -p "$BASE_PACKAGE_PATH/api/resource"
mkdir -p "$BASE_PACKAGE_PATH/api/dto"
mkdir -p "$BASE_PACKAGE_PATH/api/exception"
# Crear archivos de recursos REST vacíos (uno por módulo principal)
touch "$BASE_PACKAGE_PATH/api/resource/UsuarioResource.java"
touch "$BASE_PACKAGE_PATH/api/resource/BilleteraResource.java"
touch "$BASE_PACKAGE_PATH/api/resource/ViajeResource.java"
touch "$BASE_PACKAGE_PATH/api/resource/FlotaResource.java"
touch "$BASE_PACKAGE_PATH/api/resource/RutaResource.java"
touch "$BASE_PACKAGE_PATH/api/resource/HistorialResource.java"
touch "$BASE_PACKAGE_PATH/api/resource/ReporteResource.java"
# Archivos opcionales para manejo global
touch "$BASE_PACKAGE_PATH/api/exception/RestExceptionHandler.java"
touch "$BASE_PACKAGE_PATH/api/dto/UsuarioDTO.java"
touch "$BASE_PACKAGE_PATH/api/dto/ViajeDTO.java"




# Creación de carpetas y archivos .xhtml vacíos
mkdir -p "$WEBAPP_PATH/admin/flota"
mkdir -p "$WEBAPP_PATH/admin/paradas"
mkdir -p "$WEBAPP_PATH/admin/rutas"
mkdir -p "$WEBAPP_PATH/admin/usuarios"
mkdir -p "$WEBAPP_PATH/pasajero"
touch "$WEBAPP_PATH/admin/dashboard.xhtml"
touch "$WEBAPP_PATH/admin/flota/formulario.xhtml"
touch "$WEBAPP_PATH/admin/flota/lista.xhtml"
touch "$WEBAPP_PATH/admin/paradas/formulario.xhtml"
touch "$WEBAPP_PATH/admin/paradas/lista.xhtml"
touch "$WEBAPP_PATH/admin/rutas/formulario.xhtml"
touch "$WEBAPP_PATH/admin/rutas/lista.xhtml"
touch "$WEBAPP_PATH/admin/usuarios/formulario.xhtml"
touch "$WEBAPP_PATH/admin/usuarios/lista.xhtml"
touch "$WEBAPP_PATH/pasajero/billetera.xhtml"
touch "$WEBAPP_PATH/pasajero/dashboard.xhtml"
touch "$WEBAPP_PATH/pasajero/historial.xhtml"
touch "$WEBAPP_PATH/pasajero/mapa.xhtml"
touch "$WEBAPP_PATH/pasajero/planificarViaje.xhtml"
touch "$WEBAPP_PATH/accesoDenegado.xhtml"
touch "$WEBAPP_PATH/error.xhtml"
touch "$WEBAPP_PATH/index.xhtml"
touch "$WEBAPP_PATH/login.xhtml"
touch "$WEBAPP_PATH/registro.xhtml"
touch "$WEBAPP_PATH/template.xhtml"

# Creación de archivos de recursos y configuración vacíos
touch "$WEBAPP_PATH/resources/css/style.css"
touch "$WEBAPP_PATH/WEB-INF/web.xml"
touch "$WEBAPP_PATH/WEB-INF/beans.xml"
touch "$WEBAPP_PATH/WEB-INF/faces-config.xml"
touch "$RESOURCES_PATH/META-INF/persistence.xml"

log "✅ Estructura completa de directorios y archivos vacíos creada."

# --- 5. CREACIÓN DE ARCHIVOS DE CONFIGURACIÓN CON CONTENIDO MÍNIMO ---
log "Creando archivos de configuración con contenido mínimo válido..."

# web.xml - ¡CRÍTICO! Necesita la definición del Faces Servlet.
cat > "$WEBAPP_PATH/WEB-INF/web.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">
    <servlet>
        <servlet-name>Faces Servlet</servlet-name>
        <servlet-class>javax.faces.webapp.FacesServlet</servlet-class>
        <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>Faces Servlet</servlet-name>
        <url-pattern>*.xhtml</url-pattern>
    </servlet-mapping>
    <filter>
        <filter-name>AuthFilter</filter-name>
        <filter-class>${PACKAGE_ROOT}.shared.security.AuthFilter</filter-class>
    </filter>
    <filter-mapping>
        <filter-name>AuthFilter</filter-name>
        <url-pattern>/admin/*</url-pattern>
        <url-pattern>/pasajero/*</url-pattern>
    </filter-mapping>
    <welcome-file-list>
        <welcome-file>index.xhtml</welcome-file>
    </welcome-file-list>
</web-app>
EOF

# persistence.xml - Necesita la unidad de persistencia aunque esté vacía de propiedades.
cat > "$RESOURCES_PATH/META-INF/persistence.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<persistence version="2.1" xmlns="http://xmlns.jcp.org/xml/ns/persistence"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/persistence http://xmlns.jcp.org/xml/ns/persistence/persistence_2_1.xsd">
    <persistence-unit name="transportePU" transaction-type="JTA">
        <jta-data-source>jdbc/miDB</jta-data-source>
        <exclude-unlisted-classes>false</exclude-unlisted-classes>
        <properties>
            <!-- Propiedades pueden añadirse aquí más tarde -->
        </properties>
    </persistence-unit>
</persistence>
EOF

# beans.xml - Necesita el tag raíz para activar CDI.
cat > "$WEBAPP_PATH/WEB-INF/beans.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://xmlns.jcp.org/xml/ns/javaee"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/beans_1_1.xsd"
       bean-discovery-mode="annotated">
</beans>
EOF

# faces-config.xml - Puede estar vacío, pero debe ser un XML válido.
cat > "$WEBAPP_PATH/WEB-INF/faces-config.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<faces-config
    xmlns="http://xmlns.jcp.org/xml/ns/javaee"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-facesconfig_2_2.xsd"
    version="2.2">
</faces-config>
EOF

# index.xhtml - Una página de bienvenida mínima es mejor que un archivo vacío.
cat > "$WEBAPP_PATH/index.xhtml" << 'EOF'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html">
<h:head>
    <title>Bienvenido</title>
</h:head>
<h:body>
    <h1> en "web.xml" Establece index.xhtml como página de bienvenida </h1>
    <p>La aplicación está en línea.</p>
</h:body>
</html>
EOF

touch "$WEBAPP_PATH/resources/css/style.css"
touch "$WEBAPP_PATH/login.xhtml" # Y otros archivos .xhtml que pueden seguir vacíos por ahora

log "✅ Archivos de configuración creados con contenido mínimo válido."

# --- 6. COPIAR LIBRERÍAS Y CREAR SCRIPTS DE BUILD/DEPLOY (Sin cambios) ---
log "Copiando librerías y creando scripts..."
#cp -v "$PRIMEFACES_JAR" "$WEBAPP_PATH/WEB-INF/lib/"
cp -v "$JBCRYPT_JAR" "$WEBAPP_PATH/WEB-INF/lib/"

# CREACIÓN DE build.sh y deploy.sh (Estos scripts no necesitan cambios)
# ... (El código de `build.sh` y `deploy.sh` de la versión anterior es correcto y se mantiene aquí)
cat > "$PROJECT_DIR/build.sh" << 'EOF'
#!/bin/bash
# build.sh - Script de compilación DEFINITIVO Y CORREGIDO
set -euo pipefail

# --- 1. Cargar Entorno del Proyecto ---
PROJECT_ENV_FILE="$HOME/.project-env"
if [ -f "$PROJECT_ENV_FILE" ]; then
    source "$PROJECT_ENV_FILE"
else
    echo "ERROR: Archivo de entorno ~/.project-env no encontrado."
    exit 1
fi

# --- 2. Validar que se ejecuta desde el directorio correcto ---
if [ "$PWD" != "$PROJECT_DIR" ]; then
    echo "ERROR: Ejecuta este script desde el directorio raíz del proyecto: $PROJECT_DIR"
    exit 1
fi

# --- 3. Definir Directorios ---
BUILD_DIR="target"
CLASSES_DIR="$BUILD_DIR/WEB-INF/classes"
SRC_DIR="src/main/java"
RESOURCES_DIR="src/main/resources"
WEBAPP_DIR="src/main/webapp"
WAR_FILE="$BUILD_DIR/$PROJECT_NAME.war"
LIB_DIR="$WEBAPP_DIR/WEB-INF/lib"

# --- 4. Limpieza ---
echo "INFO: Limpiando directorio de compilación anterior..."
rm -rf "$BUILD_DIR"
mkdir -p "$CLASSES_DIR"

# --- 5. Construir el CLASSPATH de Compilación ---
echo "INFO: Construyendo classpath..."

# API principal de Java EE (contiene EJB, JPA, CDI, etc.)
GF_CLIENT_JAR="$GLASSFISH_HOME/glassfish/lib/gf-client.jar"

# API de JSF explícitamente
JSF_API_JAR=$(find "$GLASSFISH_HOME/glassfish/modules" -name "javax.faces.jar" | head -n 1)

# =========== CORRECCIÓN: AÑADIR PRIMEFACES AL CLASSPATH ===========
# Buscamos el JAR de PrimeFaces donde lo pusimos: en la carpeta lib del dominio.
PRIMEFACES_JAR=$(find "$GLASSFISH_HOME/glassfish/domains/domain1/lib" -name "primefaces*.jar" | head -n 1)

# API de JAX-RS para REST
JAXRS_API_JAR=$(find "$GLASSFISH_HOME/glassfish/modules" -name "*javax.ws.rs*.jar" | head -n 1)
if [ -z "$JAXRS_API_JAR" ]; then
    echo "ERROR: No se encontró el JAR de JAX-RS en GlassFish."
    exit 1
fi

if [ -z "$PRIMEFACES_JAR" ]; then
    echo "ERROR: No se encontró primefaces.jar en la carpeta lib del dominio de GlassFish."
    echo "       Asegúrate de haber ejecutado p06-confi-glassfish-postgresql.sh correctamente."
    exit 1
fi
# =================================================================

# Librerías locales del proyecto (solo jbcrypt ahora)
PROJECT_LIBS=$(find "$LIB_DIR" -name "*.jar" | tr '\n' ':')

# Unir todo en la variable CLASSPATH, separados por dos puntos (:)
CLASSPATH="${GF_CLIENT_JAR}:${JSF_API_JAR}:${JAXRS_API_JAR}:${PRIMEFACES_JAR}:${PROJECT_LIBS}."
# --- 6. Copiar Archivos de Recursos ANTES de compilar ---
echo "INFO: Copiando archivos de recursos (persistence.xml)..."
if [ -d "$RESOURCES_DIR" ] && [ "$(ls -A $RESOURCES_DIR)" ]; then
    cp -r "$RESOURCES_DIR"/* "$CLASSES_DIR/"
fi

# --- 7. Compilar el Código Fuente Java ---
echo "INFO: Compilando los archivos .java..."
find "$SRC_DIR" -name "*.java" -print0 | xargs -0 --no-run-if-empty javac -d "$CLASSES_DIR" -cp "$CLASSPATH"

if [ $? -ne 0 ]; then
    echo "ERROR: La compilación falló. Revisa los errores de arriba."
    exit 1
fi

# --- 8. Empaquetar el Archivo .WAR ---
echo "INFO: Empaquetando el archivo .war..."
cp -r "$WEBAPP_DIR"/* "$BUILD_DIR/"
jar -cvf "$WAR_FILE" -C "$BUILD_DIR" . > /dev/null

if [ ! -f "$WAR_FILE" ]; then
    echo "ERROR: Falló la creación del archivo WAR."
    exit 1
fi

echo "INFO: ¡Construcción completada exitosamente!"
echo "      -> Archivo generado: $WAR_FILE"
EOF


cat > "$PROJECT_DIR/deploy.sh" << 'EOF'
#!/bin/bash
set -e

# Cargar entorno
source "$HOME/.project-env"

# Validar que se ejecuta desde el directorio del proyecto
if [ "$PWD" != "$PROJECT_DIR" ]; then
    echo "ERROR: Ejecuta este script desde el directorio del proyecto: $PROJECT_DIR"
    exit 1
fi

echo "🚀 Construyendo el proyecto..."
./build.sh

WAR_FILE="target/$PROJECT_NAME.war"
if [ ! -f "$WAR_FILE" ]; then
    echo "❌ Error: No se generó el archivo WAR."
    exit 1
fi

echo "🚀 Desplegando en GlassFish..."
ASADMIN="$GLASSFISH_HOME/bin/asadmin"

# Usar --force=true es más robusto y simple que undeploy + deploy
# Asegura que la aplicación se actualice o se despliegue si no existe.
"$ASADMIN" deploy --force=true "$WAR_FILE"

echo ""
echo "🎉 ¡Listo! Accede a tu aplicación en:"
echo "   http://localhost:8080/$PROJECT_NAME"
EOF


chmod +x "$PROJECT_DIR/build.sh" "$PROJECT_DIR/deploy.sh"

# --- 7. MENSAJE FINAL ---
echo ""
log "================================================================"
log "¡PROYECTO '$PROJECT_NAME' CREADO EXITOSAMENTE!"
log "================================================================"
warn "La sintaxis de 'deploy.sh' ha sido corregida."
echo "   Para construir y desplegar, ejecuta:"
echo "      cd $PROJECT_DIR && ./deploy.sh"
