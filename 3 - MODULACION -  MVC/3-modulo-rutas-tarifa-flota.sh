#!/bin/bash
# 3-modulo-rutas-tarifa-flota.sh (VERSIÓN JDBC)
# Implementa el Módulo 3: Rutas, Tarifas y Flota usando JDBC plano.

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
header "Implementando Módulo 3: Rutas, Tarifas y Flota (JDBC)"

log "[M3] Creando POJOs: Parada, Ruta, Tarifa, Autobus"
cat > "$BASE_PACKAGE_PATH/rutas/entity/Parada.java" << 'EOF'
package com.simu.rutas.entity;

import com.google.gson.annotations.SerializedName; // <-- AÑADIR ESTE IMPORT
import java.io.Serializable;
import java.util.Objects;

public class Parada implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long id;
    private String nombre;

    @SerializedName("lat") // <-- AÑADIR ESTA ANOTACIÓN
    private Double latitud;

    @SerializedName("lng") // <-- AÑADIR ESTA ANOTACIÓN
    private Double longitud;

    // Getters y Setters (sin cambios)
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public Double getLatitud() { return latitud; }
    public void setLatitud(Double latitud) { this.latitud = latitud; }
    public Double getLongitud() { return longitud; }
    public void setLongitud(Double longitud) { this.longitud = longitud; }

    // equals y hashCode (sin cambios)
    @Override
    public boolean equals(Object o) { if (this == o) return true; if (o == null || getClass() != o.getClass()) return false; Parada parada = (Parada) o; return Objects.equals(id, parada.id); }
    @Override
    public int hashCode() { return Objects.hash(id); }
}
EOF

cat > "$BASE_PACKAGE_PATH/rutas/entity/Ruta.java" << 'EOF'
package com.simu.rutas.entity;
import java.io.Serializable;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
public class Ruta implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long id;
    private String nombre;
    private String descripcion;
    private Set<Parada> paradas = new HashSet<>();
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public Set<Parada> getParadas() { return paradas; }
    public void setParadas(Set<Parada> paradas) { this.paradas = paradas; }
    @Override
    public boolean equals(Object o) { if (this == o) return true; if (o == null || getClass() != o.getClass()) return false; Ruta ruta = (Ruta) o; return Objects.equals(id, ruta.id); }
    @Override
    public int hashCode() { return Objects.hash(id); }
}
EOF
cat > "$BASE_PACKAGE_PATH/rutas/entity/Tarifa.java" << 'EOF'
package com.simu.rutas.entity;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;
public class Tarifa implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long id;
    private String nombre;
    private BigDecimal precio;
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public BigDecimal getPrecio() { return precio; }
    public void setPrecio(BigDecimal precio) { this.precio = precio; }
    @Override
    public boolean equals(Object o) { if (this == o) return true; if (o == null || getClass() != o.getClass()) return false; Tarifa t = (Tarifa) o; return Objects.equals(id, t.id); }
    @Override
    public int hashCode() { return Objects.hash(id); }
}
EOF
cat > "$BASE_PACKAGE_PATH/flota/entity/Autobus.java" << 'EOF'
package com.simu.flota.entity;
import com.simu.rutas.entity.Ruta;
import java.io.Serializable;
import java.util.Objects;
public class Autobus implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long id;
    private String matricula;
    private int capacidad;
    private String modelo;
    private Ruta rutaAsignada;
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
    public boolean equals(Object o) { if (this == o) return true; if (o == null || getClass() != o.getClass()) return false; Autobus a = (Autobus) o; return Objects.equals(id, a.id); }
    @Override
    public int hashCode() { return Objects.hash(id); }
}
EOF

