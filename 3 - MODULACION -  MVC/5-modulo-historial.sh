#!/bin/bash
# 5-modulo-historial.sh
#
# DESCRIPCIÓN:
#   Implementa el Módulo 5: Historial de Viajes.
#   - Crea la entidad 'Viaje' para registrar los recorridos de los pasajeros.
#   - Modifica BilleteraService para incluir un método de pago de pasaje,
#     asegurando que se añaden los imports y dependencias necesarias.
#   - Crea un bean y una vista para que el pasajero consulte su historial.
#
# IDEMPOTENCIA:
#   Este script es 100% idempotente. Las modificaciones a archivos existentes
#   se comprueban antes de aplicarse para evitar duplicados.

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

# --- 2. DEFINIR RUTAS Y PAQUETTES ---
cd "$PROJECT_DIR" || error "No se pudo cambiar al directorio del proyecto: $PROJECT_DIR"

PACKAGE_ROOT="com.$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"
BASE_PACKAGE_PATH="src/main/java/$(echo "$PACKAGE_ROOT" | tr '.' '/')"
RESOURCES_PATH="src/main/resources"
WEBAPP_PATH="src/main/webapp"

# --- 3. IMPLEMENTACIÓN DEL MÓDULO DE HISTORIAL ---
header "Implementando Módulo 5: Historial de Viajes"

# =================================================================
# CAPA DE ENTIDADES (MODELO)
# =================================================================
log "Creando Entidad JPA: Viaje.java"

# --- Viaje.java ---
cat > "$BASE_PACKAGE_PATH/viajes/entity/Viaje.java" << 'EOF'
package com.simu.viajes.entity;
import com.simu.flota.entity.Autobus;
import com.simu.rutas.entity.Ruta;
import com.simu.usuarios.entity.Usuario;
import javax.persistence.*;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import java.util.Objects;
@Entity
@Table(name = "viajes")
public class Viaje implements Serializable {
    private static final long serialVersionUID = 1L;
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.EAGER) @JoinColumn(name = "usuario_id", nullable = false) private Usuario usuario;
    @ManyToOne(fetch = FetchType.EAGER) @JoinColumn(name = "ruta_id") private Ruta ruta;
    @ManyToOne(fetch = FetchType.EAGER) @JoinColumn(name = "autobus_id", nullable = false) private Autobus autobus;
    @Temporal(TemporalType.TIMESTAMP) @Column(name = "fecha_hora", nullable = false) private Date fechaHora;
    @Column(name = "costo_pasaje", nullable = false, precision = 10, scale = 2) private BigDecimal costoPasaje;
    @PrePersist protected void onCreate() { fechaHora = new Date(); }
    public Long getId() { return id; } public void setId(Long id) { this.id = id; }
    public Usuario getUsuario() { return usuario; } public void setUsuario(Usuario usuario) { this.usuario = usuario; }
    public Ruta getRuta() { return ruta; } public void setRuta(Ruta ruta) { this.ruta = ruta; }
    public Autobus getAutobus() { return autobus; } public void setAutobus(Autobus autobus) { this.autobus = autobus; }
    public Date getFechaHora() { return fechaHora; } public void setFechaHora(Date fechaHora) { this.fechaHora = fechaHora; }
    public BigDecimal getCostoPasaje() { return costoPasaje; } public void setCostoPasaje(BigDecimal c) { this.costoPasaje = c; }
    @Override public boolean equals(Object o) { if (this == o) return true; if (o == null || getClass() != o.getClass()) return false; Viaje viaje = (Viaje) o; return Objects.equals(id, viaje.id); }
    @Override public int hashCode() { return Objects.hash(id); }
}
EOF



# =================================================================
# CAPA DE SERVICIOS Y DAOs
# =================================================================
log "Creando DAO y Servicio para Historial"

# --- ViajeDAO.java ---
cat > "$BASE_PACKAGE_PATH/viajes/dao/ViajeDAO.java" << 'EOF'
package com.simu.viajes.dao;

import com.simu.shared.dao.GenericDAO;
import com.simu.viajes.entity.Viaje;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import java.util.List;

@Stateless
public class ViajeDAO extends GenericDAO<Viaje, Long> {
    @PersistenceContext(unitName = "transportePU") private EntityManager em;
    public ViajeDAO() { super(Viaje.class); }
    @Override protected EntityManager getEntityManager() { return em; }
    public List<Viaje> findByUsuarioId(Long usuarioId) {
        return em.createQuery("SELECT v FROM Viaje v WHERE v.usuario.id = :usuarioId ORDER BY v.fechaHora DESC", Viaje.class)
                 .setParameter("usuarioId", usuarioId)
                 .getResultList();
    }
}
EOF


