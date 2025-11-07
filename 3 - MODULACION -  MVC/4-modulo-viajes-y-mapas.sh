#!/bin/bash
# 4-modulo-viajes-y-mapas.sh (VERSIÓN JDBC)
# Implementa el Módulo 4: Viajes y Mapas.

set -euo pipefail

# --- SECCIÓN INICIAL ---
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
WEBAPP_PATH="src/main/webapp"


# --- IMPLEMENTACIÓN DEL MÓDULO ---
header "Implementando Módulo 4: Viajes y Mapas (JDBC)"

log "[M4] Creando Servicios, DTOs y Beans"
cat > "$BASE_PACKAGE_PATH/viajes/service/PlanificacionService.java" << 'EOF'
package com.simu.viajes.service;
import com.simu.rutas.dao.ParadaDAO;
import com.simu.rutas.dao.RutaDAO;
import com.simu.rutas.entity.Parada;
import com.simu.rutas.entity.Ruta;
import javax.ejb.Stateless;
import javax.inject.Inject;
import java.util.List;
import java.util.stream.Collectors;
@Stateless
public class PlanificacionService {
    @Inject private RutaDAO rutaDAO;
    @Inject private ParadaDAO paradaDAO;
        public List<Ruta> encontrarRutasDirectas(Long idParadaOrigen, Long idParadaDestino) {
        // Ahora simplemente delegamos la búsqueda a la nueva consulta eficiente del DAO
        return rutaDAO.findRutasContainingParadas(idParadaOrigen, idParadaDestino);
    }  
    public List<Parada> obtenerTodasLasParadas() { return paradaDAO.findAll(); }
}
EOF
cat > "$BASE_PACKAGE_PATH/viajes/dto/UbicacionAutobusDTO.java" << 'EOF'
package com.simu.viajes.dto;
import java.io.Serializable;
public class UbicacionAutobusDTO implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long idAutobus;
    private String matricula;
    private double latitud;
    private double longitud;
    public UbicacionAutobusDTO(Long id, String m, double lat, double lon) { this.idAutobus = id; this.matricula = m; this.latitud = lat; this.longitud = lon; }
    public Long getIdAutobus() { return idAutobus; }
    public String getMatricula() { return matricula; }
    public double getLatitud() { return latitud; }
    public double getLongitud() { return longitud; }
}
EOF
cat > "$BASE_PACKAGE_PATH/viajes/bean/PlanificadorBean.java" << 'EOF'
package com.simu.viajes.bean;

import com.google.gson.Gson;
import com.simu.rutas.entity.Parada;
import com.simu.rutas.entity.Ruta;
import com.simu.viajes.service.PlanificacionService;
import javax.annotation.PostConstruct;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Named @ViewScoped
public class PlanificadorBean implements Serializable {
    private static final long serialVersionUID = 1L;
    
    @Inject private PlanificacionService planificacionService;
    
    private List<Parada> paradasDisponibles;
    private Long idParadaOrigen;
    private Long idParadaDestino;
    private List<Ruta> rutasEncontradas;
    private String paradasJson = "[]";
    
    private final Gson gson = new Gson();

    @PostConstruct 
    public void init() { 
        paradasDisponibles = planificacionService.obtenerTodasLasParadas(); 
    }
    
    public void buscarRutas() { 
        rutasEncontradas = planificacionService.encontrarRutasDirectas(idParadaOrigen, idParadaDestino); 
    }
    
    public void visualizarRutaEnMapa(Ruta ruta) {
        if (ruta != null && ruta.getParadas() != null && !ruta.getParadas().isEmpty()) {
            List<Parada> paradasConCoordenadas = ruta.getParadas().stream()
                .filter(p -> p.getLatitud() != null && p.getLongitud() != null)
                .collect(Collectors.toList());
            this.paradasJson = gson.toJson(paradasConCoordenadas);
        } else {
            this.paradasJson = "[]";
        }
    }
    public List<Parada> getParadasDisponibles() { return paradasDisponibles; }
    public Long getIdParadaOrigen() { return idParadaOrigen; }
    public Long getIdParadaDestino() { return idParadaDestino; }
    public List<Ruta> getRutasEncontradas() { return rutasEncontradas; }
    public String getParadasJson() { return paradasJson; }
    public void setIdParadaOrigen(Long id) { this.idParadaOrigen = id; }
    public void setIdParadaDestino(Long id) { this.idParadaDestino = id; }

    public void setParadasJson(String paradasJson) {
        this.paradasJson = paradasJson;
    }
}
EOF



log "Módulo 4 (JDBC) completado."