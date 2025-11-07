#!/bin/bash
# 10-RestFullhttp-JsonPURO.sh
#
# Propósito:
# Implementa una capa de API RESTful usando JAX-RS (el estándar de Java EE).
# Esto permite que otras aplicaciones (móviles, webs de terceros, etc.)
# consuman los datos y la lógica de negocio de la aplicación SIMU.
#
# Características:
# - Crea la estructura de paquetes para la API.
# - Implementa la clase de configuración de JAX-RS.
# - Crea un "Resource" (endpoint) para el historial de viajes como ejemplo.
# - Crea un DTO (Data Transfer Object) para una respuesta de autenticación segura.
# - Añade un endpoint de autenticación que devuelve un token (simulado).

set -euo pipefail

# --- SECCIÓN INICIAL (COLORES, LOGS, CARGA DE ENTORNO) ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
header() { echo -e "${CYAN}--- $1 ---${NC}"; }

# Carga la configuración del proyecto
PROJECT_ENV_FILE="$HOME/.project-env"
if [ ! -f "$PROJECT_ENV_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Archivo de entorno no encontrado en ~/.project-env"
    exit 1
fi
source "$PROJECT_ENV_FILE"

# VERIFICACIÓN CRÍTICA: Cambia al directorio del proyecto. Si falla, el script se detiene.
log "Cambiando al directorio del proyecto: $PROJECT_DIR"
cd "$PROJECT_DIR" || { echo -e "${RED}[ERROR]${NC} No se pudo cambiar al directorio del proyecto: $PROJECT_DIR"; exit 1; }

# Define variables de ruta basadas en la ubicación actual (que ahora es el directorio del proyecto)
PACKAGE_ROOT="com.$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"
BASE_PACKAGE_PATH="src/main/java/$(echo "$PACKAGE_ROOT" | tr '.' '/')"


# --- IMPLEMENTACIÓN DEL MÓDULO ---
header "Implementando Módulo 10: API RESTful con JAX-RS"

# =================================================================
# 1. CREACIÓN DE DIRECTORIOS Y ARCHIVOS
# =================================================================
log "[M10] 1/3: Creando estructura de directorios y archivos para la API..."

# Crear directorios. La opción -p evita errores si ya existen.
mkdir -p "$BASE_PACKAGE_PATH/api"
mkdir -p "$BASE_PACKAGE_PATH/api/config"
mkdir -p "$BASE_PACKAGE_PATH/api/dto"
mkdir -p "$BASE_PACKAGE_PATH/api/resource"

# Crear archivos vacíos con touch para definir la estructura
touch "$BASE_PACKAGE_PATH/api/config/JAXRSConfiguration.java"
touch "$BASE_PACKAGE_PATH/api/dto/AuthRequestDTO.java"
touch "$BASE_PACKAGE_PATH/api/dto/AuthResponseDTO.java"
touch "$BASE_PACKAGE_PATH/api/resource/AuthResource.java"
touch "$BASE_PACKAGE_PATH/api/resource/HistorialResource.java"

log "Estructura de la API creada."

# =================================================================
# 2. CREACIÓN DE LOS DTOs (Data Transfer Objects)
# =================================================================
log "[M10] 2/3: Rellenando los DTOs para la API..."

cat > "$BASE_PACKAGE_PATH/api/dto/AuthRequestDTO.java" << 'EOF'
package com.simu.api.dto;
 
public class AuthRequestDTO {
    private String username;
    private String password;

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
}
EOF

cat > "$BASE_PACKAGE_PATH/api/dto/AuthResponseDTO.java" << 'EOF'
package com.simu.api.dto;

public class AuthResponseDTO {
    private String username;
    private String nombreCompleto;
    private String rol;
    private String token;

    public AuthResponseDTO(String username, String nombreCompleto, String rol, String token) {
        this.username = username;
        this.nombreCompleto = nombreCompleto;
        this.rol = rol;
        this.token = token;
    }

    // Getters y Setters
    public String getUsername() { return username; }
    public String getNombreCompleto() { return nombreCompleto; }
    public String getRol() { return rol; }
    public String getToken() { return token; }
}
EOF
log "DTOs creados."
log "[M10] 3/3: Rellenando la configuración y los endpoints de la API..."

# Clase de Configuración: Activa JAX-RS en la aplicación
cat > "$BASE_PACKAGE_PATH/api/config/JAXRSConfiguration.java" << 'EOF'
package com.simu.api.config;

import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;

/**
 * Esta clase activa JAX-RS en la aplicación.
 * La anotación @ApplicationPath define la URL base para todos los endpoints.
 * En este caso, todas las URLs de la API comenzarán con /api
 * Ejemplo: http://localhost:8080/SIMU/api/...
 */
@ApplicationPath("/api")
public class JAXRSConfiguration extends Application {
    // No se necesita añadir nada más aquí. La presencia de la clase es suficiente.
}
EOF

cat > "$BASE_PACKAGE_PATH/api/resource/AuthResource.java" << 'EOF'
package com.simu.api.resource;

import com.simu.api.dto.AuthRequestDTO;
import com.simu.api.dto.AuthResponseDTO;
import com.simu.usuarios.entity.Usuario;
import com.simu.usuarios.service.UsuarioService;
import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.UUID;

@Path("/auth")
public class AuthResource {

    @Inject
    private UsuarioService usuarioService;

    @POST
    @Path("/login")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response login(AuthRequestDTO authRequest) {
        try {
            Usuario usuario = usuarioService.autenticar(authRequest.getUsername(), authRequest.getPassword());

            if (usuario != null) {
                String token = UUID.randomUUID().toString();
                AuthResponseDTO responseDTO = new AuthResponseDTO(
                    usuario.getUsername(),
                    usuario.getNombreCompleto(),
                    usuario.getRol().getNombre(),
                    token
                );
                return Response.ok(responseDTO).build();
            } else {
                return Response.status(Response.Status.UNAUTHORIZED)
                               .entity("{\"error\":\"Usuario o contraseña incorrectos\"}")
                               .build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                           .entity("{\"error\":\"Ocurrió un error en el servidor\"}")
                           .build();
        }
    }
}
EOF

# Resource para Historial
cat > "$BASE_PACKAGE_PATH/api/resource/HistorialResource.java" << 'EOF'
package com.simu.api.resource;

import com.simu.historial.service.ConsultaHistorialService;
import com.simu.viajes.entity.Viaje;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.enterprise.context.RequestScoped;
import java.util.List;

@Path("/historial")
@RequestScoped
public class HistorialResource {

    @Inject
    private ConsultaHistorialService historialService;

    /**
     * Obtiene el historial de viajes de un usuario específico.
     * Este endpoint debería estar protegido para que solo el usuario
     * o un administrador pueda verlo (se haría con el token de autenticación).
     */
    @GET
    @Path("/usuario/{id}") // URL completa: GET /api/historial/usuario/1
    @Produces(MediaType.APPLICATION_JSON)
    public Response obtenerHistorialPorUsuario(@PathParam("id") Long usuarioId) {
        try {
            List<Viaje> historial = historialService.obtenerHistorialPorUsuario(usuarioId);
            if (historial == null || historial.isEmpty()) {
                return Response.status(Response.Status.NOT_FOUND)
                               .entity("{\"mensaje\":\"No se encontró historial para el usuario con ID " + usuarioId + "\"}")
                               .build();
            }
            // El servidor convierte automáticamente la List<Viaje> a un array JSON
            return Response.ok(historial).build();
        } catch (Exception e) {
            e.printStackTrace();
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                           .entity("{\"error\":\"Error al consultar el historial\"}")
                           .build();
        }
    }
}
EOF

log "Configuración y Endpoints de la API RESTful rellenados."
header "Módulo 10 implementado exitosamente."
echo -e "${YELLOW}¡ACCIÓN REQUERIDA! Ejecuta ./deploy.sh para aplicar los cambios.${NC}"
echo "Después de desplegar, puedes probar los endpoints:"
echo "1. GET: http://localhost:8080/SIMU/api/historial/usuario/1 (reemplaza '1' por un ID de usuario válido)"
echo "2. POST a http://localhost:8080/SIMU/api/auth/login con un JSON body como: {\"username\":\"tu_usuario\", \"password\":\"tu_clave\"}"