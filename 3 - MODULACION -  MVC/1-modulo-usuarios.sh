#!/bin/bash
# 1-modulo-usuarios.sh (VERSIÓN JDBC - COMPLETA Y CORREGIDA)
#
# Propósito:
# Implementa el Módulo 1: Gestión de Usuarios, Roles, Autenticación y Sesiones.
# Esta es la base fundamental para el resto de la aplicación.
#
# Mejoras incluidas:
# - Uso correcto de Scopes de Bean (ej: @ViewScoped para formularios).
# - Manejo robusto de errores con bloques try-catch en los Beans.
# - Implementación completa de la seguridad con un Filtro de Autenticación.
# - Código comentado para mayor claridad.

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
header "Implementando Módulo 1: Gestión de Usuarios (Versión Mejorada)"

# =================================================================
# 1. ENTIDADES (MODELO DE DATOS)
# =================================================================
log "[M1] Creando Entidades (POJOs): Rol.java, Usuario.java"

cat > "$BASE_PACKAGE_PATH/usuarios/entity/Rol.java" << 'EOF'
package com.simu.usuarios.entity;

import java.io.Serializable;
import java.util.Objects;

/**
 * Representa un rol de usuario en el sistema (ej. ADMINISTRADOR, PASAJERO).
 */
public class Rol implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long id;
    private String nombre;

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Rol rol = (Rol) o;
        return Objects.equals(id, rol.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
EOF

cat > "$BASE_PACKAGE_PATH/usuarios/entity/Usuario.java" << 'EOF'
package com.simu.usuarios.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * Representa un usuario del sistema.
 */
public class Usuario implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long id;
    private String username;
    private String password;
    private String nombreCompleto;
    private String email;
    private Date fechaRegistro;
    private Rol rol;

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String u) { this.username = u; }
    public String getPassword() { return password; }
    public void setPassword(String p) { this.password = p; }
    public String getNombreCompleto() { return nombreCompleto; }
    public void setNombreCompleto(String n) { this.nombreCompleto = n; }
    public String getEmail() { return email; }
    public void setEmail(String e) { this.email = e; }
    public Date getFechaRegistro() { return fechaRegistro; }
    public void setFechaRegistro(Date d) { this.fechaRegistro = d; }
    public Rol getRol() { return rol; }
    public void setRol(Rol r) { this.rol = r; }
}
EOF

# =================================================================
# 2. CAPA DE ACCESO A DATOS (DAOs)
# =================================================================
log "[M1] Creando DAOs (JDBC): RolDAO.java, UsuarioDAO.java"

cat > "$BASE_PACKAGE_PATH/usuarios/dao/RolDAO.java" << 'EOF'
package com.simu.usuarios.dao;

import com.simu.usuarios.entity.Rol;
import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Stateless
public class RolDAO {
    @Resource(lookup = "jdbc/miDB")
    private DataSource dataSource;

    private Rol mapRow(ResultSet rs) throws SQLException {
        Rol rol = new Rol();
        rol.setId(rs.getLong("id"));
        rol.setNombre(rs.getString("nombre"));
        return rol;
    }

    public List<Rol> findAll() {
        List<Rol> roles = new ArrayList<>();
        String sql = "SELECT * FROM roles ORDER BY nombre";
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                roles.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar roles", e);
        }
        return roles;
    }

    public Rol findById(Long id) {
        String sql = "SELECT * FROM roles WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar rol por ID", e);
        }
        return null;
    }
}
EOF

cat > "$BASE_PACKAGE_PATH/usuarios/dao/UsuarioDAO.java" << 'EOF'
package com.simu.usuarios.dao;

import com.simu.usuarios.entity.Rol;
import com.simu.usuarios.entity.Usuario;
import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Stateless
public class UsuarioDAO {
    @Resource(lookup = "jdbc/miDB")
    private DataSource dataSource;

    @Inject
    private RolDAO rolDAO;

