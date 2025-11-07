#!/bin/bash
# 2-modulo-billetera.sh (VERSIÓN JDBC)
# Implementa el Módulo 2: Billetera Electrónica usando JDBC plano.

set -euo pipefail

# --- SECCIÓN INICIAL (COLORES, LOGS, CARGA DE ENTORNO) ---
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
header "Implementando Módulo 2: Billetera Electrónica (JDBC)"

log "[M2] Creando POJOs: Tarjeta.java, Transaccion.java, TipoTransaccion.java"
cat > "$BASE_PACKAGE_PATH/billetera/entity/Tarjeta.java" << 'EOF'
package com.simu.billetera.entity;
import com.simu.usuarios.entity.Usuario;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
public class Tarjeta implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long id;
    private Usuario usuario;
    private BigDecimal saldo;
    private Date fechaCreacion;
    private List<Transaccion> transacciones;
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
cat > "$BASE_PACKAGE_PATH/billetera/entity/TipoTransaccion.java" << 'EOF'
package com.simu.billetera.entity;
public enum TipoTransaccion { RECARGA, PAGO_PASAJE, AJUSTE_POSITIVO, AJUSTE_NEGATIVO }
EOF
cat > "$BASE_PACKAGE_PATH/billetera/entity/Transaccion.java" << 'EOF'
package com.simu.billetera.entity;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
public class Transaccion implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long id;
    private Tarjeta tarjeta;
    private TipoTransaccion tipo;
    private BigDecimal monto;
    private Date fechaTransaccion;
    private String descripcion;
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Tarjeta getTarjeta() { return tarjeta; }
    public void setTarjeta(Tarjeta tarjeta) { this.tarjeta = tarjeta; }
    public TipoTransaccion getTipo() { return tipo; }
    public void setTipo(TipoTransaccion tipo) { this.tipo = tipo; }
    public BigDecimal getMonto() { return monto; }
    public void setMonto(BigDecimal monto) { this.monto = monto; }
    public Date getFechaTransaccion() { return fechaTransaccion; }
    public void setFechaTransaccion(Date fecha) { this.fechaTransaccion = fecha; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
}
EOF

