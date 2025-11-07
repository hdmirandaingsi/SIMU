#!/bin/bash
# 9-crear-vistas-finales.sh (Versión Corregida y Completa)
#
# Propósito:
# Crea y/o actualiza todas las vistas XHTML para los módulos funcionales
# de la aplicación (Billetera, Rutas, Mapas, Historial, Reportes).
# También finaliza el template principal con el menú de navegación completo.
#
# Mejoras:
# - Código XHTML validado y limpio.
# - Uso de componentes PrimeFaces para interfaces ricas (CRUD, mapas, gráficos).
# - Implementación del menú de navegación condicional basado en roles.
set -euo pipefail
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
header "Creando Vistas Finales de los Módulos (2 al 6)"
log "Creando vista de billetera del pasajero..."
cat > "$WEBAPP_PATH/pasajero/billetera.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:h="http://xmlns.jcp.org/jsf/html"
    xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
    xmlns:f="http://xmlns.jcp.org/jsf/core"
    xmlns:p="http://primefaces.org/ui">
    <ui:define name="title">Mi Billetera</ui:define>
    <ui:define name="content">
        <h:form id="formBilletera">
            <p:panel header="Gestión de Saldo">
                <p:panelGrid columns="2" styleClass="ui-noborder">
                    <h:outputText value="Saldo Actual:" style="font-weight: bold;" />
                    <h:outputText value="#{billeteraBean.tarjeta.saldo}">
                        <f:convertNumber type="currency" currencySymbol="$ " />
                    </h:outputText>
                </p:panelGrid>
            </p:panel>
            <p:spacer height="20" />
            <p:panel header="Recargar Saldo">
                <p:panelGrid columns="3" styleClass="ui-noborder">
                    <p:outputLabel for="monto" value="Monto a Recargar:"/>
                    <p:inputNumber id="monto" value="#{billeteraBean.montoRecarga}" symbol="$ " symbolPosition="p" decimalSeparator="." thousandSeparator="," minValue="0.01"/>
                    <p:commandButton value="Recargar" actionListener="#{billeteraBean.recargar}" update="formBilletera :messages"/>
                </p:panelGrid>
            </p:panel>
            <p:spacer height="20" />
            <p:panel header="Historial de Transacciones">
                <p:dataTable value="#{billeteraBean.tarjeta.transacciones}" var="tx" emptyMessage="No hay transacciones registradas." paginator="true" rows="10" sortBy="#{tx.fechaTransaccion}" sortOrder="descending">
                    <p:column headerText="Fecha">
                        <h:outputText value="#{tx.fechaTransaccion}"><f:convertDateTime pattern="dd/MM/yyyy HH:mm" /></h:outputText>
                    </p:column>
                    <p:column headerText="Tipo"><h:outputText value="#{tx.tipo}" /></p:column>
                    <p:column headerText="Descripción"><h:outputText value="#{tx.descripcion}" /></p:column>
                    <p:column headerText="Monto" style="text-align:right">
                        <h:outputText value="#{tx.monto}" styleClass="#{tx.monto gt 0 ? 'green-text' : 'red-text'}">
                            <f:convertNumber type="currency" currencySymbol="$ " />
                        </h:outputText>
                    </p:column>
                </p:dataTable>
            </p:panel>
        </h:form>
        <style>.green-text { color: green; } .red-text { color: red; }</style>
    </ui:define>