log "[M3] Creando DAOs con JDBC"
cat > "$BASE_PACKAGE_PATH/rutas/dao/ParadaDAO.java" << 'EOF'
package com.simu.rutas.dao;
import com.simu.rutas.entity.Parada;
import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
@Stateless
public class ParadaDAO {
    @Resource(lookup = "jdbc/miDB") private DataSource dataSource;
    private Parada mapRow(ResultSet rs) throws SQLException {
        Parada p = new Parada();
        p.setId(rs.getLong("id"));
        p.setNombre(rs.getString("nombre"));
        p.setLatitud(rs.getObject("latitud") != null ? rs.getDouble("latitud") : null);
        p.setLongitud(rs.getObject("longitud") != null ? rs.getDouble("longitud") : null);
        return p;
    }
    public void create(Parada p) {
        String sql = "INSERT INTO paradas (nombre, latitud, longitud) VALUES (?, ?, ?)";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, p.getNombre());
            ps.setObject(2, p.getLatitud());
            ps.setObject(3, p.getLongitud());
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
    }
    public Parada update(Parada p) {
        String sql = "UPDATE paradas SET nombre = ?, latitud = ?, longitud = ? WHERE id = ?";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, p.getNombre());
            ps.setObject(2, p.getLatitud());
            ps.setObject(3, p.getLongitud());
            ps.setLong(4, p.getId());
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
        return p;
    }
    public void delete(Long id) {
        String sql = "DELETE FROM paradas WHERE id = ?";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
    }
    public Parada findById(Long id) {
        String sql = "SELECT * FROM paradas WHERE id = ?";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return null;
    }
    public List<Parada> findAll() {
        List<Parada> list = new ArrayList<>();
        String sql = "SELECT * FROM paradas ORDER BY nombre";
        try (Connection c = dataSource.getConnection(); Statement s = c.createStatement(); ResultSet rs = s.executeQuery(sql)) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { throw new RuntimeException(e); }
        return list;
    }
}
EOF
cat > "$BASE_PACKAGE_PATH/rutas/dao/RutaDAO.java" << 'EOF'
package com.simu.rutas.dao;
import com.simu.rutas.entity.Parada;
import com.simu.rutas.entity.Ruta;
import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
@Stateless
public class RutaDAO {
    @Resource(lookup = "jdbc/miDB") private DataSource dataSource;
    @Inject private ParadaDAO paradaDAO;
    private Ruta mapRow(ResultSet rs) throws SQLException {
        Ruta r = new Ruta();
        r.setId(rs.getLong("id"));
        r.setNombre(rs.getString("nombre"));
        r.setDescripcion(rs.getString("descripcion"));
        return r;
    }
    private Set<Parada> findParadasByRutaId(Long rutaId) {
        Set<Parada> paradas = new HashSet<>();
        String sql = "SELECT parada_id FROM ruta_parada WHERE ruta_id = ?";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, rutaId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Parada parada = paradaDAO.findById(rs.getLong("parada_id"));
                    if (parada != null) paradas.add(parada);
                }
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return paradas;
    }
    private void updateParadasForRuta(Ruta r, Connection c) throws SQLException {
        String deleteSql = "DELETE FROM ruta_parada WHERE ruta_id = ?";
        try (PreparedStatement ps = c.prepareStatement(deleteSql)) {
            ps.setLong(1, r.getId());
            ps.executeUpdate();
        }
        if (r.getParadas() != null && !r.getParadas().isEmpty()) {
            String insertSql = "INSERT INTO ruta_parada (ruta_id, parada_id) VALUES (?, ?)";
            try (PreparedStatement ps = c.prepareStatement(insertSql)) {
                for (Parada p : r.getParadas()) {
                    ps.setLong(1, r.getId());
                    ps.setLong(2, p.getId());
                    ps.addBatch();
                }
                ps.executeBatch();
            }
        }
    }
    public void create(Ruta r) {
        String sql = "INSERT INTO rutas (nombre, descripcion) VALUES (?, ?)";
        try (Connection c = dataSource.getConnection()) {
            c.setAutoCommit(false);
            try (PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, r.getNombre());
                ps.setString(2, r.getDescripcion());
                ps.executeUpdate();
                try (ResultSet generatedKeys = ps.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        r.setId(generatedKeys.getLong(1));
                        updateParadasForRuta(r, c);
                    }
                }
                c.commit();
            } catch (SQLException e) { c.rollback(); throw e; }
        } catch (SQLException e) { throw new RuntimeException(e); }
    }
    public Ruta update(Ruta r) {
        String sql = "UPDATE rutas SET nombre = ?, descripcion = ? WHERE id = ?";
        try (Connection c = dataSource.getConnection()) {
            c.setAutoCommit(false);
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, r.getNombre());
                ps.setString(2, r.getDescripcion());
                ps.setLong(3, r.getId());
                ps.executeUpdate();
                updateParadasForRuta(r, c);
                c.commit();
            } catch (SQLException e) { c.rollback(); throw e; }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return r;
    }
    public void delete(Long id) {
        String sql = "DELETE FROM rutas WHERE id = ?";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
    }
    public Ruta findById(Long id) {
        String sql = "SELECT * FROM rutas WHERE id = ?";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Ruta r = mapRow(rs);
                    r.setParadas(findParadasByRutaId(id));
                    return r;
                }
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return null;
    }
    public List<Ruta> findAll() {
        List<Ruta> list = new ArrayList<>();
        String sql = "SELECT * FROM rutas ORDER BY nombre";
        try (Connection c = dataSource.getConnection(); Statement s = c.createStatement(); ResultSet rs = s.executeQuery(sql)) {
            while (rs.next()) {
                Ruta r = mapRow(rs);
                r.setParadas(findParadasByRutaId(r.getId()));
                list.add(r);
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return list;
    }
    public List<Ruta> findRutasContainingParadas(Long idParadaOrigen, Long idParadaDestino) {
    List<Ruta> rutasEncontradas = new ArrayList<>();
    // Esta consulta SQL busca rutas que tengan una entrada en ruta_parada para
    // la parada de origen Y que también tengan una entrada para la parada de destino.
    String sql = "SELECT r.* FROM rutas r " +
                    "WHERE EXISTS (SELECT 1 FROM ruta_parada rp WHERE rp.ruta_id = r.id AND rp.parada_id = ?) " +
                    "AND EXISTS (SELECT 1 FROM ruta_parada rp WHERE rp.ruta_id = r.id AND rp.parada_id = ?)";

    try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
        ps.setLong(1, idParadaOrigen);
        ps.setLong(2, idParadaDestino);
            
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Ruta r = mapRow(rs);
                // Importante: Cargar las paradas de la ruta encontrada para el mapa
                r.setParadas(findParadasByRutaId(r.getId()));
                rutasEncontradas.add(r);
            }
        }
    } catch (SQLException e) {
        throw new RuntimeException("Error al buscar rutas por paradas", e);
    }
    return rutasEncontradas;
}

}
EOF
cat > "$BASE_PACKAGE_PATH/flota/dao/AutobusDAO.java" << 'EOF'
package com.simu.flota.dao;
import com.simu.flota.entity.Autobus;
import com.simu.rutas.dao.RutaDAO;
import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
@Stateless
public class AutobusDAO {
    @Resource(lookup = "jdbc/miDB") private DataSource dataSource;
    @Inject private RutaDAO rutaDAO;
    private Autobus mapRow(ResultSet rs) throws SQLException {
        Autobus a = new Autobus();
        a.setId(rs.getLong("id"));
        a.setMatricula(rs.getString("matricula"));
        a.setCapacidad(rs.getInt("capacidad"));
        a.setModelo(rs.getString("modelo"));
        long rutaId = rs.getLong("ruta_id");
        if (!rs.wasNull()) {
            a.setRutaAsignada(rutaDAO.findById(rutaId));
        }
        return a;
    }
    public void create(Autobus a) {
        String sql = "INSERT INTO autobuses (matricula, capacidad, modelo, ruta_id) VALUES (?, ?, ?, ?)";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, a.getMatricula());
            ps.setInt(2, a.getCapacidad());
            ps.setString(3, a.getModelo());
            if (a.getRutaAsignada() != null) ps.setLong(4, a.getRutaAsignada().getId());
            else ps.setNull(4, Types.BIGINT);
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
    }
    public Autobus update(Autobus a) {
        String sql = "UPDATE autobuses SET matricula = ?, capacidad = ?, modelo = ?, ruta_id = ? WHERE id = ?";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, a.getMatricula());
            ps.setInt(2, a.getCapacidad());
            ps.setString(3, a.getModelo());
            if (a.getRutaAsignada() != null) ps.setLong(4, a.getRutaAsignada().getId());
            else ps.setNull(4, Types.BIGINT);
            ps.setLong(5, a.getId());
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
        return a;
    }
    public void delete(Long id) {
        String sql = "DELETE FROM autobuses WHERE id = ?";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
    }
    public Autobus findById(Long id) {
        String sql = "SELECT * FROM autobuses WHERE id = ?";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return null;
    }
    public List<Autobus> findAll() {
        List<Autobus> list = new ArrayList<>();
        String sql = "SELECT * FROM autobuses ORDER BY matricula";
        try (Connection c = dataSource.getConnection(); Statement s = c.createStatement(); ResultSet rs = s.executeQuery(sql)) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { throw new RuntimeException(e); }
        return list;
    }
}
EOF