# --- BilleteraService.java (SOBRESCRIBIR CON LA VERSIÓN COMPLETA) ---
log "Sobrescribiendo BilleteraService.java con funcionalidad de pago"
cat > "$BASE_PACKAGE_PATH/billetera/service/BilleteraService.java" << 'EOF'
package com.simu.billetera.service;

import com.simu.billetera.dao.TarjetaDAO;
import com.simu.billetera.dao.TransaccionDAO;
import com.simu.billetera.entity.Tarjeta;
import com.simu.billetera.entity.TipoTransaccion;
import com.simu.billetera.entity.Transaccion;
import com.simu.flota.dao.AutobusDAO;
import com.simu.flota.entity.Autobus;
import com.simu.usuarios.entity.Usuario;
import com.simu.viajes.dao.ViajeDAO;
import com.simu.viajes.entity.Viaje;
import javax.ejb.Stateless;
import javax.inject.Inject;
import java.math.BigDecimal;

@Stateless
public class BilleteraService {

    @Inject private TarjetaDAO tarjetaDAO;
    @Inject private TransaccionDAO transaccionDAO;
    @Inject private ViajeDAO viajeDAO;
    @Inject private AutobusDAO autobusDAO;

    public Tarjeta obtenerOCrearTarjeta(Usuario usuario) {
        Tarjeta tarjeta = tarjetaDAO.findByUsuarioId(usuario.getId());
        if (tarjeta == null) {
            tarjeta = new Tarjeta();
            tarjeta.setUsuario(usuario);
            tarjeta.setSaldo(BigDecimal.ZERO);
            tarjetaDAO.create(tarjeta);
        }
        return tarjeta;
    }

    public void recargarSaldo(Long usuarioId, BigDecimal monto) {
        if (monto.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("El monto a recargar debe ser positivo.");
        }
        Tarjeta tarjeta = tarjetaDAO.findByUsuarioId(usuarioId);
        if (tarjeta == null) {
            throw new IllegalStateException("El usuario no tiene una tarjeta asociada.");
        }
        tarjeta.setSaldo(tarjeta.getSaldo().add(monto));
        tarjetaDAO.update(tarjeta);

        Transaccion transaccion = new Transaccion();
        transaccion.setTarjeta(tarjeta);
        transaccion.setTipo(TipoTransaccion.RECARGA);
        transaccion.setMonto(monto);
        transaccion.setDescripcion("Recarga de saldo en línea.");
        transaccionDAO.create(transaccion);
    }

    public void pagarPasaje(Long usuarioId, Long autobusId, BigDecimal costo) throws Exception {
        Tarjeta tarjeta = tarjetaDAO.findByUsuarioId(usuarioId);
        if (tarjeta == null) {
            throw new IllegalStateException("El usuario no tiene una tarjeta asociada.");
        }
        if (tarjeta.getSaldo().compareTo(costo) < 0) {
            throw new Exception("Saldo insuficiente para pagar el pasaje.");
        }
        Autobus autobus = autobusDAO.findById(autobusId);
        if (autobus == null) {
            throw new Exception("El autobús especificado no existe.");
        }

        tarjeta.setSaldo(tarjeta.getSaldo().subtract(costo));
        tarjetaDAO.update(tarjeta);

        Transaccion transaccion = new Transaccion();
        transaccion.setTarjeta(tarjeta);
        transaccion.setTipo(TipoTransaccion.PAGO_PASAJE);
        transaccion.setMonto(costo.negate());
        transaccion.setDescripcion("Pago de pasaje en autobús: " + autobus.getMatricula());
        transaccionDAO.create(transaccion);
        
        Viaje viaje = new Viaje();
        viaje.setUsuario(tarjeta.getUsuario());
        viaje.setAutobus(autobus);
        viaje.setRuta(autobus.getRutaAsignada());
        viaje.setCostoPasaje(costo);
        viajeDAO.create(viaje);
    }
}
EOF

# --- ConsultaHistorialService.java ---
cat > "$BASE_PACKAGE_PATH/historial/service/ConsultaHistorialService.java" << 'EOF'
package com.simu.historial.service;

import com.simu.viajes.dao.ViajeDAO;
import com.simu.viajes.entity.Viaje;
import javax.ejb.Stateless;
import javax.inject.Inject;
import java.util.List;