</ui:composition>
EOF
# =================================================================
# VISTAS MÓDULO 3: GESTIÓN DE RUTAS, PARADAS Y FLOTA
# =================================================================
log "Creando vistas de gestión (paradas, rutas, flota)..."
cat > "$WEBAPP_PATH/admin/paradas/lista.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" xmlns="http://www.w3.org/1999/xhtml" xmlns:h="http://xmlns.jcp.org/jsf/html" xmlns:ui="http://xmlns.jcp.org/jsf/facelets" xmlns:p="http://primefaces.org/ui">
    <ui:define name="title">Gestión de Paradas</ui:define>
    <ui:define name="content">
        <h:form id="formParadas">
            <p:panel header="Lista de Paradas">
                <p:dataTable id="tabla" var="item" value="#{gestionParadasBean.paradas}" paginator="true" rows="10" emptyMessage="No hay paradas registradas.">
                    <p:column headerText="ID" sortBy="#{item.id}"><h:outputText value="#{item.id}" /></p:column>
                    <p:column headerText="Nombre" sortBy="#{item.nombre}"><h:outputText value="#{item.nombre}" /></p:column>
                    <p:column headerText="Latitud"><h:outputText value="#{item.latitud}" /></p:column>
                    <p:column headerText="Longitud"><h:outputText value="#{item.longitud}" /></p:column>
                    <p:column headerText="Acciones" style="width:120px; text-align:center;">
                        <p:commandButton icon="pi pi-pencil" title="Editar" actionListener="#{gestionParadasBean.setParadaSeleccionada(item)}" update=":formDialog" oncomplete="PF('dialogWV').show()" styleClass="rounded-button ui-button-success"/>
                        <p:commandButton icon="pi pi-trash" title="Eliminar" actionListener="#{gestionParadasBean.eliminar(item.id)}" update="tabla" styleClass="rounded-button ui-button-danger">
                            <p:confirm header="Confirmación" message="¿Seguro que desea eliminar la parada '#{item.nombre}'?" icon="pi pi-exclamation-triangle"/>
                        </p:commandButton>
                    </p:column>
                </p:dataTable>
                <p:toolbar><p:toolbarGroup>
                    <!-- MODIFICACIÓN AQUÍ: Añadimos PrimeFaces.focus al oncomplete -->
                    <p:commandButton value="Nueva Parada" icon="pi pi-plus" actionListener="#{gestionParadasBean.nuevo()}" update=":formDialog" oncomplete="PF('dialogWV').show(); PrimeFaces.focus('formDialog:nombre');"/>
                </p:toolbarGroup></p:toolbar>
            </p:panel>
        </h:form>

        <!-- MODIFICACIÓN AQUÍ: Añadimos appendTo="@(body)" al p:dialog -->
        <p:dialog header="Formulario de Parada" widgetVar="dialogWV" modal="true" resizable="false" appendTo="@(body)">
            <h:form id="formDialog">
                <p:panelGrid columns="2" styleClass="ui-noborder">
                    <p:outputLabel for="nombre" value="Nombre:"/>
                    <p:inputText id="nombre" value="#{gestionParadasBean.paradaSeleccionada.nombre}" required="true"/>
                    <p:outputLabel for="lat" value="Latitud:"/>
                    <p:inputNumber id="lat" value="#{gestionParadasBean.paradaSeleccionada.latitud}" decimalPlaces="7"/>
                    <p:outputLabel for="lon" value="Longitud:"/>
                    <p:inputNumber id="lon" value="#{gestionParadasBean.paradaSeleccionada.longitud}" decimalPlaces="7"/>
                </p:panelGrid>
                <p:commandButton value="Guardar" actionListener="#{gestionParadasBean.guardar}" update=":formParadas:tabla :messages" oncomplete="if(!args.validationFailed) PF('dialogWV').hide();"/>
            </h:form>
        </p:dialog>
        
        <p:confirmDialog global="true">
            <p:commandButton value="Sí" type="button" styleClass="ui-confirmdialog-yes"/>
            <p:commandButton value="No" type="button" styleClass="ui-confirmdialog-no ui-button-secondary"/>
        </p:confirmDialog>
    </ui:define>
