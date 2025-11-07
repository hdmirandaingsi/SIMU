 #!/bin-bash
# p07-MVC-estructura-carpetas-archivos.sh
#
# DESCRIPCIÓN:
#   Genera la estructura COMPLETA de carpetas y archivos para el proyecto,
#   incluyendo TODOS los archivos .java y .xhtml de todos los módulos.
#   Deja un esqueleto de proyecto limpio listo para ser llenado.

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- CARGAR CONFIGURACIÓN DEL ENTORNO ---
log "Cargando configuración del entorno..."
PROJECT_ENV_FILE="$HOME/.project-env"
if [ ! -f "$PROJECT_ENV_FILE" ]; then
    error "No se encontró ~/.project-env. Ejecuta los scripts de configuración previos."
fi
source "$PROJECT_ENV_FILE"

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
JBCRYPT_JAR="$SOURCE_DIR/jbcrypt-0.4.jar"
GSON_JAR="$SOURCE_DIR/gson-2.8.9.jar"


# --- VERIFICAR JBCRYPT JAR ---
log "Verificando prerequisitos..."
if [ ! -f "$JBCRYPT_JAR" ]; then
    error "No se encontró jbcrypt-0.4.jar en: $JBCRYPT_JAR."
fi
# --- VERIFICAR GSON JAR ---

if [ ! -f "$GSON_JAR" ]; then
    error "No se encontró gson-2.8.9.jar en: $GSON_JAR. Descárgalo y colócalo allí."
fi


# --- CREACIÓN DE LA ESTRUCTURA BASE ---
log "Creando estructura base del proyecto: $PROJECT_NAME en $PROJECT_DIR"
cd "$HOME"
# Limpiar y recrear estructura para asegurar idempotencia
rm -rf "$PROJECT_DIR/src" "$PROJECT_DIR/target"
mkdir -p "$PROJECT_DIR/$BASE_PACKAGE_PATH"
mkdir -p "$PROJECT_DIR/$RESOURCES_PATH/META-INF"
mkdir -p "$PROJECT_DIR/$WEBAPP_PATH/WEB-INF/lib"
mkdir -p "$PROJECT_DIR/$WEBAPP_PATH/resources/css"
mkdir -p "$PROJECT_DIR/$WEBAPP_PATH/resources/js"
mkdir -p "$PROJECT_DIR/$WEBAPP_PATH/resources/images"
cd "$PROJECT_DIR" || error "No se pudo cambiar al directorio del proyecto."

# --- GENERACIÓN DE ESTRUCTURA DE PAQUETES JAVA ---
log "Generando estructura de paquetes Java..."
MODULES=("usuarios" "billetera" "viajes" "flota" "rutas" "historial" "reportes" "shared" "api")
SUB_PACKAGES_MVC=("bean" "dao" "entity" "service")
SUB_PACKAGES_SHARED=("exception" "security" "util" "converter" "dao")
SUB_PACKAGES_API=("resource" "dto" "exception")

for module in "${MODULES[@]}"; do
    if [ "$module" == "shared" ]; then
        for sub_pkg in "${SUB_PACKAGES_SHARED[@]}"; do mkdir -p "$BASE_PACKAGE_PATH/$module/$sub_pkg"; done
    elif [ "$module" == "api" ]; then
        for sub_pkg in "${SUB_PACKAGES_API[@]}"; do mkdir -p "$BASE_PACKAGE_PATH/$module/$sub_pkg"; done
    else
        for sub_pkg in "${SUB_PACKAGES_MVC[@]}"; do mkdir -p "$BASE_PACKAGE_PATH/$module/$sub_pkg"; done
        if [[ "$module" == "viajes" || "$module" == "reportes" ]]; then mkdir -p "$BASE_PACKAGE_PATH/$module/dto"; fi
    fi
done

