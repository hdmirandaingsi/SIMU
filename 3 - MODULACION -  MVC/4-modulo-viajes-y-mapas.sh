#!/bin/bash
# 4-modulo-viajes-y-mapas.sh
#
# DESCRIPCIÓN:
#   Implementa el Módulo 4: Planificación de Viajes y Mapas.
#   Crea las entidades, servicios y vistas para que un pasajero pueda:
#   - Consultar rutas entre dos paradas.
#   - Visualizar una ruta y sus paradas en un mapa interactivo (usando Leaflet.js).
#
# IDEMPOTENCIA:
#   Este script sobrescribe los archivos existentes del módulo con la
#   implementación completa, garantizando un estado consistente.

set -euo pipefail

# --- COLORES Y FUNCIONES DE LOG ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header() { echo -e "${CYAN}--- $1 ---${NC}"; }

# --- 1. CARGAR Y VALIDAR CONFIGURACIÓN DEL ENTORNO ---
header "Cargando y validando entorno del proyecto"
PROJECT_ENV_FILE="$HOME/.project-env"
if [ ! -f "$PROJECT_ENV_FILE" ]; then error "No se encontró ~/.project-env."; fi
source "$PROJECT_ENV_FILE"
if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_DIR" ]; then error "Variables del proyecto no definidas."; fi
log "Entorno cargado para el proyecto: ${YELLOW}$PROJECT_NAME${NC}"

# --- 2. DEFINIR RUTAS Y PAQUETES ---
cd "$PROJECT_DIR" || error "No se pudo cambiar al directorio del proyecto: $PROJECT_DIR"

PACKAGE_ROOT="com.$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"
BASE_PACKAGE_PATH="src/main/java/$(echo "$PACKAGE_ROOT" | tr '.' '/')"
RESOURCES_PATH="src/main/resources"
WEBAPP_PATH="src/main/webapp"

# --- 3. IMPLEMENTACIÓN DEL MÓDULO DE VIAJES Y MAPAS ---
header "Implementando Módulo 4: Viajes y Mapas"

# =================================================================
# CAPA DE SERVICIOS Y DTOs
# =================================================================
log "Creando Servicios y DTOs"

# --- PlanificacionService.java ---
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

    @Inject
    private RutaDAO rutaDAO;
    @Inject
    private ParadaDAO paradaDAO;
    
    public List<Ruta> encontrarRutasDirectas(Long idParadaOrigen, Long idParadaDestino) {
        List<Ruta> todasLasRutas = rutaDAO.findAll();
        
        return todasLasRutas.stream()
            .filter(ruta -> {
                // Convertir el Set de paradas a una lista de IDs para buscar fácilmente
                List<Long> idsParadasEnRuta = ruta.getParadas().stream()
                                                    .map(Parada::getId)
                                                    .collect(Collectors.toList());
                // La ruta es válida si contiene AMBAS paradas
                return idsParadasEnRuta.contains(idParadaOrigen) && idsParadasEnRuta.contains(idParadaDestino);
            })
            .collect(Collectors.toList());
    }
    
    public List<Parada> obtenerTodasLasParadas() {
        return paradaDAO.findAll();
    }
}
EOF

# --- DTO (Data Transfer Object) para el mapa ---
# --- UbicacionAutobusDTO.java ---
cat > "$BASE_PACKAGE_PATH/viajes/dto/UbicacionAutobusDTO.java" << 'EOF'
package com.simu.viajes.dto;

import java.io.Serializable;

// Este DTO se usaría para enviar datos de ubicación en tiempo real al frontend.
// Por ahora, es un placeholder para la estructura.
public class UbicacionAutobusDTO implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long idAutobus;
    private String matricula;
    private double latitud;
    private double longitud;

    public UbicacionAutobusDTO(Long idAutobus, String matricula, double latitud, double longitud) {
        this.idAutobus = idAutobus;
        this.matricula = matricula;
        this.latitud = latitud;
        this.longitud = longitud;
    }
    
    // Getters y Setters
    public Long getIdAutobus() { return idAutobus; }
    public void setIdAutobus(Long idAutobus) { this.idAutobus = idAutobus; }
    public String getMatricula() { return matricula; }
    public void setMatricula(String matricula) { this.matricula = matricula; }
    public double getLatitud() { return latitud; }
    public void setLatitud(double latitud) { this.latitud = latitud; }
    public double getLongitud() { return longitud; }
    public void setLongitud(double longitud) { this.longitud = longitud; }
}
EOF