</ui:composition>
EOF
cat > "$WEBAPP_PATH/admin/rutas/lista.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" xmlns="http://www.w3.org/1999/xhtml" xmlns:h="http://xmlns.jcp.org/jsf/html" xmlns:ui="http://xmlns.jcp.org/jsf/facelets" xmlns:p="http://primefaces.org/ui" xmlns:f="http://xmlns.jcp.org/jsf/core">
    <ui:define name="title">Gestión de Rutas</ui:define>
    <ui:define name="content">
        <h:form id="formRutas">
            <p:panel header="Lista de Rutas">
                <p:dataTable id="tabla" var="item" value="#{gestionRutasBean.rutas}" paginator="true" rows="10" emptyMessage="No hay rutas registradas.">
                    <p:column headerText="ID" sortBy="#{item.id}"><h:outputText value="#{item.id}" /></p:column>
                    <p:column headerText="Nombre" sortBy="#{item.nombre}"><h:outputText value="#{item.nombre}" /></p:column>
                    <p:column headerText="Descripción"><h:outputText value="#{item.descripcion}" /></p:column>
                    <p:column headerText="Acciones" style="width:120px; text-align:center;">
                        <p:commandButton icon="pi pi-pencil" title="Editar" actionListener="#{gestionRutasBean.editar(item)}" update=":formDialog" oncomplete="PF('dialogWV').show()"/>
                        <p:commandButton icon="pi pi-trash" title="Eliminar" actionListener="#{gestionRutasBean.eliminar(item.id)}" update="tabla"><p:confirm header="Confirmación" message="¿Eliminar ruta '#{item.nombre}'?" icon="pi pi-exclamation-triangle"/></p:commandButton>
                    </p:column>
                </p:dataTable>
                <p:toolbar><p:toolbarGroup>
                    <p:commandButton value="Nueva Ruta" icon="pi pi-plus" actionListener="#{gestionRutasBean.nuevo()}" update=":formDialog" oncomplete="PF('dialogWV').show(); PrimeFaces.focus('formDialog:nombre');"/>
                </p:toolbarGroup></p:toolbar>
            </p:panel>
        </h:form>

        <p:dialog header="Formulario de Ruta" widgetVar="dialogWV" modal="true" width="700" resizable="false" appendTo="@(body)">
            <h:form id="formDialog">
                <p:panelGrid columns="2" styleClass="ui-noborder" style="margin-bottom:10px;">
                    <p:outputLabel for="nombre" value="Nombre:"/><p:inputText id="nombre" value="#{gestionRutasBean.rutaSeleccionada.nombre}" required="true" style="width:100%"/>
                    <p:outputLabel for="desc" value="Descripción:"/><p:inputTextarea id="desc" value="#{gestionRutasBean.rutaSeleccionada.descripcion}" rows="3" style="width:100%"/>
                </p:panelGrid>
                <p:pickList value="#{gestionRutasBean.paradasPickList}" var="parada" itemLabel="#{parada.nombre}" itemValue="#{parada}" converter="entityConverter" showSourceFilter="true" showTargetFilter="true" filterMatchMode="contains">
                    <f:facet name="sourceCaption">Paradas Disponibles</f:facet>
                    <f:facet name="targetCaption">Paradas en la Ruta</f:facet>
                </p:pickList>
                <p:commandButton value="Guardar" actionListener="#{gestionRutasBean.guardar}" update=":formRutas:tabla :messages" oncomplete="if(!args.validationFailed) PF('dialogWV').hide();" style="margin-top:10px;"/>
            </h:form>
        </p:dialog>

        <p:confirmDialog global="true"><p:commandButton value="Sí" type="button" styleClass="ui-confirmdialog-yes"/><p:commandButton value="No" type="button" styleClass="ui-confirmdialog-no ui-button-secondary"/></p:confirmDialog>
    </ui:define>