# --- GENERACIÓN DE ARCHIVOS .java VACÍOS ---
log "Generando archivos placeholder .java..."
FILES_TO_TOUCH=(
    "usuarios/bean/GestionUsuariosBean.java" "usuarios/bean/LoginBean.java" "usuarios/bean/RegistroBean.java" "usuarios/bean/SessionBean.java"
    "usuarios/dao/RolDAO.java" "usuarios/dao/UsuarioDAO.java"
    "usuarios/entity/Rol.java" "usuarios/entity/Usuario.java"
    "usuarios/service/UsuarioService.java"
    "billetera/bean/BilleteraBean.java"
    "billetera/dao/TarjetaDAO.java" "billetera/dao/TransaccionDAO.java"
    "billetera/entity/Tarjeta.java" "billetera/entity/TipoTransaccion.java" "billetera/entity/Transaccion.java"
    "billetera/service/BilleteraService.java"
    "rutas/bean/GestionParadasBean.java" "rutas/bean/GestionRutasBean.java"
    "rutas/dao/ParadaDAO.java" "rutas/dao/RutaDAO.java" "rutas/dao/TarifaDAO.java"
    "rutas/entity/Parada.java" "rutas/entity/Ruta.java" "rutas/entity/Tarifa.java"
    "flota/bean/GestionAutobusesBean.java"
    "flota/dao/AutobusDAO.java"
    "flota/entity/Autobus.java"
    "viajes/bean/PlanificadorBean.java"
    "viajes/dao/ViajeDAO.java"
    "viajes/dto/UbicacionAutobusDTO.java"
    "viajes/entity/Viaje.java"
    "viajes/service/PlanificacionService.java"
    "historial/bean/HistorialBean.java"
    "historial/service/ConsultaHistorialService.java"
    "reportes/bean/DashboardBean.java"
    "reportes/dao/ReporteDAO.java"
    "reportes/dto/IngresosPorRutaDTO.java" "reportes/dto/PasajerosHoraPicoDTO.java"
    "reportes/service/AnaliticaService.java"
    "shared/security/AuthFilter.java"
    "shared/util/FacesUtil.java"
    "shared/converter/EntityConverter.java"
)
for file in "${FILES_TO_TOUCH[@]}"; do
    touch "$BASE_PACKAGE_PATH/$file"
done

# --- GENERACIÓN DE ARCHIVOS .xhtml VACÍOS (COMPLETO) ---
log "Generando archivos placeholder .xhtml para todas las vistas..."
XHTML_FILES_TO_TOUCH=(
    # Vistas Raíz
    "accesoDenegado.xhtml"
    "error.xhtml"
    "index.xhtml"
    "login.xhtml"
    "registro.xhtml"
    "template.xhtml"
    
    # Vistas de Administrador
    "admin/dashboard.xhtml"
    "admin/flota/lista.xhtml"
    "admin/paradas/lista.xhtml"
    "admin/rutas/lista.xhtml"
    "admin/usuarios/lista.xhtml"
    
    # Vistas de Pasajero
    "pasajero/billetera.xhtml"
    "pasajero/dashboard.xhtml"
    "pasajero/historial.xhtml"
    "pasajero/planificarViaje.xhtml"
)
for file in "${XHTML_FILES_TO_TOUCH[@]}"; do
    mkdir -p "$WEBAPP_PATH/$(dirname "$file")"
    touch "$WEBAPP_PATH/$file"
done

# CREACION DE LAS VISTAS WEBAPP y configuración vacíos
touch "$WEBAPP_PATH/resources/css/style.css"
touch "$WEBAPP_PATH/WEB-INF/web.xml" # Activa servlets, filtros, mapeos, archivos de bienvenida
touch "$WEBAPP_PATH/WEB-INF/beans.xml" # Activa CDI (Contexts and Dependency Injection)
touch "$WEBAPP_PATH/WEB-INF/faces-config.xml"
touch "$WEBAPP_PATH/WEB-INF/glassfish-web.xml" # Activa servlets, filtros, mapeos, archivos de bienvenida
 

log "✅ Estructura completa de directorios y archivos vacíos creada."

# --- CREACIÓN DE ARCHIVOS DE CONFIGURACIÓN CON CONTENIDO MÍNIMO ---
log "Creando archivos de configuración PARA Glassfish  "

cat > "$WEBAPP_PATH/WEB-INF/web.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">
    <display-name>${PROJECT_NAME}</display-name>
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
# --- ACTIVANDO : INJECCION DE DEPENDENCIAS   : beans  
cat > "$WEBAPP_PATH/WEB-INF/beans.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://xmlns.jcp.org/xml/ns/javaee"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/beans_1_1.xsd"
       bean-discovery-mode="annotated">
</beans>
EOF

cat > "$WEBAPP_PATH/WEB-INF/faces-config.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<faces-config
    xmlns="http://xmlns.jcp.org/xml/ns/javaee"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-facesconfig_2_2.xsd"
    version="2.2">
</faces-config>
EOF
cat > "$WEBAPP_PATH/index.xhtml" << 'EOF'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:p="http://primefaces.org/ui">
<h:head>
    <title>Bienvenido a TransitGo</title>
    <h:outputStylesheet library="css" name="style.css"/>
