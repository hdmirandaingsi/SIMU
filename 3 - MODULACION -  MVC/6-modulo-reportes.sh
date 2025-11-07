#!/bin/bash
# 6-modulo-reportes.sh (VERSIÓN MEJORADA CON FILTROS Y EXPORTACIÓN)
# Implementa el Módulo 6: Reportes y Analítica.
#
# MEJORAS INCLUIDAS:
# - Lógica de backend (DAO, Service, Bean) modificada para aceptar rangos de fecha.
# - El DashboardBean ahora maneja el estado de los filtros y recarga los datos.
# - Se incluyen listas de datos explícitas en el bean para poder usarlas en las tablas de exportación.
# - La vista del dashboard (que se creará en el script 9) usará estos cambios.

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
header "Implementando Módulo 6: Reportes (Mejorado con Filtros)"

log "[M6] Creando DTOs para los reportes (sin cambios)"
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

log "[M6] Creando ReporteDAO.java (MODIFICADO para aceptar filtros de fecha)"
cat > "$BASE_PACKAGE_PATH/reportes/dao/ReporteDAO.java" << 'EOF'
package com.simu.reportes.dao;

import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Stateless
public class ReporteDAO {
    @Resource(lookup = "jdbc/miDB") private DataSource dataSource;
    
    public Long countPasajeros() {
        String sql = "SELECT COUNT(u.id) FROM usuarios u JOIN roles r ON u.rol_id = r.id WHERE r.nombre = 'PASAJERO'";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getLong(1);
        } catch (SQLException e) { throw new RuntimeException(e); }
        return 0L;
    }

    public Long countTotalViajes(Date fechaInicio, Date fechaFin) {
        String sql = "SELECT COUNT(*) FROM viajes WHERE fecha_hora BETWEEN ? AND ?";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setTimestamp(1, new java.sql.Timestamp(fechaInicio.getTime()));
            ps.setTimestamp(2, new java.sql.Timestamp(fechaFin.getTime()));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getLong(1);
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return 0L;
    }

    public List<Object[]> getIngresosPorRuta(Date fechaInicio, Date fechaFin) {
        List<Object[]> results = new ArrayList<>();
        String sql = "SELECT r.nombre, SUM(v.costo_pasaje) FROM viajes v JOIN rutas r ON v.ruta_id = r.id WHERE v.fecha_hora BETWEEN ? AND ? GROUP BY r.nombre ORDER BY SUM(v.costo_pasaje) DESC";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setTimestamp(1, new java.sql.Timestamp(fechaInicio.getTime()));
            ps.setTimestamp(2, new java.sql.Timestamp(fechaFin.getTime()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(new Object[]{rs.getString(1), rs.getBigDecimal(2)});
                }
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return results;
    }

    public List<Object[]> getViajesPorHora(Date fechaInicio, Date fechaFin) {
        List<Object[]> results = new ArrayList<>();
        String sql = "SELECT EXTRACT(hour from v.fecha_hora), COUNT(v.id) FROM viajes v WHERE v.fecha_hora BETWEEN ? AND ? GROUP BY 1 ORDER BY 1";
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setTimestamp(1, new java.sql.Timestamp(fechaInicio.getTime()));
            ps.setTimestamp(2, new java.sql.Timestamp(fechaFin.getTime()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(new Object[]{rs.getInt(1), rs.getLong(2)});
                }
            }
        } catch (SQLException e) { throw new RuntimeException(e); }
        return results;
    }
}
EOF

log "[M6] Creando AnaliticaService.java (MODIFICADO para pasar los filtros)"
cat > "$BASE_PACKAGE_PATH/reportes/service/AnaliticaService.java" << 'EOF'
package com.simu.reportes.service;
import com.simu.reportes.dao.ReporteDAO;
import com.simu.reportes.dto.IngresosPorRutaDTO;
import com.simu.reportes.dto.PasajerosHoraPicoDTO;
import javax.ejb.Stateless;
import javax.inject.Inject;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Stateless
public class AnaliticaService {
    @Inject private ReporteDAO reporteDAO;
    
    public long getTotalPasajeros() { return reporteDAO.countPasajeros(); }
    
    public long getTotalViajes(Date fechaInicio, Date fechaFin) { 
        return reporteDAO.countTotalViajes(fechaInicio, fechaFin); 
    }
    
    public List<IngresosPorRutaDTO> getIngresosTotalesPorRuta(Date fechaInicio, Date fechaFin) {
        return reporteDAO.getIngresosPorRuta(fechaInicio, fechaFin).stream()
                .map(result -> new IngresosPorRutaDTO((String) result[0], (BigDecimal) result[1]))
                .collect(Collectors.toList());
    }
    
    public List<PasajerosHoraPicoDTO> getDistribucionViajesPorHora(Date fechaInicio, Date fechaFin) {
        return reporteDAO.getViajesPorHora(fechaInicio, fechaFin).stream()
                .map(result -> new PasajerosHoraPicoDTO(((Number) result[0]).intValue(), (Long) result[1]))
                .collect(Collectors.toList());
    }
}
EOF

log "[M6] Creando DashboardBean.java (REDISEÑADO para manejar filtros y datos para exportar)"
cat > "$BASE_PACKAGE_PATH/reportes/bean/DashboardBean.java" << 'EOF'
package com.simu.reportes.bean;