</ui:composition>
EOF
cat > "$WEBAPP_PATH/admin/flota/lista.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" xmlns="http://www.w3.org/1999/xhtml" xmlns:h="http://xmlns.jcp.org/jsf/html" xmlns:ui="http://xmlns.jcp.org/jsf/facelets" xmlns:f="http://xmlns.jcp.org/jsf/core" xmlns:p="http://primefaces.org/ui">
    <ui:define name="title">Gestión de Flota</ui:define>
    <ui:define name="content">
        <h:form id="formFlota">
            <p:panel header="Lista de Autobuses">
                <p:dataTable id="tabla" var="item" value="#{gestionAutobusesBean.autobuses}" paginator="true" rows="10" emptyMessage="No hay autobuses registrados.">
                    <p:column headerText="ID" sortBy="#{item.id}"><h:outputText value="#{item.id}" /></p:column>
                    <p:column headerText="Matrícula" sortBy="#{item.matricula}"><h:outputText value="#{item.matricula}" /></p:column>
                    <p:column headerText="Modelo" sortBy="#{item.modelo}"><h:outputText value="#{item.modelo}" /></p:column>
                    <p:column headerText="Capacidad" sortBy="#{item.capacidad}"><h:outputText value="#{item.capacidad}" /></p:column>
                    <p:column headerText="Ruta Asignada" sortBy="#{item.rutaAsignada.nombre}"><h:outputText value="#{empty item.rutaAsignada ? 'Sin asignar' : item.rutaAsignada.nombre}" /></p:column>
                    <p:column headerText="Acciones" style="width:120px; text-align:center;">
                        <p:commandButton icon="pi pi-pencil" title="Editar" actionListener="#{gestionAutobusesBean.editar(item)}" update=":formDialog" oncomplete="PF('dialogWV').show()"/>
                        <p:commandButton icon="pi pi-trash" title="Eliminar" actionListener="#{gestionAutobusesBean.eliminar(item.id)}" update="tabla"><p:confirm header="Confirmación" message="¿Eliminar autobús '#{item.matricula}'?" icon="pi pi-exclamation-triangle"/></p:commandButton>
                    </p:column>
                </p:dataTable>
                <p:toolbar><p:toolbarGroup>
                    <p:commandButton value="Nuevo Autobús" icon="pi pi-plus" actionListener="#{gestionAutobusesBean.nuevo()}" update=":formDialog" oncomplete="PF('dialogWV').show(); PrimeFaces.focus('formDialog:mat');"/>
                </p:toolbarGroup></p:toolbar>
            </p:panel>
        </h:form>

        <p:dialog header="Formulario de Autobús" widgetVar="dialogWV" modal="true" resizable="false" appendTo="@(body)">
            <h:form id="formDialog">
                <p:panelGrid columns="2" styleClass="ui-noborder">
                    <p:outputLabel for="mat" value="Matrícula:"/><p:inputText id="mat" value="#{gestionAutobusesBean.autobusSeleccionado.matricula}" required="true"/>
                    <p:outputLabel for="mod" value="Modelo:"/><p:inputText id="mod" value="#{gestionAutobusesBean.autobusSeleccionado.modelo}"/>
                    <p:outputLabel for="cap" value="Capacidad:"/><p:inputNumber id="cap" value="#{gestionAutobusesBean.autobusSeleccionado.capacidad}" required="true"/>
                    <p:outputLabel for="ruta" value="Ruta Asignada:"/><p:selectOneMenu id="ruta" value="#{gestionAutobusesBean.rutaIdSeleccionada}"><f:selectItem itemLabel="-- Sin Asignar --" itemValue="#{null}" noSelectionOption="true"/><f:selectItems value="#{gestionAutobusesBean.rutasDisponibles}" var="ruta" itemLabel="#{ruta.nombre}" itemValue="#{ruta.id}"/></p:selectOneMenu>
                </p:panelGrid>
                <p:commandButton value="Guardar" actionListener="#{gestionAutobusesBean.guardar}" update=":formFlota:tabla :messages" oncomplete="if(!args.validationFailed) PF('dialogWV').hide();"/>
            </h:form>
        </p:dialog>
        
        <p:confirmDialog global="true"><p:commandButton value="Sí" type="button" styleClass="ui-confirmdialog-yes"/><p:commandButton value="No" type="button" styleClass="ui-confirmdialog-no ui-button-secondary"/></p:confirmDialog>
    </ui:define>