    private Usuario mapRow(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
        u.setId(rs.getLong("id"));
        u.setUsername(rs.getString("username"));
        u.setPassword(rs.getString("password"));
        u.setNombreCompleto(rs.getString("nombre_completo"));
        u.setEmail(rs.getString("email"));
        u.setFechaRegistro(rs.getTimestamp("fecha_registro"));
        Rol rol = rolDAO.findById(rs.getLong("rol_id"));
        u.setRol(rol);
        return u;
    }
    
    public void create(Usuario u) {
        String sql = "INSERT INTO usuarios (username, password, nombre_completo, email, rol_id, fecha_registro) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, u.getUsername());
            ps.setString(2, u.getPassword());
            ps.setString(3, u.getNombreCompleto());
            ps.setString(4, u.getEmail());
            ps.setLong(5, u.getRol().getId());
            ps.setTimestamp(6, new Timestamp(new java.util.Date().getTime()));
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Error al crear usuario", e);
        }
    }

    public Usuario update(Usuario u) {
        String sql;
        boolean updatePassword = u.getPassword() != null && !u.getPassword().isEmpty();
        
        if (updatePassword) {
            sql = "UPDATE usuarios SET username = ?, nombre_completo = ?, email = ?, rol_id = ?, password = ? WHERE id = ?";
        } else {
            sql = "UPDATE usuarios SET username = ?, nombre_completo = ?, email = ?, rol_id = ? WHERE id = ?";
        }
        
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, u.getUsername());
            ps.setString(2, u.getNombreCompleto());
            ps.setString(3, u.getEmail());
            ps.setLong(4, u.getRol().getId());
            if (updatePassword) {
                ps.setString(5, u.getPassword());
                ps.setLong(6, u.getId());
            } else {
                ps.setLong(5, u.getId());
            }
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Error al actualizar usuario", e);
        }
        return u;
    }

    public void delete(Long id) {
        // Primero eliminar registros dependientes en 'tarjetas' para evitar error de FK
        try (Connection conn = dataSource.getConnection();
             PreparedStatement psTarjetas = conn.prepareStatement("DELETE FROM tarjetas WHERE usuario_id = ?")) {
            psTarjetas.setLong(1, id);
            psTarjetas.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Error al eliminar tarjeta asociada al usuario", e);
        }
        
        String sql = "DELETE FROM usuarios WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Error al eliminar usuario", e);
        }
    }
    
    public Usuario findById(Long id) {
        String sql = "SELECT * FROM usuarios WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar usuario por ID", e);
        }
        return null;
    }

    public Usuario findByUsername(String username) {
        String sql = "SELECT * FROM usuarios WHERE username = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar usuario por username", e);
        }
        return null;
    }

    public List<Usuario> findAll() {
        List<Usuario> usuarios = new ArrayList<>();
        String sql = "SELECT * FROM usuarios ORDER BY nombre_completo";
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                usuarios.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar todos los usuarios", e);
        }
        return usuarios;
    }
}
EOF

# =================================================================
# 3. CAPA DE LÓGICA DE NEGOCIO (SERVICIO)
# =================================================================
log "[M1] Creando Servicio de Negocio: UsuarioService.java"

cat > "$BASE_PACKAGE_PATH/usuarios/service/UsuarioService.java" << 'EOF'
package com.simu.usuarios.service;

import com.simu.usuarios.dao.UsuarioDAO;
import com.simu.usuarios.entity.Usuario;
import org.mindrot.jbcrypt.BCrypt;
import javax.ejb.Stateless;
import javax.inject.Inject;

@Stateless
public class UsuarioService {

    @Inject
    private UsuarioDAO usuarioDAO;

    /**
     * Autentica un usuario verificando su username y contraseña.
     * @param username El nombre de usuario.
     * @param password La contraseña en texto plano.
     * @return El objeto Usuario si la autenticación es exitosa, de lo contrario null.
     */
    public Usuario autenticar(String username, String password) {
        Usuario usuario = usuarioDAO.findByUsername(username);
        if (usuario != null && BCrypt.checkpw(password, usuario.getPassword())) {
            return usuario;
        }
        return null;
    }

