#!/bin/bash
# 3-modulo-rutas-precio-flota.sh
#
# DESCRIPCIÓN:
#   Implementa el Módulo 3, que abarca la gestión de la infraestructura del
#   transporte. Crea las entidades, DAOs, servicios y vistas CRUD para:
#   - Rutas y sus trazados (paradas asociadas)
#   - Paradas
#   - Tarifas
#   - Flota de Autobuses
#
# IDEMPOTENCIA:
#   Este script es idempotente. Sobrescribe los archivos existentes del módulo
#   con la implementación completa, garantizando un estado consistente.

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

# --- 3. IMPLEMENTACIÓN DEL MÓDULO ---
header "Implementando Módulo 3: Rutas, Precios y Flota"

# =================================================================
# CAPA DE ENTIDADES (MODELO)
# =================================================================
log "Creando Entidades JPA: Parada, Ruta, Tarifa, Autobus"

# --- Parada.java ---
cat > "$BASE_PACKAGE_PATH/rutas/entity/Parada.java" << 'EOF'
package com.simu.rutas.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Objects;
import java.util.Set;

@Entity
@Table(name = "paradas")
public class Parada implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String nombre;

    @Column(precision = 10, scale = 7) // Para latitud
    private Double latitud;

    @Column(precision = 10, scale = 7) // Para longitud
    private Double longitud;

    @ManyToMany(mappedBy = "paradas")
    private Set<Ruta> rutas;

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public Double getLatitud() { return latitud; }
    public void setLatitud(Double latitud) { this.latitud = latitud; }
    public Double getLongitud() { return longitud; }
    public void setLongitud(Double longitud) { this.longitud = longitud; }
    public Set<Ruta> getRutas() { return rutas; }
    public void setRutas(Set<Ruta> rutas) { this.rutas = rutas; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Parada parada = (Parada) o;
        return Objects.equals(id, parada.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
EOF

# --- Ruta.java ---
cat > "$BASE_PACKAGE_PATH/rutas/entity/Ruta.java" << 'EOF'
package com.simu.rutas.entity;

import com.simu.flota.entity.Autobus;
import javax.persistence.*;
import java.io.Serializable;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;

@Entity
@Table(name = "rutas")
public class Ruta implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String nombre;

    private String descripcion;
    
    @OneToMany(mappedBy = "rutaAsignada")
    private Set<Autobus> autobuses;
    
    @ManyToMany(fetch = FetchType.EAGER) // EAGER para que se carguen al consultar la ruta
    @JoinTable(
        name = "ruta_parada",
        joinColumns = @JoinColumn(name = "ruta_id"),
        inverseJoinColumns = @JoinColumn(name = "parada_id")
    )
    private Set<Parada> paradas = new HashSet<>();

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public Set<Autobus> getAutobuses() { return autobuses; }
    public void setAutobuses(Set<Autobus> autobuses) { this.autobuses = autobuses; }
    public Set<Parada> getParadas() { return paradas; }
    public void setParadas(Set<Parada> paradas) { this.paradas = paradas; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Ruta ruta = (Ruta) o;
        return Objects.equals(id, ruta.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
EOF

# --- Tarifa.java ---
cat > "$BASE_PACKAGE_PATH/rutas/entity/Tarifa.java" << 'EOF'
package com.simu.rutas.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;

@Entity
@Table(name = "tarifas")
public class Tarifa implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String nombre; // Ej: "General", "Estudiante", "Tercera Edad"

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal precio;

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public BigDecimal getPrecio() { return precio; }
    public void setPrecio(BigDecimal precio) { this.precio = precio; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Tarifa tarifa = (Tarifa) o;
        return Objects.equals(id, tarifa.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
EOF

# --- Autobus.java ---
cat > "$BASE_PACKAGE_PATH/flota/entity/Autobus.java" << 'EOF'
package com.simu.flota.entity;

import com.simu.rutas.entity.Ruta;
import javax.persistence.*;
import java.io.Serializable;
import java.util.Objects;

@Entity
@Table(name = "autobuses")
public class Autobus implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 20)
    private String matricula;

    @Column(nullable = false)
    private int capacidad;

    @Column(length = 100)
    private String modelo;

    @ManyToOne
    @JoinColumn(name = "ruta_id")
    private Ruta rutaAsignada;
    
    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getMatricula() { return matricula; }
    public void setMatricula(String matricula) { this.matricula = matricula; }
    public int getCapacidad() { return capacidad; }
    public void setCapacidad(int capacidad) { this.capacidad = capacidad; }
    public String getModelo() { return modelo; }
    public void setModelo(String modelo) { this.modelo = modelo; }
    public Ruta getRutaAsignada() { return rutaAsignada; }
    public void setRutaAsignada(Ruta rutaAsignada) { this.rutaAsignada = rutaAsignada; }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Autobus autobus = (Autobus) o;
        return Objects.equals(id, autobus.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
EOF

# =================================================================
# CAPA DE ACCESO A DATOS (DAO)
# =================================================================
log "Creando DAOs para nuevas entidades"

# --- GenericDAO (para reusar código) ---
mkdir -p "$BASE_PACKAGE_PATH/shared/dao"
touch "$BASE_PACKAGE_PATH/shared/dao/GenericDAO.java"
cat > "$BASE_PACKAGE_PATH/shared/dao/GenericDAO.java" << 'EOF'
package com.simu.shared.dao;

import javax.persistence.EntityManager;
import java.util.List;

public abstract class GenericDAO<T, ID> {

    private final Class<T> entityClass;

    protected abstract EntityManager getEntityManager();

    public GenericDAO(Class<T> entityClass) {
        this.entityClass = entityClass;
    }

    public void create(T entity) {
        getEntityManager().persist(entity);
    }

    public T update(T entity) {
        return getEntityManager().merge(entity);
    }

    public void delete(ID id) {
        T entity = findById(id);
        if (entity != null) {
            getEntityManager().remove(entity);
        }
    }

    public T findById(ID id) {
        return getEntityManager().find(entityClass, id);
    }

    public List<T> findAll() {
        return getEntityManager().createQuery("SELECT e FROM " + entityClass.getSimpleName() + " e", entityClass).getResultList();
    }
}
EOF

# --- DAOs específicos que heredan de GenericDAO ---
# ParadaDAO.java
cat > "$BASE_PACKAGE_PATH/rutas/dao/ParadaDAO.java" << 'EOF'
package com.simu.rutas.dao;

import com.simu.rutas.entity.Parada;
import com.simu.shared.dao.GenericDAO;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Stateless
public class ParadaDAO extends GenericDAO<Parada, Long> {
    @PersistenceContext(unitName = "transportePU")
    private EntityManager em;

    public ParadaDAO() {
        super(Parada.class);
    }

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }
}
EOF

# RutaDAO.java
cat > "$BASE_PACKAGE_PATH/rutas/dao/RutaDAO.java" << 'EOF'
package com.simu.rutas.dao;

import com.simu.rutas.entity.Ruta;
import com.simu.shared.dao.GenericDAO;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Stateless
public class RutaDAO extends GenericDAO<Ruta, Long> {
    @PersistenceContext(unitName = "transportePU")
    private EntityManager em;

    public RutaDAO() {
        super(Ruta.class);
    }

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }
}
EOF

# TarifaDAO.java
cat > "$BASE_PACKAGE_PATH/rutas/dao/TarifaDAO.java" << 'EOF'
package com.simu.rutas.dao;

import com.simu.rutas.entity.Tarifa;
import com.simu.shared.dao.GenericDAO;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Stateless
public class TarifaDAO extends GenericDAO<Tarifa, Long> {
    @PersistenceContext(unitName = "transportePU")
    private EntityManager em;

    public TarifaDAO() {
        super(Tarifa.class);
    }

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }
}
EOF

# AutobusDAO.java
cat > "$BASE_PACKAGE_PATH/flota/dao/AutobusDAO.java" << 'EOF'
package com.simu.flota.dao;

import com.simu.flota.entity.Autobus;
import com.simu.shared.dao.GenericDAO;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Stateless
public class AutobusDAO extends GenericDAO<Autobus, Long> {
    @PersistenceContext(unitName = "transportePU")
    private EntityManager em;

    public AutobusDAO() {
        super(Autobus.class);
    }

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }
}
EOF

# =================================================================
# CAPA DE PRESENTACIÓN (BEANS Y XHTML)
# =================================================================
log "Creando Managed Beans para CRUDs de Administrador"

# --- GenericCrudBean (para reusar código en los beans) ---
# --- Necesitamos un conversor genérico para las entidades en p:pickList y p:selectOneMenu ---
mkdir -p "$BASE_PACKAGE_PATH/shared/converter"
touch "$BASE_PACKAGE_PATH/shared/converter/EntityConverter.java"
cat > "$BASE_PACKAGE_PATH/shared/converter/EntityConverter.java" << 'EOF'
package com.simu.shared.converter;

import javax.faces.component.UIComponent;
import javax.faces.context.FacesContext;
import javax.faces.convert.Converter;
import javax.faces.convert.FacesConverter;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;
import java.util.WeakHashMap;

@FacesConverter("entityConverter")
public class EntityConverter implements Converter {

    private static Map<Object, String> entities = new WeakHashMap<Object, String>();
    private static final AtomicLong ID_GENERATOR = new AtomicLong();

    @Override
    public String getAsString(FacesContext context, UIComponent component, Object entity) {
        synchronized (entities) {
            if (!entities.containsKey(entity)) {
                String id = String.valueOf(ID_GENERATOR.incrementAndGet());
                entities.put(entity, id);
                return id;
            }
            return entities.get(entity);
        }
    }

    @Override
    public Object getAsObject(FacesContext context, UIComponent component, String id) {
        for (Map.Entry<Object, String> entry : entities.entrySet()) {
            if (entry.getValue().equals(id)) {
                return entry.getKey();
            }
        }
        return null;
    }
}
EOF

# --- GestionParadasBean.java ---
cat > "$BASE_PACKAGE_PATH/rutas/bean/GestionParadasBean.java" << 'EOF'
package com.simu.rutas.bean;

import com.simu.rutas.dao.ParadaDAO;
import com.simu.rutas.entity.Parada;
import com.simu.shared.util.FacesUtil;
import javax.annotation.PostConstruct;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import java.util.List;

@Named
@ViewScoped
public class GestionParadasBean implements Serializable {
    private static final long serialVersionUID = 1L;

    @Inject
    private ParadaDAO paradaDAO;

    private List<Parada> paradas;
    private Parada paradaSeleccionada;

    @PostConstruct
    public void init() {
        paradas = paradaDAO.findAll();
        nuevo();
    }

    public void nuevo() {
        paradaSeleccionada = new Parada();
    }

    public void guardar() {
        try {
            if (paradaSeleccionada.getId() == null) {
                paradaDAO.create(paradaSeleccionada);
                FacesUtil.addInfoMessage("Éxito", "Parada creada.");
            } else {
                paradaDAO.update(paradaSeleccionada);
                FacesUtil.addInfoMessage("Éxito", "Parada actualizada.");
            }
            paradas = paradaDAO.findAll();
            nuevo();
        } catch (Exception e) {
            FacesUtil.addErrorMessage("Error al guardar", e.getMessage());
        }
    }

    public void eliminar(Long id) {
        paradaDAO.delete(id);
        paradas = paradaDAO.findAll();
        FacesUtil.addInfoMessage("Éxito", "Parada eliminada.");
    }
    
    // Getters y Setters
    public List<Parada> getParadas() { return paradas; }
    public Parada getParadaSeleccionada() { return paradaSeleccionada; }
    public void setParadaSeleccionada(Parada paradaSeleccionada) { this.paradaSeleccionada = paradaSeleccionada; }
}
EOF

# --- GestionRutasBean.java ---
cat > "$BASE_PACKAGE_PATH/rutas/bean/GestionRutasBean.java" << 'EOF'
package com.simu.rutas.bean;

import com.simu.rutas.dao.ParadaDAO;
import com.simu.rutas.dao.RutaDAO;
import com.simu.rutas.entity.Parada;
import com.simu.rutas.entity.Ruta;
import com.simu.shared.util.FacesUtil;
import org.primefaces.model.DualListModel;
import javax.annotation.PostConstruct;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.stream.Collectors;

@Named
@ViewScoped
public class GestionRutasBean implements Serializable {
    private static final long serialVersionUID = 1L;

    @Inject
    private RutaDAO rutaDAO;
    @Inject
    private ParadaDAO paradaDAO;
    
    private List<Ruta> rutas;
    private Ruta rutaSeleccionada;
    private DualListModel<Parada> paradasPickList;

    @PostConstruct
    public void init() {
        rutas = rutaDAO.findAll();
        nuevo();
    }

    public void nuevo() {
        rutaSeleccionada = new Ruta();
        List<Parada> paradasSource = paradaDAO.findAll();
        List<Parada> paradasTarget = new ArrayList<>();
        paradasPickList = new DualListModel<>(paradasSource, paradasTarget);
    }
    
    public void editar(Ruta ruta) {
        rutaSeleccionada = ruta;
        List<Parada> paradasSource = paradaDAO.findAll();
        List<Parada> paradasTarget = new ArrayList<>(ruta.getParadas());
        paradasSource.removeAll(paradasTarget);
        paradasPickList = new DualListModel<>(paradasSource, paradasTarget);
    }

    public void guardar() {
        try {
            rutaSeleccionada.setParadas(new HashSet<>(paradasPickList.getTarget()));
            if (rutaSeleccionada.getId() == null) {
                rutaDAO.create(rutaSeleccionada);
                FacesUtil.addInfoMessage("Éxito", "Ruta creada.");
            } else {
                rutaDAO.update(rutaSeleccionada);
                FacesUtil.addInfoMessage("Éxito", "Ruta actualizada.");
            }
            rutas = rutaDAO.findAll();
            nuevo();
        } catch (Exception e) {
            FacesUtil.addErrorMessage("Error al guardar", e.getMessage());
        }
    }

    public void eliminar(Long id) {
        rutaDAO.delete(id);
        rutas = rutaDAO.findAll();
        FacesUtil.addInfoMessage("Éxito", "Ruta eliminada.");
    }
    
    // Getters y Setters
    public List<Ruta> getRutas() { return rutas; }
    public Ruta getRutaSeleccionada() { return rutaSeleccionada; }
    public void setRutaSeleccionada(Ruta rutaSeleccionada) { this.rutaSeleccionada = rutaSeleccionada; }
    public DualListModel<Parada> getParadasPickList() { return paradasPickList; }
    public void setParadasPickList(DualListModel<Parada> paradasPickList) { this.paradasPickList = paradasPickList; }
}
EOF

# --- GestionAutobusesBean.java ---
cat > "$BASE_PACKAGE_PATH/flota/bean/GestionAutobusesBean.java" << 'EOF'
package com.simu.flota.bean;

import com.simu.flota.dao.AutobusDAO;
import com.simu.flota.entity.Autobus;
import com.simu.rutas.dao.RutaDAO;
import com.simu.rutas.entity.Ruta;
import com.simu.shared.util.FacesUtil;
import javax.annotation.PostConstruct;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import java.util.List;

@Named
@ViewScoped
public class GestionAutobusesBean implements Serializable {
    private static final long serialVersionUID = 1L;

    @Inject
    private AutobusDAO autobusDAO;
    @Inject
    private RutaDAO rutaDAO;

    private List<Autobus> autobuses;
    private Autobus autobusSeleccionado;
    private List<Ruta> rutasDisponibles;
    private Long rutaIdSeleccionada;

    @PostConstruct
    public void init() {
        autobuses = autobusDAO.findAll();
        rutasDisponibles = rutaDAO.findAll();
        nuevo();
    }

    public void nuevo() {
        autobusSeleccionado = new Autobus();
        rutaIdSeleccionada = null;
    }
    
    public void editar(Autobus autobus) {
        this.autobusSeleccionado = autobus;
        if (autobus.getRutaAsignada() != null) {
            this.rutaIdSeleccionada = autobus.getRutaAsignada().getId();
        } else {
            this.rutaIdSeleccionada = null;
        }
    }

    public void guardar() {
        try {
            if (rutaIdSeleccionada != null) {
                Ruta ruta = rutaDAO.findById(rutaIdSeleccionada);
                autobusSeleccionado.setRutaAsignada(ruta);
            } else {
                autobusSeleccionado.setRutaAsignada(null);
            }
            
            if (autobusSeleccionado.getId() == null) {
                autobusDAO.create(autobusSeleccionado);
                FacesUtil.addInfoMessage("Éxito", "Autobús creado.");
            } else {
                autobusDAO.update(autobusSeleccionado);
                FacesUtil.addInfoMessage("Éxito", "Autobús actualizado.");
            }
            autobuses = autobusDAO.findAll();
            nuevo();
        } catch (Exception e) {
            FacesUtil.addErrorMessage("Error al guardar", e.getMessage());
        }
    }

    public void eliminar(Long id) {
        autobusDAO.delete(id);
        autobuses = autobusDAO.findAll();
        FacesUtil.addInfoMessage("Éxito", "Autobús eliminado.");
    }
    
    // Getters y Setters
    public List<Autobus> getAutobuses() { return autobuses; }
    public Autobus getAutobusSeleccionado() { return autobusSeleccionado; }
    public void setAutobusSeleccionado(Autobus autobusSeleccionado) { this.autobusSeleccionado = autobusSeleccionado; }
    public List<Ruta> getRutasDisponibles() { return rutasDisponibles; }
    public Long getRutaIdSeleccionada() { return rutaIdSeleccionada; }
    public void setRutaIdSeleccionada(Long rutaIdSeleccionada) { this.rutaIdSeleccionada = rutaIdSeleccionada; }
}
EOF


log "Creando Vistas XHTML para CRUDs de Administrador"

# --- admin/paradas/lista.xhtml ---
cat > "$WEBAPP_PATH/admin/paradas/lista.xhtml" << 'EOF'
<ui:composition template="/template.xhtml"
      xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:p="http://primefaces.org/ui">
      
    <ui:define name="title">Gestión de Paradas</ui:define>
    
    <ui:define name="content">
        <h:form id="formParadas">
            <p:panel header="Lista de Paradas">
                <p:dataTable id="tabla" var="item" value="#{gestionParadasBean.paradas}" paginator="true" rows="10">
                    <p:column headerText="ID"><h:outputText value="#{item.id}" /></p:column>
                    <p:column headerText="Nombre"><h:outputText value="#{item.nombre}" /></p:column>
                    <p:column headerText="Latitud"><h:outputText value="#{item.latitud}" /></p:column>
                    <p:column headerText="Longitud"><h:outputText value="#{item.longitud}" /></p:column>
                    <p:column headerText="Acciones">
                        <p:commandButton icon="pi pi-pencil" actionListener="#{gestionParadasBean.setParadaSeleccionada(item)}"
                                         update=":formDialog" oncomplete="PF('dialog').show()"/>
                        <p:commandButton icon="pi pi-trash" actionListener="#{gestionParadasBean.eliminar(item.id)}" update="tabla">
                            <p:confirm header="Confirmación" message="¿Eliminar parada?" icon="pi pi-exclamation-triangle"/>
                        </p:commandButton>
                    </p:column>
                </p:dataTable>
                <p:toolbar>
                    <p:toolbarGroup>
                        <p:commandButton value="Nueva Parada" icon="pi pi-plus" actionListener="#{gestionParadasBean.nuevo()}"
                                         update=":formDialog" oncomplete="PF('dialog').show()"/>
                    </p:toolbarGroup>
                </p:toolbar>
            </p:panel>
        </h:form>

        <p:dialog header="Formulario de Parada" widgetVar="dialog" modal="true">
            <h:form id="formDialog">
                <p:panelGrid columns="2" styleClass="ui-noborder">
                    <p:outputLabel for="nombre" value="Nombre:"/>
                    <p:inputText id="nombre" value="#{gestionParadasBean.paradaSeleccionada.nombre}" required="true"/>
                    <p:outputLabel for="lat" value="Latitud:"/>
                    <p:inputNumber id="lat" value="#{gestionParadasBean.paradaSeleccionada.latitud}"/>
                    <p:outputLabel for="lon" value="Longitud:"/>
                    <p:inputNumber id="lon" value="#{gestionParadasBean.paradaSeleccionada.longitud}"/>
                </p:panelGrid>
                <p:commandButton value="Guardar" actionListener="#{gestionParadasBean.guardar}" 
                                 update=":formParadas:tabla" oncomplete="if(!args.validationFailed) PF('dialog').hide();"/>
            </h:form>
        </p:dialog>
        
        <p:confirmDialog global="true"><p:commandButton value="Sí" type="button" styleClass="ui-confirmdialog-yes"/><p:commandButton value="No" type="button" styleClass="ui-confirmdialog-no"/></p:confirmDialog>
    </ui:define>
</ui:composition>
EOF

# --- admin/rutas/lista.xhtml ---
cat > "$WEBAPP_PATH/admin/rutas/lista.xhtml" << 'EOF'
<ui:composition template="/template.xhtml"
      xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:p="http://primefaces.org/ui">
      
    <ui:define name="title">Gestión de Rutas</ui:define>
    
    <ui:define name="content">
        <h:form id="formRutas">
            <p:panel header="Lista de Rutas">
                <p:dataTable id="tabla" var="item" value="#{gestionRutasBean.rutas}" paginator="true" rows="10">
                    <p:column headerText="ID"><h:outputText value="#{item.id}" /></p:column>
                    <p:column headerText="Nombre"><h:outputText value="#{item.nombre}" /></p:column>
                    <p:column headerText="Descripción"><h:outputText value="#{item.descripcion}" /></p:column>
                    <p:column headerText="Acciones">
                        <p:commandButton icon="pi pi-pencil" actionListener="#{gestionRutasBean.editar(item)}"
                                         update=":formDialog" oncomplete="PF('dialog').show()"/>
                        <p:commandButton icon="pi pi-trash" actionListener="#{gestionRutasBean.eliminar(item.id)}" update="tabla">
                            <p:confirm header="Confirmación" message="¿Eliminar ruta?" icon="pi pi-exclamation-triangle"/>
                        </p:commandButton>
                    </p:column>
                </p:dataTable>
                <p:toolbar>
                    <p:toolbarGroup>
                        <p:commandButton value="Nueva Ruta" icon="pi pi-plus" actionListener="#{gestionRutasBean.nuevo()}"
                                         update=":formDialog" oncomplete="PF('dialog').show()"/>
                    </p:toolbarGroup>
                </p:toolbar>
            </p:panel>
        </h:form>

        <p:dialog header="Formulario de Ruta" widgetVar="dialog" modal="true" width="700">
            <h:form id="formDialog">
                <p:panelGrid columns="2" styleClass="ui-noborder">
                    <p:outputLabel for="nombre" value="Nombre:"/>
                    <p:inputText id="nombre" value="#{gestionRutasBean.rutaSeleccionada.nombre}" required="true"/>
                    <p:outputLabel for="desc" value="Descripción:"/>
                    <p:inputTextarea id="desc" value="#{gestionRutasBean.rutaSeleccionada.descripcion}"/>
                </p:panelGrid>
                
                <p:pickList value="#{gestionRutasBean.paradasPickList}" var="parada" itemLabel="#{parada.nombre}" itemValue="#{parada}" converter="entityConverter" />
                
                <p:commandButton value="Guardar" actionListener="#{gestionRutasBean.guardar}" 
                                 update=":formRutas:tabla" oncomplete="if(!args.validationFailed) PF('dialog').hide();"/>
            </h:form>
        </p:dialog>
        
        <p:confirmDialog global="true"><p:commandButton value="Sí" type="button" styleClass="ui-confirmdialog-yes"/><p:commandButton value="No" type="button" styleClass="ui-confirmdialog-no"/></p:confirmDialog>
    </ui:define>
</ui:composition>
EOF

# --- admin/flota/lista.xhtml ---
cat > "$WEBAPP_PATH/admin/flota/lista.xhtml" << 'EOF'
<ui:composition template="/template.xhtml"
      xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:f="http://xmlns.jcp.org/jsf/core"
      xmlns:p="http://primefaces.org/ui">
      
    <ui:define name="title">Gestión de Flota</ui:define>
    
    <ui:define name="content">
        <h:form id="formFlota">
            <p:panel header="Lista de Autobuses">
                <p:dataTable id="tabla" var="item" value="#{gestionAutobusesBean.autobuses}" paginator="true" rows="10">
                    <p:column headerText="ID"><h:outputText value="#{item.id}" /></p:column>
                    <p:column headerText="Matrícula"><h:outputText value="#{item.matricula}" /></p:column>
                    <p:column headerText="Modelo"><h:outputText value="#{item.modelo}" /></p:column>
                    <p:column headerText="Capacidad"><h:outputText value="#{item.capacidad}" /></p:column>
                    <p:column headerText="Ruta Asignada"><h:outputText value="#{item.rutaAsignada.nombre}" /></p:column>
                    <p:column headerText="Acciones">
                        <p:commandButton icon="pi pi-pencil" actionListener="#{gestionAutobusesBean.editar(item)}"
                                         update=":formDialog" oncomplete="PF('dialog').show()"/>
                        <p:commandButton icon="pi pi-trash" actionListener="#{gestionAutobusesBean.eliminar(item.id)}" update="tabla">
                            <p:confirm header="Confirmación" message="¿Eliminar autobús?" icon="pi pi-exclamation-triangle"/>
                        </p:commandButton>
                    </p:column>
                </p:dataTable>
                <p:toolbar>
                    <p:toolbarGroup>
                        <p:commandButton value="Nuevo Autobús" icon="pi pi-plus" actionListener="#{gestionAutobusesBean.nuevo()}"
                                         update=":formDialog" oncomplete="PF('dialog').show()"/>
                    </p:toolbarGroup>
                </p:toolbar>
            </p:panel>
        </h:form>

        <p:dialog header="Formulario de Autobús" widgetVar="dialog" modal="true">
            <h:form id="formDialog">
                <p:panelGrid columns="2" styleClass="ui-noborder">
                    <p:outputLabel for="mat" value="Matrícula:"/>
                    <p:inputText id="mat" value="#{gestionAutobusesBean.autobusSeleccionado.matricula}" required="true"/>
                    <p:outputLabel for="mod" value="Modelo:"/>
                    <p:inputText id="mod" value="#{gestionAutobusesBean.autobusSeleccionado.modelo}"/>
                    <p:outputLabel for="cap" value="Capacidad:"/>
                    <p:inputNumber id="cap" value="#{gestionAutobusesBean.autobusSeleccionado.capacidad}" required="true"/>
                    <p:outputLabel for="ruta" value="Ruta Asignada:"/>
                    <p:selectOneMenu id="ruta" value="#{gestionAutobusesBean.rutaIdSeleccionada}">
                        <f:selectItem itemLabel="Sin asignar" itemValue="#{null}" />
                        <f:selectItems value="#{gestionAutobusesBean.rutasDisponibles}" var="ruta" itemLabel="#{ruta.nombre}" itemValue="#{ruta.id}"/>
                    </p:selectOneMenu>
                </p:panelGrid>
                <p:commandButton value="Guardar" actionListener="#{gestionAutobusesBean.guardar}" 
                                 update=":formFlota:tabla" oncomplete="if(!args.validationFailed) PF('dialog').hide();"/>
            </h:form>
        </p:dialog>
        
        <p:confirmDialog global="true"><p:commandButton value="Sí" type="button" styleClass="ui-confirmdialog-yes"/><p:commandButton value="No" type="button" styleClass="ui-confirmdialog-no"/></p:confirmDialog>
    </ui:define>
</ui:composition>
EOF

# =================================================================
# ACTUALIZACIÓN DE CONFIGURACIÓN Y UI
# =================================================================
log "Añadiendo enlaces de administración al template"
MENU_ITEMS=(
    "<p:menuitem value=\"Gestión Rutas\" url=\"/admin/rutas/lista.xhtml\" rendered=\"#{sessionBean.isAdmin()}\"/>"
    "<p:menuitem value=\"Gestión Paradas\" url=\"/admin/paradas/lista.xhtml\" rendered=\"#{sessionBean.isAdmin()}\"/>"
    "<p:menuitem value=\"Gestión Flota\" url=\"/admin/flota/lista.xhtml\" rendered=\"#{sessionBean.isAdmin()}\"/>"
)
ANCHOR_LINE="<p:menuitem value=\"Gestión Usuarios\""

for item in "${MENU_ITEMS[@]}"; do
    if ! grep -qF "$item" "$WEBAPP_PATH/template.xhtml"; then
        sed -i "/${ANCHOR_LINE}/a ${item}" "$WEBAPP_PATH/template.xhtml"
    fi
done

log "Actualizando persistence.xml con nuevas entidades"
CLASSES_TO_ADD="        <class>${PACKAGE_ROOT}.rutas.entity.Parada</class>\\n        <class>${PACKAGE_ROOT}.rutas.entity.Ruta</class>\\n        <class>${PACKAGE_ROOT}.rutas.entity.Tarifa</class>\\n        <class>${PACKAGE_ROOT}.flota.entity.Autobus</class>"
sed -i "/<!-- ENTITIES_PLACEHOLDER -->/ i ${CLASSES_TO_ADD}" "$RESOURCES_PATH/META-INF/persistence.xml"

# --- 4. MENSAJE FINAL ---
echo ""
header "Módulo 3: Rutas, Precios y Flota - IMPLEMENTACIÓN COMPLETA"
log "Se han creado todas las interfaces de administración para la infraestructura."
warn "El primer paso después de desplegar será crear Paradas, luego Rutas (asociando las paradas), y finalmente Autobuses (asignándolos a una ruta)."
echo ""
log "Para construir y desplegar los cambios, ejecuta:"
echo -e "   ${YELLOW}cd $PROJECT_DIR && ./deploy.sh${NC}"