#!/bin/bash
# 5-modulo-historial.sh (VERSIÓN JDBC)
# Implementa el Módulo 5: Historial de Viajes usando JDBC plano.

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
header "Implementando Módulo 5: Historial de Viajes (JDBC)"

log "[M5] Creando POJO: Viaje.java"
cat > "$BASE_PACKAGE_PATH/viajes/entity/Viaje.java" << 'EOF'
package com.simu.viajes.entity;
import com.simu.flota.entity.Autobus;
import com.simu.rutas.entity.Ruta;
import com.simu.usuarios.entity.Usuario;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import java.util.Objects;
public class Viaje implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long id;
    private Usuario usuario;
    private Ruta ruta;
    private Autobus autobus;
    private Date fechaHora;
    private BigDecimal costoPasaje;
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Usuario getUsuario() { return usuario; }
    public void setUsuario(Usuario usuario) { this.usuario = usuario; }
    public Ruta getRuta() { return ruta; }
    public void setRuta(Ruta ruta) { this.ruta = ruta; }
    public Autobus getAutobus() { return autobus; }
    public void setAutobus(Autobus autobus) { this.autobus = autobus; }
    public Date getFechaHora() { return fechaHora; }
    public void setFechaHora(Date fechaHora) { this.fechaHora = fechaHora; }
    public BigDecimal getCostoPasaje() { return costoPasaje; }
    public void setCostoPasaje(BigDecimal c) { this.costoPasaje = c; }
    @Override public boolean equals(Object o) { if (this == o) return true; if (o == null || getClass() != o.getClass()) return false; Viaje v = (Viaje) o; return Objects.equals(id, v.id); }
    @Override public int hashCode() { return Objects.hash(id); }
}
EOF

log "[M5] Creando DAO con JDBC: ViajeDAO.java"
cat > "$BASE_PACKAGE_PATH/viajes/dao/ViajeDAO.java" << 'EOF'
package com.simu.viajes.dao;
import com.simu.flota.dao.AutobusDAO;
import com.simu.rutas.dao.RutaDAO;
import com.simu.usuarios.dao.UsuarioDAO;
import com.simu.viajes.entity.Viaje;
import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
@Stateless
public class ViajeDAO {
    @Resource(lookup = "jdbc/miDB") private DataSource dataSource;
    @Inject private UsuarioDAO usuarioDAO;
    @Inject private RutaDAO rutaDAO;
    @Inject private AutobusDAO autobusDAO;
    private Viaje mapRow(ResultSet rs) throws SQLException {
        Viaje v = new Viaje();
        v.setId(rs.getLong("id"));
        v.setFechaHora(rs.getTimestamp("fecha_hora"));
        v.setCostoPasaje(rs.getBigDecimal("costo_pasaje"));
        v.setUsuario(usuarioDAO.findById(rs.getLong("usuario_id")));
        long rutaId = rs.getLong("ruta_id");
        if (!rs.wasNull()) v.setRuta(rutaDAO.findById(rutaId));
        v.setAutobus(autobusDAO.findById(rs.getLong("autobus_id")));
        return v;
    }
    public void create(Viaje v) {
        String sql = "INSERT INTO viajes (usuario_id, ruta_id, autobus_id, fecha_hora, costo_pasaje) VALUES (?, ?, ?, ?, ?)";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, v.getUsuario().getId());
            if (v.getRuta() != null) ps.setLong(2, v.getRuta().getId()); else ps.setNull(2, Types.BIGINT);
            ps.setLong(3, v.getAutobus().getId());
            ps.setTimestamp(4, new Timestamp(new java.util.Date().getTime()));
            ps.setBigDecimal(5, v.getCostoPasaje());
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
    }
    public List<Viaje> findByUsuarioId(Long usuarioId) {
        List<Viaje> list = new ArrayList<>();
        String sql = "SELECT * FROM viajes WHERE usuario_id = ? ORDER BY fecha_hora DESC";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return list;
    }
}
EOF

log "[M5] Actualizando BilleteraService con pago de pasaje"
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
            return tarjetaDAO.findByUsuarioId(usuario.getId());
        }
        return tarjeta;
    }
    public void recargarSaldo(Long usuarioId, BigDecimal monto) {
        if (monto.compareTo(BigDecimal.ZERO) <= 0) { throw new IllegalArgumentException("El monto debe ser positivo."); }
        Tarjeta tarjeta = tarjetaDAO.findByUsuarioId(usuarioId);
        if (tarjeta == null) { throw new IllegalStateException("El usuario no tiene tarjeta."); }
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
        if (tarjeta == null) { throw new IllegalStateException("El usuario no tiene tarjeta."); }
        if (tarjeta.getSaldo().compareTo(costo) < 0) { throw new Exception("Saldo insuficiente."); }
        Autobus autobus = autobusDAO.findById(autobusId);
        if (autobus == null) { throw new Exception("El autobús no existe."); }
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

log "[M5] Creando Servicio, Bean y Vista para el historial"
cat > "$BASE_PACKAGE_PATH/historial/service/ConsultaHistorialService.java" << 'EOF'
package com.simu.historial.service;
import com.simu.viajes.dao.ViajeDAO;
import com.simu.viajes.entity.Viaje;
import javax.ejb.Stateless;
import javax.inject.Inject;
import java.util.List;
@Stateless
public class ConsultaHistorialService {
    @Inject private ViajeDAO viajeDAO;
    public List<Viaje> obtenerHistorialPorUsuario(Long usuarioId) { return viajeDAO.findByUsuarioId(usuarioId); }
}
EOF
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
@Named @ViewScoped
public class HistorialBean implements Serializable {
    private static final long serialVersionUID = 1L;
    @Inject private ConsultaHistorialService historialService;
    @Inject private SessionBean sessionBean;
    private List<Viaje> historialViajes;
    @PostConstruct
    public void init() {
        if (sessionBean.isLoggedIn()) {
            historialViajes = historialService.obtenerHistorialPorUsuario(sessionBean.getUsuarioLogueado().getId());
        } else {
            historialViajes = Collections.emptyList();
        }
    }
    public List<Viaje> getHistorialViajes() { return historialViajes; }
}
EOF

log "Módulo 5 (JDBC) completado."