    /**
     * Registra un nuevo usuario en el sistema.
     * Se encarga de hashear la contraseña antes de guardarla.
     * @param usuario El objeto Usuario con los datos, incluyendo la contraseña en texto plano.
     */
    public void registrarUsuario(Usuario usuario) {
        // Hashear la contraseña antes de persistirla
        String hashedPassword = BCrypt.hashpw(usuario.getPassword(), BCrypt.gensalt());
        usuario.setPassword(hashedPassword);
        usuarioDAO.create(usuario);
    }
}
EOF

# =================================================================
# 4. CAPA DE PRESENTACIÓN (BEANS)
# =================================================================
log "[M1] Creando Managed Beans (CDI): SessionBean, LoginBean, RegistroBean, GestionUsuariosBean"

cat > "$BASE_PACKAGE_PATH/usuarios/bean/SessionBean.java" << 'EOF'
package com.simu.usuarios.bean;

import com.simu.usuarios.entity.Usuario;
import javax.enterprise.context.SessionScoped;
import javax.inject.Named;
import java.io.Serializable;

/**
 * Bean de Sesión: Mantiene la información del usuario logueado
 * durante toda su sesión de navegación. Es el pilar de la seguridad.
 */
@Named
@SessionScoped
public class SessionBean implements Serializable {
    private static final long serialVersionUID = 1L;
    private Usuario usuarioLogueado;

    public void login(Usuario usuario) { this.usuarioLogueado = usuario; }
    public void logout() { this.usuarioLogueado = null; }

    public boolean isLoggedIn() { return usuarioLogueado != null; }
    public boolean isAdmin() { return isLoggedIn() && "ADMINISTRADOR".equals(usuarioLogueado.getRol().getNombre()); }
    public boolean isPasajero() { return isLoggedIn() && "PASAJERO".equals(usuarioLogueado.getRol().getNombre()); }

    public Usuario getUsuarioLogueado() { return usuarioLogueado; }
}
EOF

cat > "$BASE_PACKAGE_PATH/usuarios/bean/LoginBean.java" << 'EOF'
package com.simu.usuarios.bean;

import com.simu.shared.util.FacesUtil;
import com.simu.usuarios.entity.Usuario;
import com.simu.usuarios.service.UsuarioService;
import javax.annotation.PostConstruct; // <-- AÑADIR IMPORT
import javax.faces.context.FacesContext;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import javax.servlet.http.Cookie; // <-- AÑADIR IMPORT
import javax.servlet.http.HttpServletRequest; // <-- AÑADIR IMPORT
import javax.servlet.http.HttpServletResponse; // <-- AÑADIR IMPORT

@Named
@ViewScoped
public class LoginBean implements Serializable {

    private static final long serialVersionUID = 1L;

    private String username;
    private String password;
    private boolean rememberMe; // <-- AÑADIR PROPIEDAD PARA EL CHECKBOX

    @Inject
    private UsuarioService usuarioService;
    @Inject
    private SessionBean sessionBean;