import com.simu.reportes.dto.IngresosPorRutaDTO;
import com.simu.reportes.dto.PasajerosHoraPicoDTO;
import com.simu.reportes.service.AnaliticaService;
import org.primefaces.model.charts.ChartData;
import org.primefaces.model.charts.axes.cartesian.CartesianScales;
import org.primefaces.model.charts.axes.cartesian.linear.CartesianLinearAxes;
import org.primefaces.model.charts.axes.cartesian.linear.CartesianLinearTicks;
import org.primefaces.model.charts.bar.BarChartDataSet;
import org.primefaces.model.charts.bar.BarChartModel;
import org.primefaces.model.charts.bar.BarChartOptions;
import org.primefaces.model.charts.line.LineChartDataSet;
import org.primefaces.model.charts.line.LineChartModel;
import org.primefaces.model.charts.line.LineChartOptions;
import org.primefaces.model.charts.optionconfig.title.Title;

import javax.annotation.PostConstruct;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Named @ViewScoped
public class DashboardBean implements Serializable {
    private static final long serialVersionUID = 1L;
    @Inject private AnaliticaService analiticaService;
    
    // Atributos para los filtros
    private Date fechaInicio;
    private Date fechaFin;
    
    // Atributos para las estadísticas
    private long totalPasajeros;
    private long totalViajes;

    // Atributos para las listas de datos (para tablas de exportación)
    private List<IngresosPorRutaDTO> ingresosPorRuta;
    private List<PasajerosHoraPicoDTO> viajesPorHora;
    
    // Modelos de gráficos
    private BarChartModel barModel;
    private LineChartModel lineModel;

    @PostConstruct
    public void init() {
        totalPasajeros = analiticaService.getTotalPasajeros();
        
        // Inicializar fechas al mes actual por defecto
        Calendar cal = Calendar.getInstance();
        cal.set(Calendar.DAY_OF_MONTH, 1);
        cal.set(Calendar.HOUR_OF_DAY, 0);
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        fechaInicio = cal.getTime();
        
        cal.setTime(new Date()); // Hoy
        cal.set(Calendar.HOUR_OF_DAY, 23);
        cal.set(Calendar.MINUTE, 59);
        cal.set(Calendar.SECOND, 59);
        fechaFin = cal.getTime();
        
        // Cargar datos iniciales con el filtro por defecto
        filtrarReportes();
    }
    
    // Acción que se llama desde el botón "Aplicar Filtros"
    public void filtrarReportes() {
        totalViajes = analiticaService.getTotalViajes(fechaInicio, fechaFin);
        ingresosPorRuta = analiticaService.getIngresosTotalesPorRuta(fechaInicio, fechaFin);
        viajesPorHora = analiticaService.getDistribucionViajesPorHora(fechaInicio, fechaFin);
        createBarModel();
        createLineModel();
    }

    private void createBarModel() {
        barModel = new BarChartModel();
        ChartData data = new ChartData();
        BarChartDataSet barDataSet = new BarChartDataSet();
        barDataSet.setLabel("Ingresos ($)");
        barDataSet.setData(ingresosPorRuta.stream().map(IngresosPorRutaDTO::getTotalIngresos).collect(Collectors.toList()));
        
        data.addChartDataSet(barDataSet);
        data.setLabels(ingresosPorRuta.stream().map(IngresosPorRutaDTO::getNombreRuta).collect(Collectors.toList()));
        barModel.setData(data);
        
        // Opciones del gráfico
        BarChartOptions options = new BarChartOptions();
        Title title = new Title();
        title.setDisplay(true);
        title.setText("Ingresos por Ruta");
        options.setTitle(title);
        barModel.setOptions(options);
    }

    private void createLineModel() {
        lineModel = new LineChartModel();
        ChartData data = new ChartData();
        LineChartDataSet dataSet = new LineChartDataSet();
        dataSet.setData(viajesPorHora.stream().map(PasajerosHoraPicoDTO::getNumeroDeViajes).collect(Collectors.toList()));
        dataSet.setLabel("Número de Viajes");
        dataSet.setBorderColor("rgb(255, 99, 132)");
        
        data.addChartDataSet(dataSet);
        data.setLabels(viajesPorHora.stream().map(dto -> dto.getHora() + ":00").collect(Collectors.toList()));
        lineModel.setData(data);

        // Opciones del gráfico
        LineChartOptions options = new LineChartOptions();
        Title title = new Title();
        title.setDisplay(true);
        title.setText("Distribución de Viajes por Hora");
        options.setTitle(title);
        lineModel.setOptions(options);
    }

    // --- GETTERS Y SETTERS ---
    public Date getFechaInicio() { return fechaInicio; }
    public void setFechaInicio(Date fechaInicio) { this.fechaInicio = fechaInicio; }
    public Date getFechaFin() { return fechaFin; }
    public void setFechaFin(Date fechaFin) { this.fechaFin = fechaFin; }
    public long getTotalPasajeros() { return totalPasajeros; }
    public long getTotalViajes() { return totalViajes; }
    public BarChartModel getBarModel() { return barModel; }
    public LineChartModel getLineModel() { return lineModel; }
    public List<IngresosPorRutaDTO> getIngresosPorRuta() { return ingresosPorRuta; }
    public List<PasajerosHoraPicoDTO> getViajesPorHora() { return viajesPorHora; }
}
EOF

log "Módulo 6 (Reportes) completado y mejorado al 100%."