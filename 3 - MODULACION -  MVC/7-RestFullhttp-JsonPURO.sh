#!/bin/bash
# 7-RestFullhttp.sh
#
# DESCRIPCIÓN:
#   Rellena los archivos REST vacíos generados por p07-MVC-estructura-carpetas-archivos.sh
#   Ubica la API REST al mismo nivel que los demás módulos: com/simu/api/
#
# MÓDULO: 8 (RESTful API)
# ESTILO: MVC + JAX-RS + JSON puro
# IDEMPOTENTE: Sobrescribe sin duplicar

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header() { echo -e "${CYAN}--- $1 ---${NC}"; }

# --- 1. CARGAR Y VALIDAR CONFIGURACIÓN DEL ENTORNO ---
header "Cargando y validando entorno del proyecto"
PROJECT_ENV_FILE="$HOME/.project-env"
if [ ! -f "$PROJECT_ENV_FILE" ]; then
    error "No se encontró ~/.project-env. Ejecuta los scripts de configuración previos."
fi
source "$PROJECT_ENV_FILE"

if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_DIR" ]; then
    error "Las variables PROJECT_NAME o PROJECT_DIR no están definidas en ~/.project-env."
fi
log "Entorno cargado para el proyecto: ${YELLOW}$PROJECT_NAME${NC}"

# --- 2. DEFINIR RUTAS Y PAQUETES ---
cd "$PROJECT_DIR" || error "No se pudo cambiar al directorio del proyecto: $PROJECT_DIR"

PACKAGE_ROOT="com.$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"
BASE_PACKAGE_PATH="src/main/java/$(echo "$PACKAGE_ROOT" | tr '.' '/')"
API_PATH="$BASE_PACKAGE_PATH/api"

# =================================================================
# RELLENAR ARCHIVOS REST EN com/simu/api/
# =================================================================
log "Rellenando archivos REST en $API_PATH"

# --- UsuarioResource.java ---
cat > "$API_PATH/resource/UsuarioResource.java" << EOF
package ${PACKAGE_ROOT}.api.resource;

import ${PACKAGE_ROOT}.api.dto.UsuarioDTO;
import ${PACKAGE_ROOT}.usuarios.dao.UsuarioDAO;
import ${PACKAGE_ROOT}.usuarios.entity.Usuario;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.List;
import java.util.stream.Collectors;

@Path("/usuarios")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UsuarioResource {

    @Inject
    private UsuarioDAO usuarioDAO;

    @GET
    public List<UsuarioDTO> listar() {
        return usuarioDAO.findAll().stream()
                .map(u -> new UsuarioDTO(u.getId(), u.getUsername(), u.getNombreCompleto(), u.getEmail(), u.getRol().getNombre()))
                .collect(Collectors.toList());
    }

    @GET
    @Path("/{id}")
    public Response obtener(@PathParam("id") Long id) {
        Usuario u = usuarioDAO.findById(id);
        if (u == null) return Response.status(Response.Status.NOT_FOUND).build();
        UsuarioDTO dto = new UsuarioDTO(u.getId(), u.getUsername(), u.getNombreCompleto(), u.getEmail(), u.getRol().getNombre());
        return Response.ok(dto).build();
    }
}
EOF

 

# --- BilleteraResource.java ---
cat > "$API_PATH/resource/BilleteraResource.java" << 'EOF'
package com.simu.api.resource;

import com.simu.billetera.service.BilleteraService;
import com.simu.usuarios.entity.Usuario;
import com.simu.billetera.entity.Tarjeta;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.math.BigDecimal;

@Path("/billetera")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class BilleteraResource {

    @Inject
    private BilleteraService billeteraService;

    @GET
    @Path("/{usuarioId}")
    public Response obtenerSaldo(@PathParam("usuarioId") Long usuarioId) {
        Tarjeta tarjeta = billeteraService.obtenerOCrearTarjeta(new Usuario() {{ setId(usuarioId); }});
        return Response.ok("{\"saldo\":\"" + tarjeta.getSaldo() + "\"}").build();
    }

    @POST
    @Path("/recargar")
    public Response recargar(@QueryParam("usuarioId") Long usuarioId,
                             @QueryParam("monto") BigDecimal monto) {
        try {
            billeteraService.recargarSaldo(usuarioId, monto);
            return Response.ok("{\"mensaje\":\"Recarga exitosa\"}").build();
        } catch (Exception e) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\":\"" + e.getMessage() + "\"}").build();
        }
    }
}
EOF