    // Este método se ejecuta DESPUÉS de que el bean es creado,
    // perfecto para leer cookies al cargar la página.
    @PostConstruct
    public void init() {
        HttpServletRequest request = (HttpServletRequest) FacesContext.getCurrentInstance().getExternalContext().getRequest();
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if ("remembered_user".equals(cookie.getName())) {
                    this.username = cookie.getValue();
                    this.rememberMe = true;
                    break;
                }
            }
        }
    }

    public String iniciarSesion() {
        try {
            String trimmedUsername = (this.username != null) ? this.username.trim() : null;
            Usuario usuario = usuarioService.autenticar(trimmedUsername, this.password);

            if (usuario != null) {
                sessionBean.login(usuario);
                
                // --- LÓGICA PARA MANEJAR LA COOKIE ---
                HttpServletResponse response = (HttpServletResponse) FacesContext.getCurrentInstance().getExternalContext().getResponse();
                if (rememberMe) {
                    // Crear la cookie para recordar al usuario
                    Cookie userCookie = new Cookie("remembered_user", trimmedUsername);
                    // Establecer caducidad (ej. 7 días)
                    userCookie.setMaxAge(7 * 24 * 60 * 60); // en segundos
                    response.addCookie(userCookie);
                } else {
                    // Eliminar la cookie si el usuario desmarca la casilla
                    Cookie userCookie = new Cookie("remembered_user", null);
                    userCookie.setMaxAge(0); // Caducidad 0 para eliminar
                    response.addCookie(userCookie);
                }
                // --- FIN DE LA LÓGICA DE COOKIE ---
                
                if (sessionBean.isAdmin()) {
                    return "/admin/dashboard.xhtml?faces-redirect=true";
                } else {
                    return "/pasajero/dashboard.xhtml?faces-redirect=true";
                }
            } else {
                FacesUtil.addErrorMessage("Acceso Denegado", "Usuario o contraseña incorrectos.");
                return null;
            }
        } catch (Exception e) {
            FacesUtil.addErrorMessage("Error Inesperado", "Ocurrió un error al intentar iniciar sesión.");
            e.printStackTrace();
            return null;
        }
    }

    public String cerrarSesion() {
        FacesContext.getCurrentInstance().getExternalContext().invalidateSession();
        return "/login.xhtml?faces-redirect=true";
    }

    // Getters y Setters
    public String getUsername() { return username; }
    public void setUsername(String u) { this.username = u; }
    public String getPassword() { return password; }
    public void setPassword(String p) { this.password = p; }
    // --- AÑADIR GETTER Y SETTER PARA EL CHECKBOX ---
    public boolean isRememberMe() { return rememberMe; }
    public void setRememberMe(boolean rememberMe) { this.rememberMe = rememberMe; }
}
EOF

cat > "$BASE_PACKAGE_PATH/usuarios/bean/RegistroBean.java" << 'EOF'
package com.simu.usuarios.bean;

import com.simu.shared.util.FacesUtil;
import com.simu.usuarios.dao.RolDAO;
import com.simu.usuarios.entity.Rol;
import com.simu.usuarios.entity.Usuario;
import com.simu.usuarios.service.UsuarioService;
import javax.annotation.PostConstruct;
import javax.faces.context.FacesContext;
import javax.faces.view.ViewScoped; // <-- IMPORT CORRECTO
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable; // <-- IMPORT CORRECTO

@Named
@ViewScoped // <-- ANOTACIÓN CORRECTA
public class RegistroBean implements Serializable { // <-- IMPLEMENTACIÓN CORRECTA

    private static final long serialVersionUID = 1L;

    @Inject
    private UsuarioService usuarioService;
    @Inject
    private RolDAO rolDAO;
    private Usuario nuevoUsuario;

    @PostConstruct
    public void init() {
        nuevoUsuario = new Usuario();
    }

    public String registrar() {
        try {
            Rol rolPasajero = rolDAO.findAll().stream()
                .filter(r -> "PASAJERO".equals(r.getNombre()))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("El rol 'PASAJERO' no se encuentra en la base de datos."));
            
            nuevoUsuario.setRol(rolPasajero);
            usuarioService.registrarUsuario(nuevoUsuario);
            
            FacesContext.getCurrentInstance().getExternalContext().getFlash().setKeepMessages(true);
            FacesUtil.addInfoMessage("¡Registro Exitoso!", "Ahora puedes iniciar sesión con tu nueva cuenta.");
            
            return "/login.xhtml?faces-redirect=true";

        } catch (Exception e) {
            String mensajeError = "Ocurrió un error inesperado durante el registro.";
            Throwable cause = e;
            while(cause.getCause() != null) {
                cause = cause.getCause();
            }
            if (cause.getMessage() != null && cause.getMessage().contains("duplicate key")) {
                mensajeError = "El nombre de usuario o el email ya están en uso.";
            }
            
            FacesUtil.addErrorMessage("Error en el Registro", mensajeError);
            e.printStackTrace();
            return null;
        }
    }

    // Getters y Setters
    public Usuario getNuevoUsuario() { return nuevoUsuario; }
    public void setNuevoUsuario(Usuario u) { this.nuevoUsuario = u; }
}
EOF

