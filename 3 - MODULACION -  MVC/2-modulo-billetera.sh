#!/bin/bash
# 2-modulo-billetera.sh
#
# DESCRIPCIÓN:
#   Implementa el Módulo 2: Billetera Electrónica.
#   Crea las entidades, DAOs, servicios, beans y vistas necesarias para que un
#   pasajero pueda gestionar su saldo y ver sus transacciones.
#
# IDEMPOTENCIA:
#   Este script sobrescribe los archivos del módulo de billetera con la
#   implementación completa, solucionando errores de compilación de placeholders
#   y asegurando un estado consistente.

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
RESOURCES_PATH="src/main/resources"
WEBAPP_PATH="src/main/webapp"

# --- 3. IMPLEMENTACIÓN DEL MÓDULO DE BILLETERA ---
header "Implementando Módulo 2: Billetera Electrónica"

# =================================================================
# CAPA DE ENTIDADES (MODELO)
# =================================================================
log "Creando Entidades JPA: Tarjeta.java, Transaccion.java, TipoTransaccion.java"

# --- Tarjeta.java ---
cat > "$BASE_PACKAGE_PATH/billetera/entity/Tarjeta.java" << 'EOF'
package com.simu.billetera.entity;

import com.simu.usuarios.entity.Usuario;
import javax.persistence.*;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Entity
@Table(name = "tarjetas")
public class Tarjeta implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "usuario_id", nullable = false, unique = true)
    private Usuario usuario;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal saldo;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "fecha_creacion", nullable = false)
    private Date fechaCreacion;
    
    @OneToMany(mappedBy = "tarjeta", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Transaccion> transacciones;

    @PrePersist
    protected void onCreate() {
        fechaCreacion = new Date();
        if (saldo == null) {
            saldo = BigDecimal.ZERO;
        }
    }

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Usuario getUsuario() { return usuario; }
    public void setUsuario(Usuario usuario) { this.usuario = usuario; }
    public BigDecimal getSaldo() { return saldo; }
    public void setSaldo(BigDecimal saldo) { this.saldo = saldo; }
    public Date getFechaCreacion() { return fechaCreacion; }
    public void setFechaCreacion(Date fechaCreacion) { this.fechaCreacion = fechaCreacion; }
    public List<Transaccion> getTransacciones() { return transacciones; }
    public void setTransacciones(List<Transaccion> transacciones) { this.transacciones = transacciones; }
}
EOF

# --- TipoTransaccion.java ---
cat > "$BASE_PACKAGE_PATH/billetera/entity/TipoTransaccion.java" << 'EOF'
package com.simu.billetera.entity;

public enum TipoTransaccion {
    RECARGA,
    PAGO_PASAJE,
    AJUSTE_POSITIVO,
    AJUSTE_NEGATIVO
}
EOF
# --- Transaccion.java ---
cat > "$BASE_PACKAGE_PATH/billetera/entity/Transaccion.java" << 'EOF'
package com.simu.billetera.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Entity
@Table(name = "transacciones")
public class Transaccion implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tarjeta_id", nullable = false)
    private Tarjeta tarjeta;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_transaccion", nullable = false)
    private TipoTransaccion tipo;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal monto;
    
    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "fecha_transaccion", nullable = false)
    private Date fechaTransaccion; // <-- RENOMBRADO AQUÍ
    
    private String descripcion;

    @PrePersist
    protected void onCreate() {
        fechaTransaccion = new Date(); // <-- ACTUALIZADO AQUÍ
    }

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Tarjeta getTarjeta() { return tarjeta; }
    public void setTarjeta(Tarjeta tarjeta) { this.tarjeta = tarjeta; }
    public TipoTransaccion getTipo() { return tipo; }
    public void setTipo(TipoTransaccion tipo) { this.tipo = tipo; }
    public BigDecimal getMonto() { return monto; }
    public void setMonto(BigDecimal monto) { this.monto = monto; }
    public Date getFechaTransaccion() { return fechaTransaccion; } // <-- ACTUALIZADO AQUÍ
    public void setFechaTransaccion(Date fecha) { this.fechaTransaccion = fecha; } // <-- ACTUALIZADO AQUÍ
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
}
EOF
# =================================================================
# CAPA DE ACCESO A DATOS (DAO)
# =================================================================
log "Creando DAOs: TarjetaDAO.java y TransaccionDAO.java"

# --- TarjetaDAO.java ---
cat > "$BASE_PACKAGE_PATH/billetera/dao/TarjetaDAO.java" << 'EOF'
package com.simu.billetera.dao;

import com.simu.billetera.entity.Tarjeta;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;

@Stateless
public class TarjetaDAO {

    @PersistenceContext(unitName = "transportePU")
    private EntityManager em;