</ui:composition>
EOF
# =================================================================
# VISTA MÓDULO 4: PLANIFICACIÓN DE VIAJES
# =================================================================
# ... (dentro del script 9-crear-vistas-finales.sh)
log "Creando vista de planificación de viajes con mapa..."
cat > "$WEBAPP_PATH/pasajero/planificarViaje.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" 
    xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:h="http://xmlns.jcp.org/jsf/html" 
    xmlns:ui="http://xmlns.jcp.org/jsf/facelets" 
    xmlns:f="http://xmlns.jcp.org/jsf/core" 
    xmlns:p="http://primefaces.org/ui">
    
    <ui:define name="title">Planificar Viaje</ui:define>
    
    <ui:define name="content">
        <h:outputStylesheet name="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
        <h:outputScript name="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js" />
        
        <h:form id="formPlanificador">
            <p:panel header="Encuentra tu Ruta">
                <p:panelGrid columns="3" styleClass="ui-noborder">
                    <p:outputLabel for="origen" value="Parada de Origen:"/>
                    <p:selectOneMenu id="origen" value="#{planificadorBean.idParadaOrigen}" filter="true" filterMatchMode="contains" required="true">
                        <f:selectItem itemLabel="Selecciona una parada" itemValue="" noSelectionOption="true"/>
                        <f:selectItems value="#{planificadorBean.paradasDisponibles}" var="parada" itemLabel="#{parada.nombre}" itemValue="#{parada.id}"/>
                    </p:selectOneMenu>
                    <p:message for="origen"/>
                    
                    <p:outputLabel for="destino" value="Parada de Destino:"/>
                    <p:selectOneMenu id="destino" value="#{planificadorBean.idParadaDestino}" filter="true" filterMatchMode="contains" required="true">
                        <f:selectItem itemLabel="Selecciona una parada" itemValue="" noSelectionOption="true"/>
                        <f:selectItems value="#{planificadorBean.paradasDisponibles}" var="parada" itemLabel="#{parada.nombre}" itemValue="#{parada.id}"/>
                    </p:selectOneMenu>
                    <p:message for="destino"/>
                </p:panelGrid>
                <p:commandButton value="Buscar Rutas" actionListener="#{planificadorBean.buscarRutas}" update="panelResultados :messages"/>
            </p:panel>

            <p:panel id="panelResultados" header="Rutas Disponibles" style="margin-top:20px;">
                <p:dataTable value="#{planificadorBean.rutasEncontradas}" var="ruta" emptyMessage="No se encontraron rutas directas.">
                    <p:column headerText="Nombre Ruta"><h:outputText value="#{ruta.nombre}"/></p:column>
                    <p:column headerText="Descripción"><h:outputText value="#{ruta.descripcion}"/></p:column>
                    <p:column headerText="Ver en Mapa" style="width:120px; text-align:center;">
                        <p:commandButton icon="pi pi-map-marker" title="Visualizar Ruta" 
                                         actionListener="#{planificadorBean.visualizarRutaEnMapa(ruta)}" 
                                         oncomplete="PF('mapaDialogWV').show()"
                                         update=":formPlanificador:hiddenJson" />
                    </p:column>
                </p:dataTable>
            </p:panel>
            
            <h:inputHidden id="hiddenJson" value="#{planificadorBean.paradasJson}" />
        </h:form>
        
        <p:dialog widgetVar="mapaDialogWV" header="Visualización de Ruta" width="80%" 
                  modal="true" appendTo="@(body)" onShow="initMap()">
            <div id="map" style="height: 400px; width: 100%;"></div>
        </p:dialog>
        
        <h:outputScript>
            var map; // Variable global para la instancia del mapa

            function initMap() {
                // Si el mapa ya existe, simplemente lo limpiamos y redimensionamos
                if (map) {
                    map.eachLayer(function (layer) {
                        // Borra solo marcadores y polilíneas, deja el mapa base (tile layer)
                        if (!!layer.toGeoJSON) { 
                           map.removeLayer(layer);
                        }
                    });
                } else { // Si no existe, lo creamos por primera vez
                    map = L.map('map').setView([13.6929, -89.2182], 13);
                    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        attribution: '&#169; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                    }).addTo(map);
                }
                
                // Forzar el redimensionamiento es la clave para que sea visible
                setTimeout(function() {
                    map.invalidateSize();
                    drawRouteOnMap(); // Llamamos a la función de dibujo DESPUÉS de redimensionar
                }, 100);
            }

            function drawRouteOnMap() {
                var paradasDataField = document.getElementById('formPlanificador:hiddenJson');
                if (!paradasDataField || !paradasDataField.value || paradasDataField.value === '[]') {
                    console.log('No hay datos de paradas para dibujar.');
                    return;
                }
                
                console.log('Dibujando ruta con datos:', paradasDataField.value);

                try {
                    var paradas = JSON.parse(paradasDataField.value);
                    if (paradas.length > 0) {
                        var latlngs = paradas.map(p => [p.lat, p.lng]);
                        
                        paradas.forEach(p => L.marker([p.lat, p.lng]).addTo(map).bindPopup(p.nombre));
                        var polyline = L.polyline(latlngs, {color: 'blue'}).addTo(map);
                        
                        map.fitBounds(polyline.getBounds().pad(0.1));
                    }
                } catch(e) { console.error("Error al procesar datos del mapa: ", e); }
            }
        </h:outputScript>
    </ui:define>