# --- ViajeResource.java ---
cat > "$API_PATH/resource/ViajeResource.java" << 'EOF'
package com.simu.api.resource;

import com.simu.api.dto.ViajeDTO;
import com.simu.viajes.dao.ViajeDAO;
import com.simu.viajes.entity.Viaje;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import java.util.List;
import java.util.stream.Collectors;

@Path("/viajes")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ViajeResource {

    @Inject
    private ViajeDAO viajeDAO;

    @GET
    public List<ViajeDTO> listar(@QueryParam("usuarioId") Long usuarioId) {
        List<Viaje> viajes = usuarioId != null ? viajeDAO.findByUsuarioId(usuarioId) : viajeDAO.findAll();
        return viajes.stream()
                .map(v -> new ViajeDTO(v.getId(), v.getFechaHora(),
                        v.getRuta() != null ? v.getRuta().getNombre() : null,
                        v.getAutobus().getMatricula(),
                        v.getCostoPasaje()))
                .collect(Collectors.toList());
    }
}
EOF

# --- RutaResource.java ---
cat > "$API_PATH/resource/RutaResource.java" << 'EOF'
package com.simu.api.resource;

import com.simu.rutas.dao.RutaDAO;
import com.simu.rutas.entity.Ruta;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.List;

@Path("/rutas")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class RutaResource {

    @Inject
    private RutaDAO rutaDAO;

    @GET
    public List<Ruta> listar() {
        return rutaDAO.findAll();
    }

    @GET
    @Path("/{id}")
    public Response obtener(@PathParam("id") Long id) {
        Ruta r = rutaDAO.findById(id);
        return r != null ? Response.ok(r).build() : Response.status(Response.Status.NOT_FOUND).build();
    }
}
EOF

# --- FlotaResource.java ---
cat > "$API_PATH/resource/FlotaResource.java" << 'EOF'
package com.simu.api.resource;

import com.simu.flota.dao.AutobusDAO;
import com.simu.flota.entity.Autobus;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.List;

@Path("/flota")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class FlotaResource {

    @Inject
    private AutobusDAO autobusDAO;

    @GET
    public List<Autobus> listar() {
        return autobusDAO.findAll();
    }

    @GET
    @Path("/{id}")
    public Response obtener(@PathParam("id") Long id) {
        Autobus a = autobusDAO.findById(id);
        return a != null ? Response.ok(a).build() : Response.status(Response.Status.NOT_FOUND).build();
    }
}
EOF

# --- HistorialResource.java ---
cat > "$API_PATH/resource/HistorialResource.java" << 'EOF'
package com.simu.api.resource;

import com.simu.api.dto.ViajeDTO;
import com.simu.viajes.dao.ViajeDAO;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import java.util.List;
import java.util.stream.Collectors;

@Path("/historial")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class HistorialResource {

    @Inject
    private ViajeDAO viajeDAO;

    @GET
    public List<ViajeDTO> obtenerHistorial(@QueryParam("usuarioId") Long usuarioId) {
        return viajeDAO.findByUsuarioId(usuarioId).stream()
                .map(v -> new ViajeDTO(v.getId(), v.getFechaHora(),
                        v.getRuta() != null ? v.getRuta().getNombre() : null,
                        v.getAutobus().getMatricula(),
                        v.getCostoPasaje()))
                .collect(Collectors.toList());
    }
}
EOF

# --- ReporteResource.java ---
cat > "$API_PATH/resource/ReporteResource.java" << 'EOF'
package com.simu.api.resource;

import com.simu.reportes.dto.IngresosPorRutaDTO;
import com.simu.reportes.dto.PasajerosHoraPicoDTO;
import com.simu.reportes.service.AnaliticaService;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import java.util.List;

@Path("/reportes")
@Produces(MediaType.APPLICATION_JSON)
public class ReporteResource {

    @Inject
    private AnaliticaService analiticaService;

    @GET
    @Path("/ingresos-por-ruta")
    public List<IngresosPorRutaDTO> ingresosPorRuta() {
        return analiticaService.getIngresosTotalesPorRuta();
    }

    @GET
    @Path("/viajes-por-hora")
    public List<PasajerosHoraPicoDTO> viajesPorHora() {
        return analiticaService.getDistribucionViajesPorHora();
    }