cat > "$BASE_PACKAGE_PATH/usuarios/bean/GestionUsuariosBean.java" << 'EOF'
package com.simu.usuarios.bean;

import com.simu.shared.util.FacesUtil;
import com.simu.usuarios.dao.RolDAO;
import com.simu.usuarios.dao.UsuarioDAO;
import com.simu.usuarios.entity.Rol;
import com.simu.usuarios.entity.Usuario;
import org.mindrot.jbcrypt.BCrypt;
import javax.annotation.PostConstruct;
import javax.faces.view.ViewScoped;
import javax.inject.Inject;
import javax.inject.Named;
import java.io.Serializable;
import java.util.List;

@Named
@ViewScoped
public class GestionUsuariosBean implements Serializable {
    private static final long serialVersionUID = 1L;

    @Inject private UsuarioDAO usuarioDAO;
    @Inject private RolDAO rolDAO;
    
    private List<Usuario> usuarios;
    private Usuario usuarioSeleccionado;
    private List<Rol> rolesDisponibles;
    private Long rolIdSeleccionado;
    private String newPassword;

    @PostConstruct
    public void init() {
        recargarLista();
        rolesDisponibles = rolDAO.findAll();
    }
    
    private void recargarLista() {
        usuarios = usuarioDAO.findAll();
    }

    public void nuevo() {
        usuarioSeleccionado = new Usuario();
        rolIdSeleccionado = null;
        newPassword = null;
    }

    public void editar(Usuario u) {
        this.usuarioSeleccionado = u;
        this.rolIdSeleccionado = u.getRol().getId();
        this.newPassword = null;
    }

    public void guardar() {
        try {
            usuarioSeleccionado.setRol(rolDAO.findById(rolIdSeleccionado));
            
            // Solo actualiza la contraseña si se ingresó una nueva
            if (newPassword != null && !newPassword.trim().isEmpty()) {
                usuarioSeleccionado.setPassword(BCrypt.hashpw(newPassword, BCrypt.gensalt()));
            } else {
                // Si es un usuario nuevo, la contraseña es obligatoria.
                if (usuarioSeleccionado.getId() == null) {
                    FacesUtil.addErrorMessage("Error de Validación", "La contraseña es obligatoria para nuevos usuarios.");
                    return;
                }
                // Si es edición, no la cambiamos
                usuarioSeleccionado.setPassword(null); 
            }
            
            if (usuarioSeleccionado.getId() == null) {
                usuarioDAO.create(usuarioSeleccionado);
                FacesUtil.addInfoMessage("Éxito", "Usuario creado correctamente.");
            } else {
                usuarioDAO.update(usuarioSeleccionado);
                FacesUtil.addInfoMessage("Éxito", "Usuario actualizado correctamente.");
            }
            recargarLista();
            nuevo(); // Limpiar el formulario
        } catch (Exception e) {
            String mensajeError = "El username o email ya existen.";
            FacesUtil.addErrorMessage("Error al Guardar", mensajeError);
            e.printStackTrace();
        }
    }

    public void eliminar(Long id) {
        try {
            usuarioDAO.delete(id);
            FacesUtil.addInfoMessage("Éxito", "Usuario eliminado.");
            recargarLista();
        } catch (Exception e) {
            FacesUtil.addErrorMessage("Error al Eliminar", "No se pudo eliminar el usuario.");
            e.printStackTrace();
        }
    }
    
