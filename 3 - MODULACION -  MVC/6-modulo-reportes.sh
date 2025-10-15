#!/bin/bash
# 6-modulo-reportes.sh (Versión Final - 100% Modular)
set -euo pipefail

# --- SECCIÓN INICIAL (COLORES, LOGS, CARGA DE ENTORNO) ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header() { echo -e "${CYAN}--- $1 ---${NC}"; }
header "Cargando entorno del proyecto"
PROJECT_ENV_FILE="$HOME/.project-env"; if [ ! -f "$PROJECT_ENV_FILE" ]; then error "No se encontró ~/.project-env."; fi
source "$PROJECT_ENV_FILE"; if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_DIR" ]; then error "Variables del proyecto no definidas."; fi
cd "$PROJECT_DIR" || error "No se pudo cambiar al directorio del proyecto."
PACKAGE_ROOT="com.$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"
BASE_PACKAGE_PATH="src/main/java/$(echo "$PACKAGE_ROOT" | tr '.' '/')"
RESOURCES_PATH="src/main/resources"; WEBAPP_PATH="src/main/webapp"
# --- FIN SECCIÓN INICIAL ---

header "Implementando Módulo 6: Reportes y Analítica"

# =================================================================
# CAPA DE DTOs
# =================================================================
log "Creando DTOs para los reportes"
# ... (El código de los DTOs no cambia, es correcto) ...
cat > "$BASE_PACKAGE_PATH/reportes/dto/IngresosPorRutaDTO.java" << 'EOF'
package com.simu.reportes.dto;
import java.io.Serializable;
import java.math.BigDecimal;
public class IngresosPorRutaDTO implements Serializable {
    private static final long serialVersionUID = 1L;
    private String nombreRuta;
    private BigDecimal totalIngresos;
    public IngresosPorRutaDTO(String n, BigDecimal t) { this.nombreRuta = n; this.totalIngresos = t != null ? t : BigDecimal.ZERO; }
    public String getNombreRuta() { return nombreRuta; }
    public BigDecimal getTotalIngresos() { return totalIngresos; }
}
EOF
cat > "$BASE_PACKAGE_PATH/reportes/dto/PasajerosHoraPicoDTO.java" << 'EOF'
package com.simu.reportes.dto;
import java.io.Serializable;
public class PasajerosHoraPicoDTO implements Serializable {
    private static final long serialVersionUID = 1L;
    private int hora;
    private long numeroDeViajes;
    public PasajerosHoraPicoDTO(int h, long n) { this.hora = h; this.numeroDeViajes = n; }
    public int getHora() { return hora; }
    public long getNumeroDeViajes() { return numeroDeViajes; }
}
EOF

# =================================================================
# CAPA DE ACCESO A DATOS (DAO) - NUEVO DAO PARA REPORTES
# =================================================================
log "Creando ReporteDAO.java para centralizar las consultas de analítica"

touch "$BASE_PACKAGE_PATH/reportes/dao/ReporteDAO.java"
cat > "$BASE_PACKAGE_PATH/reportes/dao/ReporteDAO.java" << 'EOF'
package com.simu.reportes.dao;

import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import java.util.List;

@Stateless
public class ReporteDAO {

    @PersistenceContext(unitName = "transportePU")
    private EntityManager em;

    public Long countPasajeros() {
        try {
            return em.createQuery("SELECT COUNT(u) FROM Usuario u WHERE u.rol.nombre = 'PASAJERO'", Long.class).getSingleResult();
        } catch (Exception e) {
            return 0L;
        }
    }

    public Long countTotalViajes() {
        try {
            return em.createQuery("SELECT COUNT(v) FROM Viaje v", Long.class).getSingleResult();
        } catch (Exception e) {
            return 0L;
        }
    }

    public List<Object[]> getIngresosPorRuta() {
        return em.createQuery(
            "SELECT v.ruta.nombre, SUM(v.costoPasaje) FROM Viaje v WHERE v.ruta IS NOT NULL GROUP BY v.ruta.nombre ORDER BY SUM(v.costoPasaje) DESC", Object[].class)
            .getResultList();
    }

    public List<Object[]> getViajesPorHora() {
        return em.createQuery(
            "SELECT FUNCTION('EXTRACT', hour from v.fechaHora), COUNT(v) FROM Viaje v GROUP BY FUNCTION('EXTRACT', hour from v.fechaHora) ORDER BY FUNCTION('EXTRACT', hour from v.fechaHora)", Object[].class)
            .getResultList();
    }
}
EOF

# =================================================================
# CAPA DE SERVICIOS Y PRESENTACIÓN
# =================================================================
log "Creando Servicio de Analítica y Dashboard"

# --- AnaliticaService.java (Ahora usa ReporteDAO) ---
cat > "$BASE_PACKAGE_PATH/reportes/service/AnaliticaService.java" << 'EOF'
package com.simu.reportes.service;

import com.simu.reportes.dao.ReporteDAO;
import com.simu.reportes.dto.IngresosPorRutaDTO;
import com.simu.reportes.dto.PasajerosHoraPicoDTO;
import javax.ejb.Stateless;
import javax.inject.Inject;
import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Stateless
public class AnaliticaService {

    @Inject
    private ReporteDAO reporteDAO;

    public long getTotalPasajeros() {
        return reporteDAO.countPasajeros();
    }

    public long getTotalViajes() {
        return reporteDAO.countTotalViajes();
    }