</h:head>
<h:body style="background-image: url('https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&amp;w=2069&amp;auto=format&amp;fit=crop'); background-size: cover;">
    <div style="background: rgba(255,255,255,0.85); max-width: 400px; margin: 80px auto; padding: 32px; border-radius: 16px; box-shadow: 0 4px 24px rgba(0,0,0,0.1);">
        <h1 style="text-align:center; font-size:2em; margin-bottom:16px;">Bienvenido a Sistema Integral de Movilidad Urbana</h1>
        <p style="text-align:center; margin-bottom:24px;">Tu sistema integral de movilidad urbana</p>
        <p:messages id="messages" showDetail="true" closable="true" />
        
        <h:form>
            <p:panelGrid columns="2" styleClass="ui-noborder">
                <p:outputLabel for="username" value="Usuario:" />
                <p:inputText id="username" value="#{loginBean.username}" required="true" label="Usuario"/>
                <p:outputLabel for="password" value="Contraseña:" />
                <p:password id="password" value="#{loginBean.password}" required="true" label="Contraseña"/>
            </p:panelGrid>
            <!-- Este botón ahora podrá encontrar el componente con id="messages" para actualizarlo -->
            <p:commandButton value="Iniciar Sesión" action="#{loginBean.iniciarSesion}" update="@form messages" style="width:100%; margin-top:12px;"/>
            <p:link outcome="/registro" value="Registrarse" style="margin-left:10px;"/>
        </h:form>
        <div style="text-align:center; margin-top:24px;">
            <a href="#" style="margin-right:10px;">Ayuda</a>
            <a href="#" style="margin-right:10px;">Explorar</a>
            <a href="#">Negocios</a>
        </div>
    </div>
</h:body>
</html>
EOF
# --- INICIO DEL CÓDIGO A AÑADIR ---
cat > "$WEBAPP_PATH/WEB-INF/glassfish-web.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE glassfish-web-app PUBLIC "-//GlassFish.org//DTD GlassFish Application Server 3.1 Servlet 3.0//EN" "http://glassfish.org/dtds/glassfish-web-app_3_0-1.dtd">
<glassfish-web-app>
    <property name="use-em-for-at-resource" value="false" />
</glassfish-web-app>
EOF
log "✅ Archivos de configuración creados con contenido mínimo."

log "Copiando librerías y creando scripts de build/deploy..."
cp -v "$JBCRYPT_JAR" "$WEBAPP_PATH/WEB-INF/lib/"
cp -v "$SOURCE_DIR/gson-2.8.9.jar" "$WEBAPP_PATH/WEB-INF/lib/"
cat > "$PROJECT_DIR/build.sh" << 'EOF'
#!/bin/bash
# build.sh - Versión final con validaciones explícitas y depuración de classpath.

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- CARGAR ENTORNO DEL PROYECTO ---
PROJECT_ENV_FILE="$HOME/.project-env"
if [ ! -f "$PROJECT_ENV_FILE" ]; then
    error "No se encontró el archivo de entorno '~/.project-env'."
fi
source "$PROJECT_ENV_FILE"

if [ "$PWD" != "$PROJECT_DIR" ]; then
    error "Ejecuta este script desde el directorio raíz del proyecto: $PROJECT_DIR"
fi

# --- VARIABLES DE BUILD ---
BUILD_DIR="target"
CLASSES_DIR="$BUILD_DIR/WEB-INF/classes"
SRC_DIR="src/main/java"
RESOURCES_DIR="src/main/resources"
WEBAPP_DIR="src/main/webapp"
WAR_FILE="$BUILD_DIR/$PROJECT_NAME.war"
LIB_DIR="$WEBAPP_DIR/WEB-INF/lib"

# =================================================================
# 1. LIMPIEZA
# =================================================================
log "Limpiando directorio de construcción anterior ('target')..."
rm -rf "$BUILD_DIR"
mkdir -p "$CLASSES_DIR"

# =================================================================
# 2. CONSTRUCCIÓN DEL CLASSPATH Y VALIDACIÓN
# =================================================================
log "Construyendo classpath y validando dependencias..."