# =================================================================
# CAPA DE PRESENTACIÓN (BEANS Y XHTML)
# =================================================================
log "Creando Managed Beans: PlanificadorBean.java"

# --- PlanificadorBean.java ---
cat > "$BASE_PACKAGE_PATH/viajes/bean/PlanificadorBean.java" << 'EOF'
package com.simu.viajes.bean;

import com.simu.rutas.entity.Parada;
import com.simu.rutas.entity.Ruta;
import com.simu.viajes.service.PlanificacionService;
import org.primefaces.shaded.json.JSONArray;
import org.primefaces.shaded.json.JSONObject;

import javax.annotation.PostConstruct;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import java.util.List;

@Named
@ViewScoped
public class PlanificadorBean implements Serializable {
    private static final long serialVersionUID = 1L;

    @Inject
    private PlanificacionService planificacionService;

    private List<Parada> paradasDisponibles;
    private Long idParadaOrigen;
    private Long idParadaDestino;
    private List<Ruta> rutasEncontradas;
    
    private String paradasJson = "[]"; // Para pasar los datos de las paradas al mapa

    @PostConstruct
    public void init() {
        paradasDisponibles = planificacionService.obtenerTodasLasParadas();
    }

    public void buscarRutas() {
        rutasEncontradas = planificacionService.encontrarRutasDirectas(idParadaOrigen, idParadaDestino);
    }
    
    public void visualizarRutaEnMapa(Ruta ruta) {
        // Convertir las paradas de la ruta seleccionada a formato JSON para Leaflet
        JSONArray paradasArray = new JSONArray();
        if (ruta != null && ruta.getParadas() != null) {
            for (Parada p : ruta.getParadas()) {
                if(p.getLatitud() != null && p.getLongitud() != null) {
                    JSONObject paradaJson = new JSONObject();
                    paradaJson.put("lat", p.getLatitud());
                    paradaJson.put("lng", p.getLongitud());
                    paradaJson.put("nombre", p.getNombre());
                    paradasArray.put(paradaJson);
                }
            }
        }
        this.paradasJson = paradasArray.toString();
    }

    // Getters y Setters
    public List<Parada> getParadasDisponibles() { return paradasDisponibles; }
    public Long getIdParadaOrigen() { return idParadaOrigen; }
    public void setIdParadaOrigen(Long idParadaOrigen) { this.idParadaOrigen = idParadaOrigen; }
    public Long getIdParadaDestino() { return idParadaDestino; }
    public void setIdParadaDestino(Long idParadaDestino) { this.idParadaDestino = idParadaDestino; }
    public List<Ruta> getRutasEncontradas() { return rutasEncontradas; }
    public String getParadasJson() { return paradasJson; }
}
EOF

log "Creando Vista XHTML: pasajero/planificarViaje.xhtml"