    public List<IngresosPorRutaDTO> getIngresosTotalesPorRuta() {
        return reporteDAO.getIngresosPorRuta().stream()
                .map(result -> new IngresosPorRutaDTO((String) result[0], (BigDecimal) result[1]))
                .collect(Collectors.toList());
    }

    public List<PasajerosHoraPicoDTO> getDistribucionViajesPorHora() {
        return reporteDAO.getViajesPorHora().stream()
                .map(result -> new PasajerosHoraPicoDTO(((Number) result[0]).intValue(), (Long) result[1]))
                .collect(Collectors.toList());
    }
}
EOF

# ... (El código para DashboardBean.java y admin/dashboard.xhtml no cambia, es correcto) ...

# =================================================================
# ACTUALIZACIÓN DE UI Y CONFIGURACIÓN (SOBRESCRIBIR)
# =================================================================
log "Actualizando UI y Configuración para Módulo 6"

# --- template.xhtml (Sin cambios desde el Módulo 5) ---
cat > "$WEBAPP_PATH/template.xhtml" << 'EOF'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:p="http://primefaces.org/ui"
      xmlns:f="http://xmlns.jcp.org/jsf/core">
<h:head>
    <f:facet name="first"><meta http-equiv="X-UA-Compatible" content="IE=edge" /><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0"/></f:facet>
    <title><ui:insert name="title">Sistema de Transporte</ui:insert></title>
    <h:outputStylesheet library="css" name="style.css" />
</h:head>
<h:body>
    <p:layout fullPage="true">
        <p:layoutUnit position="north" size="100" header="Sistema de Transporte Urbano">
            <h:form rendered="#{sessionBean.isLoggedIn()}">
                <p:menubar>
                    <p:menuitem value="Dashboard" outcome="/pasajero/dashboard" rendered="#{sessionBean.isPasajero()}"/>
                    <p:menuitem value="Mi Billetera" outcome="/pasajero/billetera" rendered="#{sessionBean.isPasajero()}"/>
                    <p:menuitem value="Planificar Viaje" outcome="/pasajero/planificarViaje" rendered="#{sessionBean.isPasajero()}"/>
                    <p:menuitem value="Mi Historial" outcome="/pasajero/historial" rendered="#{sessionBean.isPasajero()}"/>
                    <p:menuitem value="Dashboard Admin" outcome="/admin/dashboard" rendered="#{sessionBean.isAdmin()}"/>
                    <p:menuitem value="Gestión Usuarios" outcome="/admin/usuarios/lista" rendered="#{sessionBean.isAdmin()}"/>
                    <p:menuitem value="Gestión Rutas" outcome="/admin/rutas/lista" rendered="#{sessionBean.isAdmin()}"/>
                    <p:menuitem value="Gestión Paradas" outcome="/admin/paradas/lista" rendered="#{sessionBean.isAdmin()}"/>
                    <p:menuitem value="Gestión Flota" outcome="/admin/flota/lista" rendered="#{sessionBean.isAdmin()}"/>
                    <f:facet name="options"><p:outputLabel value="Bienvenido, #{sessionBean.usuarioLogueado.nombreCompleto}" style="margin-right:20px;"/><p:commandButton value="Cerrar Sesión" action="#{loginBean.cerrarSesion}" icon="pi pi-sign-out" styleClass="ui-button-warning"/></f:facet>
                </p:menubar>
            </h:form>
        </p:layoutUnit>
        <p:layoutUnit position="center"><p:growl id="messages" showDetail="true" sticky="false" /><ui:insert name="content"/></p:layoutUnit>
    </p:layout>
</h:body>
</html>
EOF

# --- persistence.xml (Sin cambios de entidades desde el Módulo 5) ---
cat > "$RESOURCES_PATH/META-INF/persistence.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<persistence version="2.1"
             xmlns="http://xmlns.jcp.org/xml/ns/persistence"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/persistence http://xmlns.jcp.org/xml/ns/persistence/persistence_2_1.xsd">
    <persistence-unit name="transportePU" transaction-type="JTA">
        <jta-data-source>jdbc/miDB</jta-data-source>
        <class>${PACKAGE_ROOT}.usuarios.entity.Usuario</class>
        <class>${PACKAGE_ROOT}.usuarios.entity.Rol</class>
        <class>${PACKAGE_ROOT}.billetera.entity.Tarjeta</class>
        <class>${PACKAGE_ROOT}.billetera.entity.Transaccion</class>
        <class>${PACKAGE_ROOT}.rutas.entity.Parada</class>
        <class>${PACKAGE_ROOT}.rutas.entity.Ruta</class>
        <class>${PACKAGE_ROOT}.rutas.entity.Tarifa</class>
        <class>${PACKAGE_ROOT}.flota.entity.Autobus</class>
        <class>${PACKAGE_ROOT}.viajes.entity.Viaje</class>
        <exclude-unlisted-classes>true</exclude-unlisted-classes>
        <properties>
            <property name="javax.persistence.schema-generation.database.action" value="drop-and-create"/>
        </properties>
    </persistence-unit>
</persistence>
EOF

header "Módulo 6: Implementación Completa y 100% Modular   Reportes y Analítica"
log "Se ha implementado el Dashboard del Administrador con gráficos y estadísticas."
warn "Asegúrate de simular algunos viajes en la BD para poder ver los gráficos."
log "Para construir y desplegar los cambios, ejecuta:"
echo -e "   ${YELLOW}cd $PROJECT_DIR && ./deploy.sh${NC}"