log "[M3] Creando Beans y Conversor"
cat > "$BASE_PACKAGE_PATH/shared/converter/EntityConverter.java" << 'EOF'
package com.simu.shared.converter;
import javax.faces.component.UIComponent;
import javax.faces.context.FacesContext;
import javax.faces.convert.Converter;
import javax.faces.convert.FacesConverter;
import java.util.Map;
import java.util.WeakHashMap;
import java.util.concurrent.atomic.AtomicLong;
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
@Named @ViewScoped
public class GestionParadasBean implements Serializable {
    private static final long serialVersionUID = 1L;
    @Inject private ParadaDAO paradaDAO;
    private List<Parada> paradas;
    private Parada paradaSeleccionada;
    @PostConstruct public void init() { paradas = paradaDAO.findAll(); nuevo(); }
    public void nuevo() { paradaSeleccionada = new Parada(); }
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
        } catch (Exception e) { FacesUtil.addErrorMessage("Error al guardar", e.getMessage()); }
    }
    public void eliminar(Long id) { paradaDAO.delete(id); paradas = paradaDAO.findAll(); FacesUtil.addInfoMessage("Éxito", "Parada eliminada."); }
    public List<Parada> getParadas() { return paradas; }
    public Parada getParadaSeleccionada() { return paradaSeleccionada; }
    public void setParadaSeleccionada(Parada p) { this.paradaSeleccionada = p; }
}
EOF
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
@Named @ViewScoped
public class GestionRutasBean implements Serializable {
    private static final long serialVersionUID = 1L;
    @Inject private RutaDAO rutaDAO;
    @Inject private ParadaDAO paradaDAO;
    private List<Ruta> rutas;
    private Ruta rutaSeleccionada;
    private DualListModel<Parada> paradasPickList;
    @PostConstruct public void init() { rutas = rutaDAO.findAll(); nuevo(); }
    public void nuevo() {
        rutaSeleccionada = new Ruta();
        List<Parada> paradasSource = paradaDAO.findAll();
        paradasPickList = new DualListModel<>(paradasSource, new ArrayList<>());
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
        } catch (Exception e) { FacesUtil.addErrorMessage("Error al guardar", e.getMessage()); }
    }
    public void eliminar(Long id) { rutaDAO.delete(id); rutas = rutaDAO.findAll(); FacesUtil.addInfoMessage("Éxito", "Ruta eliminada."); }
    public List<Ruta> getRutas() { return rutas; }
    public Ruta getRutaSeleccionada() { return rutaSeleccionada; }
    public void setRutaSeleccionada(Ruta r) { this.rutaSeleccionada = r; }
    public DualListModel<Parada> getParadasPickList() { return paradasPickList; }
    public void setParadasPickList(DualListModel<Parada> p) { this.paradasPickList = p; }
}
EOF
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
@Named @ViewScoped
public class GestionAutobusesBean implements Serializable {
    private static final long serialVersionUID = 1L;
    @Inject private AutobusDAO autobusDAO;
    @Inject private RutaDAO rutaDAO;
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
    public void nuevo() { autobusSeleccionado = new Autobus(); rutaIdSeleccionada = null; }
    public void editar(Autobus autobus) {
        this.autobusSeleccionado = autobus;
        if (autobus.getRutaAsignada() != null) this.rutaIdSeleccionada = autobus.getRutaAsignada().getId();
        else this.rutaIdSeleccionada = null;
    }
    public void guardar() {
        try {
            if (rutaIdSeleccionada != null) autobusSeleccionado.setRutaAsignada(rutaDAO.findById(rutaIdSeleccionada));
            else autobusSeleccionado.setRutaAsignada(null);
            
            if (autobusSeleccionado.getId() == null) {
                autobusDAO.create(autobusSeleccionado);
                FacesUtil.addInfoMessage("Éxito", "Autobús creado.");
            } else {
                autobusDAO.update(autobusSeleccionado);
                FacesUtil.addInfoMessage("Éxito", "Autobús actualizado.");
            }
            autobuses = autobusDAO.findAll();
            nuevo();
        } catch (Exception e) { FacesUtil.addErrorMessage("Error al guardar", e.getMessage()); }
    }
    public void eliminar(Long id) { autobusDAO.delete(id); autobuses = autobusDAO.findAll(); FacesUtil.addInfoMessage("Éxito", "Autobús eliminado."); }
    public List<Autobus> getAutobuses() { return autobuses; }
    public Autobus getAutobusSeleccionado() { return autobusSeleccionado; }
    public void setAutobusSeleccionado(Autobus a) { this.autobusSeleccionado = a; }
    public List<Ruta> getRutasDisponibles() { return rutasDisponibles; }
    public Long getRutaIdSeleccionada() { return rutaIdSeleccionada; }
    public void setRutaIdSeleccionada(Long id) { this.rutaIdSeleccionada = id; }
}
EOF

log "Módulo 3 (JDBC) completado."