    @GET
    @Path("/totales")
    public TotalesDTO totales() {
        return new TotalesDTO(analiticaService.getTotalPasajeros(), analiticaService.getTotalViajes());
    }

    public static class TotalesDTO {
        public final long totalPasajeros;
        public final long totalViajes;

        public TotalesDTO(long totalPasajeros, long totalViajes) {
            this.totalPasajeros = totalPasajeros;
            this.totalViajes = totalViajes;
        }
    }
}
EOF

# --- RestExceptionHandler.java ---
cat > "$API_PATH/exception/RestExceptionHandler.java" << 'EOF'
package com.simu.api.exception;

import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

@Provider
public class RestExceptionHandler implements ExceptionMapper<Exception> {
    @Override
    public Response toResponse(Exception ex) {
        return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity("{\"error\":\"" + ex.getMessage() + "\"}")
                .build();
    }
}
EOF

# --- UsuarioDTO.java ---
cat > "$API_PATH/dto/UsuarioDTO.java" << 'EOF'
package com.simu.api.dto;

import java.io.Serializable;

public class UsuarioDTO implements Serializable {
    private Long id;
    private String username;
    private String nombreCompleto;
    private String email;
    private String rol;

    public UsuarioDTO() {}

    public UsuarioDTO(Long id, String username, String nombreCompleto, String email, String rol) {
        this.id = id;
        this.username = username;
        this.nombreCompleto = nombreCompleto;
        this.email = email;
        this.rol = rol;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getNombreCompleto() { return nombreCompleto; }
    public void setNombreCompleto(String nombreCompleto) { this.nombreCompleto = nombreCompleto; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getRol() { return rol; }
    public void setRol(String rol) { this.rol = rol; }
}
EOF

# --- ViajeDTO.java ---
cat > "$API_PATH/dto/ViajeDTO.java" << 'EOF'
package com.simu.api.dto;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

public class ViajeDTO implements Serializable {
    private Long id;
    private Date fechaHora;
    private String rutaNombre;
    private String autobusMatricula;
    private BigDecimal costoPasaje;

    public ViajeDTO() {}

    public ViajeDTO(Long id, Date fechaHora, String rutaNombre, String autobusMatricula, BigDecimal costoPasaje) {
        this.id = id;
        this.fechaHora = fechaHora;
        this.rutaNombre = rutaNombre;
        this.autobusMatricula = autobusMatricula;
        this.costoPasaje = costoPasaje;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Date getFechaHora() { return fechaHora; }
    public void setFechaHora(Date fechaHora) { this.fechaHora = fechaHora; }
    public String getRutaNombre() { return rutaNombre; }
    public void setRutaNombre(String rutaNombre) { this.rutaNombre = rutaNombre; }
    public String getAutobusMatricula() { return autobusMatricula; }
    public void setAutobusMatricula(String autobusMatricula) { this.autobusMatricula = autobusMatricula; }
    public BigDecimal getCostoPasaje() { return costoPasaje; }
    public void setCostoPasaje(BigDecimal costoPasaje) { this.costoPasaje = costoPasaje; }
}
EOF

# =================================================================
# MENSAJE FINAL
# =================================================================
echo ""
header "✅ Módulo 8: API RESTful - RELLENO COMPLETO"
log "Todos los archivos REST vacíos han sido rellenados con código JAX-RS funcional."
log "Tu API está lista para ser consumida por tu app Android (Kotlin/Java)."
echo ""
log "Endpoints disponibles:"
echo -e "   ${YELLOW}GET  /api/usuarios${NC}"
echo -e "   ${YELLOW}GET  /api/usuarios/{id}${NC}"
echo -e "   ${YELLOW}GET  /api/billetera/{usuarioId}${NC}"
echo -e "   ${YELLOW}POST /api/billetera/recargar?usuarioId=X&monto=Y${NC}"
echo -e "   ${YELLOW}GET  /api/viajes?usuarioId=X${NC}"
echo -e "   ${YELLOW}GET  /api/rutas${NC}"
echo -e "   ${YELLOW}GET  /api/flota${NC}"
echo -e "   ${YELLOW}GET  /api/historial?usuarioId=X${NC}"
echo -e "   ${YELLOW}GET  /api/reportes/totales${NC}"
echo ""
log "Para construir y desplegar:"
echo -e "   ${YELLOW}cd $PROJECT_DIR && ./deploy.sh${NC}"