    public void create(Tarjeta tarjeta) {
        em.persist(tarjeta);
    }
    
    public Tarjeta update(Tarjeta tarjeta) {
        return em.merge(tarjeta);
    }

    public Tarjeta findByUsuarioId(Long usuarioId) {
        try {
            TypedQuery<Tarjeta> query = em.createQuery("SELECT t FROM Tarjeta t WHERE t.usuario.id = :usuarioId", Tarjeta.class);
            query.setParameter("usuarioId", usuarioId);
            return query.getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }
}
EOF

# --- TransaccionDAO.java ---
cat > "$BASE_PACKAGE_PATH/billetera/dao/TransaccionDAO.java" << 'EOF'
package com.simu.billetera.dao;

import com.simu.billetera.entity.Transaccion;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Stateless
public class TransaccionDAO {
    
    @PersistenceContext(unitName = "transportePU")
    private EntityManager em;

    public void create(Transaccion transaccion) {
        em.persist(transaccion);
    }
}
EOF

# =================================================================
# CAPA DE SERVICIOS (LÓGICA DE NEGOCIO)
# =================================================================
log "Creando Servicios: BilleteraService.java"

# --- BilleteraService.java ---
cat > "$BASE_PACKAGE_PATH/billetera/service/BilleteraService.java" << 'EOF'
package com.simu.billetera.service;

import com.simu.billetera.dao.TarjetaDAO;
import com.simu.billetera.dao.TransaccionDAO;
import com.simu.billetera.entity.Tarjeta;
import com.simu.billetera.entity.TipoTransaccion;
import com.simu.billetera.entity.Transaccion;
import com.simu.usuarios.entity.Usuario;
import javax.ejb.Stateless;
import javax.inject.Inject;
import java.math.BigDecimal;

@Stateless
public class BilleteraService {

    @Inject
    private TarjetaDAO tarjetaDAO;

    @Inject
    private TransaccionDAO transaccionDAO;

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
}
EOF

# =================================================================
# CAPA DE PRESENTACIÓN (BEANS Y XHTML)
# =================================================================
log "Creando Managed Bean: BilleteraBean.java (Versión Corregida)"

# --- BilleteraBean.java ---
cat > "$BASE_PACKAGE_PATH/billetera/bean/BilleteraBean.java" << 'EOF'
package com.simu.billetera.bean;

import com.simu.billetera.entity.Tarjeta;
import com.simu.billetera.service.BilleteraService;
import com.simu.shared.util.FacesUtil;
import com.simu.usuarios.bean.SessionBean;
import com.simu.usuarios.entity.Usuario;
import javax.annotation.PostConstruct;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import java.math.BigDecimal;

@Named
@ViewScoped
public class BilleteraBean implements Serializable {
    private static final long serialVersionUID = 1L;

    @Inject
    private BilleteraService billeteraService;

    // INYECCIÓN CORRECTA: Usamos SessionBean para obtener el estado del usuario
    @Inject
    private SessionBean sessionBean;

    private Tarjeta tarjeta;
    private BigDecimal montoRecarga;

    @PostConstruct
    public void init() {
        // Obtenemos el usuario de la sesión
        Usuario usuarioActual = sessionBean.getUsuarioLogueado();
        if (usuarioActual != null) {
            // Buscamos o creamos la tarjeta para este usuario
            this.tarjeta = billeteraService.obtenerOCrearTarjeta(usuarioActual);
        } else {
            // Manejar caso en que no hay usuario logueado (aunque el filtro debería prevenir esto)
            FacesUtil.addErrorMessage("Error de Sesión", "No se pudo identificar al usuario.");
        }
    }
    
    public void recargar() {
        if (montoRecarga == null || montoRecarga.compareTo(BigDecimal.ZERO) <= 0) {
            FacesUtil.addErrorMessage("Monto Inválido", "Por favor, ingrese un monto mayor a cero.");
            return;
        }

        try {
            billeteraService.recargarSaldo(tarjeta.getUsuario().getId(), montoRecarga);
            // Actualizar la tarjeta en la vista
            this.tarjeta = billeteraService.obtenerOCrearTarjeta(sessionBean.getUsuarioLogueado());
            FacesUtil.addInfoMessage("Recarga Exitosa", "Su nuevo saldo es: " + tarjeta.getSaldo());
            montoRecarga = null; // Limpiar el campo del formulario
        } catch (Exception e) {
            FacesUtil.addErrorMessage("Error en la Recarga", e.getMessage());
        }
    }