</ui:composition> 
EOF

# =================================================================
# VISTA MÓDULO 5: HISTORIAL
# =================================================================
log "Creando vista de historial de viajes..."
cat > "$WEBAPP_PATH/pasajero/historial.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" xmlns="http://www.w3.org/1999/xhtml" xmlns:h="http://xmlns.jcp.org/jsf/html" xmlns:ui="http://xmlns.jcp.org/jsf/facelets" xmlns:f="http://xmlns.jcp.org/jsf/core" xmlns:p="http://primefaces.org/ui">
    <ui:define name="title">Historial de Viajes</ui:define>
    <ui:define name="content">
        <h:form>
            <p:panel header="Mis Viajes Realizados">
                <p:dataTable value="#{historialBean.historialViajes}" var="viaje" emptyMessage="Aún no has realizado ningún viaje." paginator="true" rows="15" sortBy="#{viaje.fechaHora}" sortOrder="descending">
                    <p:column headerText="Fecha y Hora" sortBy="#{viaje.fechaHora}">
                        <h:outputText value="#{viaje.fechaHora}"><f:convertDateTime pattern="dd/MM/yyyy HH:mm:ss" timeZone="America/El_Salvador" /></h:outputText>
                    </p:column>
                    <p:column headerText="Ruta" sortBy="#{viaje.ruta.nombre}">
                        <h:outputText value="#{viaje.ruta.nombre != null ? viaje.ruta.nombre : 'No especificada'}" />
                    </p:column>
                    <p:column headerText="Autobús (Matrícula)" sortBy="#{viaje.autobus.matricula}">
                        <h:outputText value="#{viaje.autobus.matricula}" />
                    </p:column>
                    <p:column headerText="Costo" style="text-align:right" sortBy="#{viaje.costoPasaje}">
                        <h:outputText value="#{viaje.costoPasaje}"><f:convertNumber type="currency" currencySymbol="$"/></h:outputText>
                    </p:column>
                </p:dataTable>
            </p:panel>
        </h:form>
    </ui:define>
</ui:composition>
EOF