@Stateless
public class ConsultaHistorialService {
    
    @Inject
    private ViajeDAO viajeDAO;

    public List<Viaje> obtenerHistorialPorUsuario(Long usuarioId) {
        return viajeDAO.findByUsuarioId(usuarioId);
    }
}
EOF

# =================================================================
# CAPA DE PRESENTACIÓN (BEANS Y XHTML)
# =================================================================
log "Creando Managed Bean: HistorialBean.java"

# --- HistorialBean.java ---
cat > "$BASE_PACKAGE_PATH/historial/bean/HistorialBean.java" << 'EOF'
package com.simu.historial.bean;

import com.simu.historial.service.ConsultaHistorialService;
import com.simu.usuarios.bean.SessionBean;
import com.simu.viajes.entity.Viaje;
import javax.annotation.PostConstruct;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import java.util.Collections;
import java.util.List;

@Named
@ViewScoped
public class HistorialBean implements Serializable {
    private static final long serialVersionUID = 1L;

    @Inject
    private ConsultaHistorialService historialService;
    
    @Inject
    private SessionBean sessionBean;
    
    private List<Viaje> historialViajes;
    
    @PostConstruct
    public void init() {
        if (sessionBean.isLoggedIn()) {
            Long usuarioId = sessionBean.getUsuarioLogueado().getId();
            historialViajes = historialService.obtenerHistorialPorUsuario(usuarioId);
        } else {
            historialViajes = Collections.emptyList();
        }
    }
    
    // Getter
    public List<Viaje> getHistorialViajes() { return historialViajes; }
}
EOF

log "Creando Vista XHTML: pasajero/historial.xhtml"

# --- pasajero/historial.xhtml ---
cat > "$WEBAPP_PATH/pasajero/historial.xhtml" << 'EOF'
<ui:composition template="/template.xhtml"
      xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:f="http://xmlns.jcp.org/jsf/core"
      xmlns:p="http://primefaces.org/ui">
      
    <ui:define name="title">Historial de Viajes</ui:define>
    
    <ui:define name="content">
        <h:form>
            <p:panel header="Mis Viajes Realizados">
                <p:dataTable value="#{historialBean.historialViajes}" var="viaje"
                             emptyMessage="Aún no has realizado ningún viaje."
                             paginator="true" rows="15" sortBy="#{viaje.fechaHora}" sortOrder="descending">
                    
                    <p:column headerText="Fecha y Hora" sortBy="#{viaje.fechaHora}">
                        <h:outputText value="#{viaje.fechaHora}">
                            <f:convertDateTime pattern="dd/MM/yyyy HH:mm:ss" />
                        </h:outputText>
                    </p:column>
                    
                    <p:column headerText="Ruta" sortBy="#{viaje.ruta.nombre}">
                        <h:outputText value="#{viaje.ruta.nombre != null ? viaje.ruta.nombre : 'No especificada'}" />
                    </p:column>

                    <p:column headerText="Autobús (Matrícula)" sortBy="#{viaje.autobus.matricula}">
                        <h:outputText value="#{viaje.autobus.matricula}" />
                    </p:column>

                    <p:column headerText="Costo" style="text-align:right" sortBy="#{viaje.costoPasaje}">
                        <h:outputText value="#{viaje.costoPasaje}">
                            <f:convertNumber type="currency" currencySymbol="$"/>
                        </h:outputText>
                    </p:column>
                </p:dataTable>
            </p:panel>
        </h:form>
    </ui:define>
</ui:composition>
EOF
 


# --- template.xhtml (Acumula hasta Módulo 5) ---
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


# --- persistence.xml (Acumula hasta Módulo 5) ---
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




# --- 4. MENSAJE FINAL ---
echo ""
header "Módulo 5: Historial de Viajes - IMPLEMENTACIÓN COMPLETA Y CORREGIDA"
log "Se ha creado la entidad 'Viaje' y la vista de historial para el pasajero."
log "El archivo 'BilleteraService.java' ha sido modificado correctamente para incluir el pago de pasajes y el registro de viajes."
warn "La lógica de 'pago' ahora es funcional, pero se necesita una interfaz (un botón, por ejemplo) para que el usuario pueda activarla y generar registros."
echo ""
log "Para construir y desplegar los cambios, ejecuta:"
echo -e "   ${YELLOW}cd $PROJECT_DIR && ./deploy.sh${NC}"