log "[M2] Creando DAOs con JDBC: TarjetaDAO.java y TransaccionDAO.java"
cat > "$BASE_PACKAGE_PATH/billetera/dao/TarjetaDAO.java" << 'EOF'
package com.simu.billetera.dao;
import com.simu.billetera.entity.Tarjeta;
import com.simu.billetera.entity.Transaccion;
import com.simu.usuarios.dao.UsuarioDAO;
import com.simu.usuarios.entity.Usuario;
import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.sql.DataSource;
import java.sql.*;
import java.util.List;
@Stateless
public class TarjetaDAO {
    @Resource(lookup = "jdbc/miDB") private DataSource dataSource;
    @Inject private UsuarioDAO usuarioDAO;
    @Inject private TransaccionDAO transaccionDAO;
    public void create(Tarjeta tarjeta) {
        String sql = "INSERT INTO tarjetas (usuario_id, saldo, fecha_creacion) VALUES (?, ?, ?)";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, tarjeta.getUsuario().getId());
            ps.setBigDecimal(2, tarjeta.getSaldo());
            ps.setTimestamp(3, new Timestamp(new java.util.Date().getTime()));
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
    }
    public Tarjeta update(Tarjeta tarjeta) {
        String sql = "UPDATE tarjetas SET saldo = ? WHERE id = ?";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBigDecimal(1, tarjeta.getSaldo());
            ps.setLong(2, tarjeta.getId());
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
        return tarjeta;
    }
    public Tarjeta findByUsuarioId(Long usuarioId) {
        String sql = "SELECT * FROM tarjetas WHERE usuario_id = ?";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Tarjeta tarjeta = new Tarjeta();
                    tarjeta.setId(rs.getLong("id"));
                    tarjeta.setSaldo(rs.getBigDecimal("saldo"));
                    tarjeta.setFechaCreacion(rs.getTimestamp("fecha_creacion"));
                    Usuario usuario = usuarioDAO.findById(usuarioId);
                    tarjeta.setUsuario(usuario);
                    List<Transaccion> transacciones = transaccionDAO.findByTarjetaId(tarjeta.getId());
                    tarjeta.setTransacciones(transacciones);
                    return tarjeta;
                }
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return null;
    }
}
EOF
cat > "$BASE_PACKAGE_PATH/billetera/dao/TransaccionDAO.java" << 'EOF'
package com.simu.billetera.dao;
import com.simu.billetera.entity.TipoTransaccion;
import com.simu.billetera.entity.Transaccion;
import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
@Stateless
public class TransaccionDAO {
    @Resource(lookup = "jdbc/miDB") private DataSource dataSource;
    public void create(Transaccion transaccion) {
        String sql = "INSERT INTO transacciones (tarjeta_id, tipo_transaccion, monto, fecha_transaccion, descripcion) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, transaccion.getTarjeta().getId());
            ps.setString(2, transaccion.getTipo().name());
            ps.setBigDecimal(3, transaccion.getMonto());
            ps.setTimestamp(4, new Timestamp(new java.util.Date().getTime()));
            ps.setString(5, transaccion.getDescripcion());
            ps.executeUpdate();
        } catch (SQLException e) { throw new RuntimeException(e); }
    }
    public List<Transaccion> findByTarjetaId(Long tarjetaId) {
        List<Transaccion> transacciones = new ArrayList<>();
        String sql = "SELECT * FROM transacciones WHERE tarjeta_id = ? ORDER BY fecha_transaccion DESC";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, tarjetaId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Transaccion tx = new Transaccion();
                    tx.setId(rs.getLong("id"));
                    tx.setTipo(TipoTransaccion.valueOf(rs.getString("tipo_transaccion")));
                    tx.setMonto(rs.getBigDecimal("monto"));
                    tx.setFechaTransaccion(rs.getTimestamp("fecha_transaccion"));
                    tx.setDescripcion(rs.getString("descripcion"));
                    transacciones.add(tx);
                }
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return transacciones;
    }
}
EOF

log "[M2] Creando Servicio, Bean y Vista"
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
    @Inject private TarjetaDAO tarjetaDAO;
    @Inject private TransaccionDAO transaccionDAO;
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
}
EOF
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
@Named @ViewScoped
public class BilleteraBean implements Serializable {
    private static final long serialVersionUID = 1L;
    @Inject private BilleteraService billeteraService;
    @Inject private SessionBean sessionBean;
    private Tarjeta tarjeta;
    private BigDecimal montoRecarga;
    @PostConstruct
    public void init() {
        Usuario usuarioActual = sessionBean.getUsuarioLogueado();
        if (usuarioActual != null) {
            this.tarjeta = billeteraService.obtenerOCrearTarjeta(usuarioActual);
        } else {
            FacesUtil.addErrorMessage("Error de Sesión", "No se pudo identificar al usuario.");
        }
    }
    public void recargar() {
        if (montoRecarga == null || montoRecarga.compareTo(BigDecimal.ZERO) <= 0) {
            FacesUtil.addErrorMessage("Monto Inválido", "Ingrese un monto mayor a cero.");
            return;
        }
        try {
            billeteraService.recargarSaldo(tarjeta.getUsuario().getId(), montoRecarga);
            this.tarjeta = billeteraService.obtenerOCrearTarjeta(sessionBean.getUsuarioLogueado());
            FacesUtil.addInfoMessage("Recarga Exitosa", "Su nuevo saldo es: " + tarjeta.getSaldo());
            montoRecarga = null;
        } catch (Exception e) { FacesUtil.addErrorMessage("Error en la Recarga", e.getMessage()); }
    }
    public Tarjeta getTarjeta() { return tarjeta; }
    public void setTarjeta(Tarjeta t) { this.tarjeta = t; }
    public BigDecimal getMontoRecarga() { return montoRecarga; }
    public void setMontoRecarga(BigDecimal m) { this.montoRecarga = m; }
}
EOF
log "Módulo 2 (JDBC) completado."