GF_CLIENT_JAR="$GLASSFISH_HOME/glassfish/lib/gf-client.jar"
JSF_API_JAR=$(find "$GLASSFISH_HOME" -name "javax.faces.jar" | head -n 1)
JAXRS_API_JAR=$(find "$GLASSFISH_HOME" -name "javax.ws.rs-api.jar" | head -n 1)
BEAN_VALIDATION_API_JAR=$(find "$GLASSFISH_HOME" -name "bean-validator.jar" | head -n 1)
PRIMEFACES_JAR=$(find "$GLASSFISH_HOME/glassfish/domains/domain1/lib" -name "primefaces*.jar" | head -n 1)

# --- VALIDACIONES ---
if [ -z "$JSF_API_JAR" ]; then error "javax.faces.jar no encontrado."; fi
if [ -z "$JAXRS_API_JAR" ]; then error "javax.ws.rs-api.jar no encontrado."; fi
if [ -z "$BEAN_VALIDATION_API_JAR" ]; then error "bean-validator.jar no encontrado."; fi
if [ -z "$PRIMEFACES_JAR" ]; then error "primefaces.jar no encontrado en el dominio."; fi

# =================================================================
# == CORRECCIÓN CLAVE: Construir el classpath de librerías del proyecto ==
# =================================================================
PROJECT_LIBS=""
if [ -d "$LIB_DIR" ] && [ "$(ls -A "$LIB_DIR")" ]; then
    # Bucle para encontrar todos los .jar y añadirlos al classpath
    for jar in "$LIB_DIR"/*.jar; do
        PROJECT_LIBS="$PROJECT_LIBS:$jar"
    done
fi
log "  [✔] Librerías del proyecto encontradas: $PROJECT_LIBS"
# =================================================================

# Ensamblar el CLASSPATH final.
CLASSPATH="${GF_CLIENT_JAR}:${JSF_API_JAR}:${JAXRS_API_JAR}:${BEAN_VALIDATION_API_JAR}:${PRIMEFACES_JAR}${PROJECT_LIBS}"
log "Classpath final para compilación: $CLASSPATH"

# =================================================================
# 3. COMPILACIÓN
# =================================================================
log "Copiando recursos (si existen)..."
if [ -d "$RESOURCES_DIR" ] && [ "$(ls -A $RESOURCES_DIR)" ]; then
    cp -r "$RESOURCES_DIR"/* "$CLASSES_DIR/"
fi

log "Compilando el código fuente de Java..."
find "$SRC_DIR" -name "*.java" -print0 | xargs -0 --no-run-if-empty javac -d "$CLASSES_DIR" -cp "$CLASSPATH"
if [ $? -ne 0 ]; then
    error "Falló la compilación. Revisa los errores del compilador más arriba."
fi
log "Compilación completada sin errores."

# =================================================================
# 4. EMPAQUETADO
# =================================================================
log "Empaquetando la aplicación en un archivo .war..."
cp -r "$WEBAPP_DIR"/* "$BUILD_DIR/"
(cd "$BUILD_DIR" && jar -cvf "../$WAR_FILE" .) > /dev/null

if [ ! -f "$WAR_FILE" ]; then
    error "Falló la creación del archivo WAR."
fi

log "🎉 ¡Construcción completada! El archivo final es: ${YELLOW}$WAR_FILE${NC}"
EOF

cat > "$PROJECT_DIR/deploy.sh" << 'EOF'
#!/bin/bash
set -euo pipefail
source "$HOME/.project-env"
if [ "$PWD" != "$PROJECT_DIR" ]; then 
    echo -e "\033[0;31m[ERROR]\033[0m Ejecuta este script desde $PROJECT_DIR"
    exit 1
fi
echo "🚀 Construyendo el proyecto..."
./build.sh

WAR_FILE="target/$PROJECT_NAME.war"
if [ ! -f "$WAR_FILE" ]; then 
    echo -e "\033[0;31m[ERROR]\033[0m No se generó el archivo WAR."
    exit 1
fi
echo "🚀 Desplegando en GlassFish (sin autenticación)..."
ASADMIN="$GLASSFISH_HOME/bin/asadmin"
"$ASADMIN" deploy --force=true "$WAR_FILE"
echo ""
echo -e "\033[0;32m🎉 ¡Listo! Accede a tu aplicación en: http://localhost:8080/$PROJECT_NAME\033[0m"
EOF
chmod +x "$PROJECT_DIR/build.sh" "$PROJECT_DIR/deploy.sh"
echo ""
log "================================================================"
log "¡ESTRUCTURA DEL PROYECTO '$PROJECT_NAME' CREADA EXITOSAMENTE!"
log "================================================================"
echo "   Ahora puedes ejecutar los scripts de módulo (1-modulo-..., etc.)"
echo "   para poblar el proyecto con código."