# =================================================================
# VISTA MÓDULO 6: REPORTES
# =================================================================
log "Creando vista de dashboard de reportes para el administrador..."
cat > "$WEBAPP_PATH/admin/dashboard.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" 
    xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:h="http://xmlns.jcp.org/jsf/html" 
    xmlns:ui="http://xmlns.jcp.org/jsf/facelets" 
    xmlns:p="http://primefaces.org/ui"
    xmlns:f="http://xmlns.jcp.org/jsf/core">
    
    <ui:define name="title">Dashboard Administrador</ui:define>
    
    <ui:define name="content">
        <h:outputScript library="primefaces" name="chartjs/chartjs.js" target="head" />
        
        <h:form id="formFiltros">
            <p:panel header="Filtros de Reporte">
                <p:panelGrid columns="5" styleClass="ui-noborder">
                    <p:outputLabel for="fechaInicio" value="Desde:"/>
                    <p:calendar id="fechaInicio" value="#{dashboardBean.fechaInicio}" pattern="dd/MM/yyyy" mask="true"/>
                    
                    <p:outputLabel for="fechaFin" value="Hasta:"/>
                    <p:calendar id="fechaFin" value="#{dashboardBean.fechaFin}" pattern="dd/MM/yyyy" mask="true"/>
                    
                    <p:commandButton value="Aplicar Filtros" actionListener="#{dashboardBean.filtrarReportes}" 
                                     update=":formDashboard" icon="pi pi-filter"/>
                </p:panelGrid>
            </p:panel>
        </h:form>
        
        <h:panelGroup id="formDashboard">
            <div class="ui-g" style="margin-top: 20px;">
                <div class="ui-g-12 ui-md-6 ui-lg-3">
                    <p:panel style="text-align:center;">
                        <i class="pi pi-users" style="font-size: 3rem; color: #2196F3;"></i>
                        <h3>#{dashboardBean.totalPasajeros}</h3>
                        <p>Pasajeros Registrados (Total)</p>
                    </p:panel>
                </div>
                <div class="ui-g-12 ui-md-6 ui-lg-3">
                    <p:panel style="text-align:center;">
                        <i class="pi pi-car" style="font-size: 3rem; color: #4CAF50;"></i>
                        <h3>#{dashboardBean.totalViajes}</h3>
                        <p>Viajes en Periodo</p>
                    </p:panel>
                </div>
            </div>
            
            <div class="ui-g" style="margin-top: 20px;">
                <div class="ui-g-12 ui-lg-6">
                    <p:panel header="Ingresos por Ruta">
                        <p:barChart model="#{dashboardBean.barModel}" style="width: 100%; height: 300px;"/>
                        <h:form>
                            <p:commandButton value="Exportar Excel" icon="pi pi-file-excel" ajax="false" styleClass="ui-button-success" style="margin-right: 5px;">
                                <p:dataExporter type="xls" target="tablaIngresos" fileName="ingresos_por_ruta"/>
                            </p:commandButton>
                            <p:commandButton value="Exportar PDF" icon="pi pi-file-pdf" ajax="false" styleClass="ui-button-danger">
                                <p:dataExporter type="pdf" target="tablaIngresos" fileName="ingresos_por_ruta"/>
                            </p:commandButton>
                            <p:dataTable id="tablaIngresos" var="item" value="#{dashboardBean.ingresosPorRuta}" style="margin-top: 10px;">
                                <p:column headerText="Ruta"><h:outputText value="#{item.nombreRuta}"/></p:column>
                                <p:column headerText="Ingresos"><h:outputText value="#{item.totalIngresos}"><f:convertNumber type="currency" currencySymbol="$"/></h:outputText></p:column>
                            </p:dataTable>
                        </h:form>
                    </p:panel>
                </div>
                <div class="ui-g-12 ui-lg-6">
                     <p:panel header="Horas Pico de Viajes">
                        <p:lineChart model="#{dashboardBean.lineModel}" style="width: 100%; height: 300px;"/>
                        <h:form>
                            <p:commandButton value="Exportar Excel" icon="pi pi-file-excel" ajax="false" styleClass="ui-button-success" style="margin-right: 5px;">
                                <p:dataExporter type="xls" target="tablaHoras" fileName="viajes_por_hora"/>
                            </p:commandButton>
                            <p:commandButton value="Exportar PDF" icon="pi pi-file-pdf" ajax="false" styleClass="ui-button-danger">
                                <p:dataExporter type="pdf" target="tablaHoras" fileName="viajes_por_hora"/>
                            </p:commandButton>
                             <p:dataTable id="tablaHoras" var="item" value="#{dashboardBean.viajesPorHora}" style="margin-top: 10px;">
                                <p:column headerText="Hora"><h:outputText value="#{item.hora}:00"/></p:column>
                                <p:column headerText="Número de Viajes"><h:outputText value="#{item.numeroDeViajes}"/></p:column>
                            </p:dataTable>
                        </h:form>
                    </p:panel>
                </div>
            </div>
        </h:panelGroup>
    </ui:define>
</ui:composition>
EOF