# --- pasajero/planificarViaje.xhtml ---
cat > "$WEBAPP_PATH/pasajero/planificarViaje.xhtml" << 'EOF'
<ui:composition template="/template.xhtml"
      xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:f="http://xmlns.jcp.org/jsf/core"
      xmlns:p="http://primefaces.org/ui">
      
    <ui:define name="title">Planificar Viaje</ui:define>

    <ui:define name="content">
        <!-- Librerías para el mapa Leaflet -->
        <h:outputStylesheet name="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
        <h:outputScript name="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js" />
        
        <style>
            #map { height: 400px; }
        </style>

        <h:form id="formPlanificador">
            <p:panel header="Encuentra tu Ruta">
                <p:panelGrid columns="3" styleClass="ui-noborder">
                    <p:outputLabel for="origen" value="Parada de Origen:"/>
                    <p:selectOneMenu id="origen" value="#{planificadorBean.idParadaOrigen}" filter="true" filterMatchMode="contains">
                        <f:selectItem itemLabel="Selecciona origen" itemValue="#{null}" />
                        <f:selectItems value="#{planificadorBean.paradasDisponibles}" var="parada" 
                                       itemLabel="#{parada.nombre}" itemValue="#{parada.id}"/>
                    </p:selectOneMenu>
                    <p:message for="origen"/>

                    <p:outputLabel for="destino" value="Parada de Destino:"/>
                    <p:selectOneMenu id="destino" value="#{planificadorBean.idParadaDestino}" filter="true" filterMatchMode="contains">
                        <f:selectItem itemLabel="Selecciona destino" itemValue="#{null}" />
                        <f:selectItems value="#{planificadorBean.paradasDisponibles}" var="parada" 
                                       itemLabel="#{parada.nombre}" itemValue="#{parada.id}"/>
                    </p:selectOneMenu>
                    <p:message for="destino"/>
                </p:panelGrid>
                <p:commandButton value="Buscar Rutas" actionListener="#{planificadorBean.buscarRutas}" update="panelResultados"/>
            </p:panel>
            
            <p:panel id="panelResultados" header="Rutas Disponibles" style="margin-top:20px;">
                <p:dataTable value="#{planificadorBean.rutasEncontradas}" var="ruta"
                             emptyMessage="No se encontraron rutas directas.">
                    <p:column headerText="Nombre Ruta">
                        <h:outputText value="#{ruta.nombre}"/>
                    </p:column>
                    <p:column headerText="Descripción">
                        <h:outputText value="#{ruta.descripcion}"/>
                    </p:column>
                     <p:column headerText="Ver en Mapa">
                        <p:commandButton icon="pi pi-map-marker" title="Visualizar Ruta"
                                         actionListener="#{planificadorBean.visualizarRutaEnMapa(ruta)}"
                                         update="panelMapa" oncomplete="PF('mapaDialog').show(); initMap();"/>
                    </p:column>
                </p:dataTable>
            </p:panel>
        </h:form>
        
        <p:dialog widgetVar="mapaDialog" header="Visualización de Ruta" width="80%" height="500" modal="true">
            <h:panelGroup id="panelMapa">
                <div id="map"></div>
                <!-- Pasamos los datos de las paradas desde el bean a JavaScript -->
                <h:inputHidden id="paradasData" value="#{planificadorBean.paradasJson}"/>
            </h:panelGroup>
        </p:dialog>

        <script>
            var map; // Variable global para el mapa
            var polyline;
            var markers = [];

            function initMap() {
                // Prevenir reinicialización si el mapa ya existe
                if (map) {
                    map.remove();
                }
                
                // Coordenadas centrales por defecto (ej. San Salvador)
                map = L.map('map').setView([13.6929, -89.2182], 13);
                
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '&amp;copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                }).addTo(map);

                // Limpiar marcadores y línea anteriores
                if (polyline) map.removeLayer(polyline);
                markers.forEach(marker => map.removeLayer(marker));
                markers = [];

                // Obtener datos de paradas del campo oculto y parsearlos
                var paradasDataField = document.getElementById('formPlanificador:paradasData');
                if (!paradasDataField) {
                     // Si el ID cambia por JSF, buscar por otro medio
                     paradasDataField = $('[id$=paradasData]');
                }

                try {
                     var paradas = JSON.parse(paradasDataField.value);
                     var latlngs = [];
                     
                     if(paradas.length > 0) {
                         paradas.forEach(function(p) {
                             var latlng = [p.lat, p.lng];
                             latlngs.push(latlng);
                             var marker = L.marker(latlng).addTo(map).bindPopup(p.nombre);
                             markers.push(marker);
                         });
                         
                         // Dibujar la línea que conecta las paradas
                         polyline = L.polyline(latlngs, {color: 'blue'}).addTo(map);
                         
                         // Ajustar el zoom del mapa para que se vea toda la ruta
                         map.fitBounds(polyline.getBounds());
                     }
                } catch (e) {
                    console.error("Error al parsear datos de paradas: ", e);
                }
            }
        </script>
    </ui:define>
</ui:composition>
EOF

# --- 4. MENSAJE FINAL ---
echo ""
header "Módulo 4: Viajes y Mapas - IMPLEMENTACIÓN COMPLETA"
log "Se han creado las funcionalidades para planificar viajes y visualizarlos."
warn "Para probar, asegúrate de tener varias paradas y al menos una ruta que las conecte, creadas desde el panel de administración."
echo ""
log "Para construir y desplegar los cambios, ejecuta:"
echo -e "   ${YELLOW}cd $PROJECT_DIR && ./deploy.sh${NC}"