    // Getters y Setters
    public List<Usuario> getUsuarios() { return usuarios; }
    public Usuario getUsuarioSeleccionado() { return usuarioSeleccionado; }
    public void setUsuarioSeleccionado(Usuario u) { this.usuarioSeleccionado = u; }
    public List<Rol> getRolesDisponibles() { return rolesDisponibles; }
    public Long getRolIdSeleccionado() { return rolIdSeleccionado; }
    public void setRolIdSeleccionado(Long id) { this.rolIdSeleccionado = id; }
    public String getNewPassword() { return newPassword; }
    public void setNewPassword(String p) { this.newPassword = p; }
}
EOF

# =================================================================
# 5. UTILIDADES COMPARTIDAS Y SEGURIDAD
# =================================================================
log "[M1] Creando Filtro de Seguridad y Clases de Utilidad"

cat > "$BASE_PACKAGE_PATH/shared/util/FacesUtil.java" << 'EOF'
package com.simu.shared.util;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

/**
 * Clase de utilidad para simplificar el envío de mensajes a la interfaz de JSF.
 */
public class FacesUtil {
    public static void addInfoMessage(String summary, String detail) {
        FacesContext.getCurrentInstance().addMessage(null, 
            new FacesMessage(FacesMessage.SEVERITY_INFO, summary, detail));
    }

    public static void addErrorMessage(String summary, String detail) {
        FacesContext.getCurrentInstance().addMessage(null, 
            new FacesMessage(FacesMessage.SEVERITY_ERROR, summary, detail));
    }
}
EOF

cat > "$BASE_PACKAGE_PATH/shared/security/AuthFilter.java" << 'EOF'
package com.simu.shared.security;

import com.simu.usuarios.bean.SessionBean;
import javax.inject.Inject;
import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Filtro de seguridad que protege las URLs.
 * Redirige al login si no hay sesión, o a 'acceso denegado' si el rol no es correcto.
 */
public class AuthFilter implements Filter {
    @Inject
    private SessionBean sessionBean;

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        String requestURI = request.getRequestURI();

        // --- INICIO DEL CÓDIGO AÑADIDO ---
        // Obtenemos la IP del cliente.
        String clientIp = request.getRemoteAddr();
        // --- FIN DEL CÓDIGO AÑADIDO ---


        // Si el SessionBean no se ha inyectado o no hay usuario, redirigir al login
        if (sessionBean == null || !sessionBean.isLoggedIn()) {
            // Imprimimos el intento de acceso SIN sesión
            System.out.println("Intento de acceso NO AUTORIZADO a: " + requestURI + " desde la IP: " + clientIp);
            response.sendRedirect(request.getContextPath() + "/login.xhtml");
            return;
        }

        // --- CÓDIGO AÑADIDO PARA LOGGING ---
        // Si el usuario ya está logueado, registramos su actividad
        System.out.println("Acceso AUTORIZADO para usuario: '" + sessionBean.getUsuarioLogueado().getUsername() + "' a la URL: " + requestURI + " desde la IP: " + clientIp);
        // --- FIN DEL CÓDIGO AÑADIDO ---


        // Reglas de protección por rol
        if (requestURI.startsWith(request.getContextPath() + "/admin/") && !sessionBean.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/accesoDenegado.xhtml");
            return;
        }

        if (requestURI.startsWith(request.getContextPath() + "/pasajero/") && !sessionBean.isPasajero()) {
            response.sendRedirect(request.getContextPath() + "/accesoDenegado.xhtml");
            return;
        }

        // Si pasa todas las validaciones, continuar con la petición
        chain.doFilter(req, res);
    }

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // No se necesita inicialización especial
    }

    @Override
    public void destroy() {
        // No se necesita limpieza especial
    }
}
EOF

log "Módulo 1 (Usuarios) implementado al 100% con todas las mejoras."