# =================================================================
# ACTUALIZACIÓN FINAL DEL TEMPLATE
# =================================================================
log "Actualizando template.xhtml con el menú de navegación completo..."
cat > "$WEBAPP_PATH/template.xhtml" << 'EOF'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:p="http://primefaces.org/ui"
      xmlns:f="http://xmlns.jcp.org/jsf/core">

<h:head>
    <f:facet name="first">
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0"/>
    </f:facet>
    <title><ui:insert name="title">Sistema de Transporte</ui:insert></title>
    <link rel="icon" href="data:;base64,iVBORw0KGgo="/>
    <h:outputStylesheet library="css" name="style.css" />
    <style type="text/css">
        html, body { height: 100%; margin: 0; padding: 0; font-family: Arial, sans-serif; font-size: 14px; }
        .main-container { display: flex; flex-direction: column; height: 100vh; }
        .header { flex-shrink: 0; height: 60px; background-color: #f5f5f5; border-bottom: 1px solid #ddd; display: flex; align-items: center; padding: 0 20px; box-sizing: border-box; }
        .header h2 { margin: 0; flex-grow: 1; }
        .body-container { display: flex; flex-grow: 1; overflow: hidden; }
        .sidebar { flex-shrink: 0; width: 250px; background-color: #fafafa; border-right: 1px solid #ddd; padding: 15px; box-sizing: border-box; overflow-y: auto; }
        .content { flex-grow: 1; padding: 20px; overflow-y: auto; }
    </style>
</h:head>

<h:body>
    <div class="main-container">
        <div class="header">
            <h2>Sistema de Transporte Urbano</h2>
            <h:form rendered="#{sessionBean.isLoggedIn()}">
                 <p:outputLabel value="Bienvenido, #{sessionBean.usuarioLogueado.nombreCompleto}" style="margin-right:20px; vertical-align: middle;"/>
                 <p:commandButton value="Cerrar Sesión" action="#{loginBean.cerrarSesion}" icon="pi pi-sign-out" styleClass="ui-button-warning"/>
            </h:form>
        </div>
        <div class="body-container">
            <div class="sidebar">
                <h:form rendered="#{sessionBean.isLoggedIn()}">
                    <h3>Menú</h3>
                     <p:menu>
                        <p:menuitem value="Dashboard" outcome="/pasajero/dashboard.xhtml" icon="pi pi-home" rendered="#{sessionBean.isPasajero()}"/>
                        <p:menuitem value="Mi Billetera" outcome="/pasajero/billetera.xhtml" icon="pi pi-wallet" rendered="#{sessionBean.isPasajero()}"/>
                        <p:menuitem value="Planificar Viaje" outcome="/pasajero/planificarViaje.xhtml" icon="pi pi-map-marker" rendered="#{sessionBean.isPasajero()}"/>
                        <p:menuitem value="Mi Historial" outcome="/pasajero/historial.xhtml" icon="pi pi-history" rendered="#{sessionBean.isPasajero()}"/>
                        <p:menuitem value="Dashboard Admin" outcome="/admin/dashboard.xhtml" icon="pi pi-chart-bar" rendered="#{sessionBean.isAdmin()}"/>
                        <p:menuitem value="Gestión Usuarios" outcome="/admin/usuarios/lista.xhtml" icon="pi pi-users" rendered="#{sessionBean.isAdmin()}"/>
                        <p:menuitem value="Gestión Rutas" outcome="/admin/rutas/lista.xhtml" icon="pi pi-sitemap" rendered="#{sessionBean.isAdmin()}"/>
                        <p:menuitem value="Gestión Paradas" outcome="/admin/paradas/lista.xhtml" icon="pi pi-map" rendered="#{sessionBean.isAdmin()}"/>
                        <p:menuitem value="Gestión Flota" outcome="/admin/flota/lista.xhtml" icon="pi pi-truck" rendered="#{sessionBean.isAdmin()}"/>
                    </p:menu>
                </h:form>
            </div>
            <div class="content">
                <p:growl id="messages" showDetail="true" life="4000" />
                <ui:insert name="content"/>
            </div>
        </div>
    </div>
</h:body>
</html>
EOF



log "Todas las vistas han sido creadas/actualizadas al 100%."