    // Getters y Setters
    public Tarjeta getTarjeta() { return tarjeta; }
    public void setTarjeta(Tarjeta tarjeta) { this.tarjeta = tarjeta; }
    public BigDecimal getMontoRecarga() { return montoRecarga; }
    public void setMontoRecarga(BigDecimal montoRecarga) { this.montoRecarga = montoRecarga; }
}
EOF

log "Creando Vista XHTML: pasajero/billetera.xhtml"
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
                        <f:convertNumber type="currency" currencySymbol="$" />
                    </h:outputText>
                </p:panelGrid>
            </p:panel>
            
            <p:spacer height="20" />

            <p:panel header="Recargar Saldo">
                <p:panelGrid columns="3" styleClass="ui-noborder">
                    <p:outputLabel for="monto" value="Monto a Recargar:"/>
                    <p:inputNumber id="monto" value="#{billeteraBean.montoRecarga}"
                                   symbol="$ " symbolPosition="p" decimalSeparator="." thousandSeparator=","/>
                    <p:commandButton value="Recargar" action="#{billeteraBean.recargar}"
                                     update="formBilletera"/>
                </p:panelGrid>
            </p:panel>

            <p:spacer height="20" />

            <p:panel header="Historial de Transacciones">
                 <p:dataTable value="#{billeteraBean.tarjeta.transacciones}" var="tx"
                              emptyMessage="No hay transacciones registradas."
                              paginator="true" rows="10"
                              sortBy="#{tx.fechaTransaccion}" sortOrder="descending">
                    <p:column headerText="Fecha">
                        <h:outputText value="#{tx.fechaTransaccion}">
                            <f:convertDateTime pattern="dd/MM/yyyy HH:mm" />
                        </h:outputText>
                    </p:column>
                    <p:column headerText="Tipo">
                        <h:outputText value="#{tx.tipo}" />
                    </p:column>
                    <p:column headerText="Descripción">
                        <h:outputText value="#{tx.descripcion}" />
                    </p:column>
                    <p:column headerText="Monto" style="text-align:right">
                        <h:outputText value="#{tx.monto}">
                            <f:convertNumber type="currency" currencySymbol="$" />
                        </h:outputText>
                    </p:column>
                </p:dataTable>
            </p:panel>
        </h:form>
    </ui:define>
</ui:composition>
EOF

# =================================================================
# ACTUALIZACIÓN DE UI Y CONFIGURACIÓN (SOBRESCRIBIR)
# =================================================================
log "Actualizando UI y Configuración para incluir Módulo 2"

# --- template.xhtml (Acumula Módulos 1 + 2) ---
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
    <h:outputStylesheet library="css" name="style.css" />
</h:head>
<h:body>
    <p:layout fullPage="true">
        <p:layoutUnit position="north" size="100" header="Sistema de Transporte Urbano">
            <h:form rendered="#{sessionBean.isLoggedIn()}">
                <p:menubar>
                    <p:menuitem value="Dashboard" outcome="/pasajero/dashboard" rendered="#{sessionBean.isPasajero()}"/>
                    <p:menuitem value="Mi Billetera" outcome="/pasajero/billetera" rendered="#{sessionBean.isPasajero()}"/>
                    <p:menuitem value="Dashboard Admin" outcome="/admin/dashboard" rendered="#{sessionBean.isAdmin()}"/>
                    <p:menuitem value="Gestión Usuarios" outcome="/admin/usuarios/lista" rendered="#{sessionBean.isAdmin()}"/>
                    <f:facet name="options">
                        <p:outputLabel value="Bienvenido, #{sessionBean.usuarioLogueado.nombreCompleto}" style="margin-right:20px;"/>
                        <p:commandButton value="Cerrar Sesión" action="#{loginBean.cerrarSesion}" icon="pi pi-sign-out" styleClass="ui-button-warning"/>
                    </f:facet>
                </p:menubar>
            </h:form>
        </p:layoutUnit>
        <p:layoutUnit position="center">
            <p:growl id="messages" showDetail="true" sticky="false" />
            <ui:insert name="content"/>
        </p:layoutUnit>
    </p:layout>
</h:body>
</html>
EOF

# --- persistence.xml (Acumula Módulos 1 + 2) ---
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
        <exclude-unlisted-classes>true</exclude-unlisted-classes>
        <properties>
            <property name="javax.persistence.schema-generation.database.action" value="drop-and-create"/>
        </properties>
    </persistence-unit>
</persistence>
EOF


 

# --- 4. MENSAJE FINAL ---
echo ""
header "Módulo 2: Billetera Electrónica - IMPLEMENTACIÓN COMPLETA"
log "Se han creado y poblado los archivos para el Módulo de Billetera."
log "El error de compilación en 'BilleteraBean.java' ha sido corregido."
echo ""
log "Ahora puedes construir y desplegar de nuevo para probar la nueva funcionalidad:"
echo -e "   ${YELLOW}cd $PROJECT_DIR && ./deploy.sh${NC}"
