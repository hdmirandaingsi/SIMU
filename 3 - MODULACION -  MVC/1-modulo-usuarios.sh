#!/bin/bash
# 1-modulo-usuarios.sh
#
# DESCRIPCIÓN:
#   Implementa el Módulo 1: Gestión de Usuarios y Perfiles.
#   Este script llena los archivos vacíos creados por p07-MVC con el código
#   necesario para el registro, login, gestión de perfiles y seguridad básica.
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

# --- 3. IMPLEMENTACIÓN DEL MÓDULO DE USUARIOS ---
header "Implementando Módulo 1: Gestión de Usuarios y Perfiles"

# =================================================================
# CAPA DE ENTIDADES (MODELO)
# =================================================================
log "Creando Entidades JPA: Rol.java y Usuario.java"

# --- Rol.java ---
cat > "$BASE_PACKAGE_PATH/usuarios/entity/Rol.java" << 'EOF'
package com.simu.usuarios.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Objects;
import java.util.List;

@Entity
@Table(name = "roles")
public class Rol implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String nombre; // Ej: "ADMINISTRADOR", "PASAJERO"

    @OneToMany(mappedBy = "rol")
    private List<Usuario> usuarios;

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public List<Usuario> getUsuarios() { return usuarios; }
    public void setUsuarios(List<Usuario> usuarios) { this.usuarios = usuarios; }

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

# --- Usuario.java ---
cat > "$BASE_PACKAGE_PATH/usuarios/entity/Usuario.java" << 'EOF'
package com.simu.usuarios.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Date;
import java.util.Objects;

@Entity
@Table(name = "usuarios")
public class Usuario implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String username;

    @Column(nullable = false)
    private String password; // Almacenará el hash

    @Column(nullable = false, length = 150)
    private String nombreCompleto;

    @Column(nullable = false, unique = true, length = 150)
    private String email;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "fecha_registro", nullable = false)
    private Date fechaRegistro;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "rol_id", nullable = false)
    private Rol rol;

    @PrePersist
    protected void onCreate() {
        fechaRegistro = new Date();
    }

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getNombreCompleto() { return nombreCompleto; }
    public void setNombreCompleto(String nombreCompleto) { this.nombreCompleto = nombreCompleto; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public Date getFechaRegistro() { return fechaRegistro; }
    public void setFechaRegistro(Date fechaRegistro) { this.fechaRegistro = fechaRegistro; }
    public Rol getRol() { return rol; }
    public void setRol(Rol rol) { this.rol = rol; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Usuario usuario = (Usuario) o;
        return Objects.equals(id, usuario.id);
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
log "Creando DAOs: RolDAO.java y UsuarioDAO.java"

# --- RolDAO.java ---
cat > "$BASE_PACKAGE_PATH/usuarios/dao/RolDAO.java" << 'EOF'
package com.simu.usuarios.dao;

import com.simu.usuarios.entity.Rol;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import java.util.List;

@Stateless
public class RolDAO {

    @PersistenceContext(unitName = "transportePU")
    private EntityManager em;

    public Rol findById(Long id) {
        return em.find(Rol.class, id);
    }

    public List<Rol> findAll() {
        return em.createQuery("SELECT r FROM Rol r", Rol.class).getResultList();
    }

    public Rol findByNombre(String nombre) {
        try {
            TypedQuery<Rol> query = em.createQuery("SELECT r FROM Rol r WHERE r.nombre = :nombre", Rol.class);
            query.setParameter("nombre", nombre);
            return query.getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }
    
    public void create(Rol rol) {
        em.persist(rol);
    }
}
EOF

# --- UsuarioDAO.java ---
cat > "$BASE_PACKAGE_PATH/usuarios/dao/UsuarioDAO.java" << 'EOF'
package com.simu.usuarios.dao;

import com.simu.usuarios.entity.Usuario;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.NoResultException;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import java.util.List;

@Stateless
public class UsuarioDAO {

    @PersistenceContext(unitName = "transportePU")
    private EntityManager em;

    public void create(Usuario usuario) {
        em.persist(usuario);
    }

    public Usuario update(Usuario usuario) {
        return em.merge(usuario);
    }

    public void delete(Long id) {
        Usuario usuario = findById(id);
        if (usuario != null) {
            em.remove(usuario);
        }
    }

    public Usuario findById(Long id) {
        return em.find(Usuario.class, id);
    }

    public List<Usuario> findAll() {
        return em.createQuery("SELECT u FROM Usuario u", Usuario.class).getResultList();
    }
    
    public Usuario findByUsername(String username) {
        try {
            TypedQuery<Usuario> query = em.createQuery("SELECT u FROM Usuario u WHERE u.username = :username", Usuario.class);
            query.setParameter("username", username);
            return query.getSingleResult();
        } catch (NoResultException e) {
            return null; // No encontrado
        }
    }
    
    // MÉTODO MEJORADO
    public boolean usernameExists(String username) {
        Long count = em.createQuery("SELECT COUNT(u) FROM Usuario u WHERE u.username = :username", Long.class)
                       .setParameter("username", username)
                       .getSingleResult();
        return count > 0;
    }

    // NUEVO MÉTODO
    public boolean emailExists(String email) {
        Long count = em.createQuery("SELECT COUNT(u) FROM Usuario u WHERE u.email = :email", Long.class)
                       .setParameter("email", email)
                       .getSingleResult();
        return count > 0;
    }
}
EOF

# =================================================================
# CAPA DE SERVICIOS (LÓGICA DE NEGOCIO)
# =================================================================
log "Creando Servicios: UsuarioService.java"

# --- UsuarioService.java ---
cat > "$BASE_PACKAGE_PATH/usuarios/service/UsuarioService.java" << 'EOF'
package com.simu.usuarios.service;

import com.simu.usuarios.dao.RolDAO;
import com.simu.usuarios.dao.UsuarioDAO;
import com.simu.usuarios.entity.Rol;
import com.simu.usuarios.entity.Usuario;
import org.mindrot.jbcrypt.BCrypt;

import javax.ejb.Stateless;
import javax.inject.Inject;

@Stateless
public class UsuarioService {

    @Inject
    private UsuarioDAO usuarioDAO;

    @Inject
    private RolDAO rolDAO;

    public Usuario registrarUsuario(Usuario usuario, String nombreRol) throws Exception {
        // VERIFICACIÓN 1: El nombre de usuario ya existe
        if (usuarioDAO.usernameExists(usuario.getUsername())) {
            throw new Exception("El nombre de usuario ya está en uso. Por favor, elige otro.");
        }

        // VERIFICACIÓN 2: El email ya existe
        if (usuarioDAO.emailExists(usuario.getEmail())) {
            throw new Exception("La dirección de email ya está registrada.");
        }

        Rol rol = rolDAO.findByNombre(nombreRol);
        if (rol == null) {
            throw new Exception("Error interno: el rol de pasajero no está configurado.");
        }
        usuario.setRol(rol);
        
        // Hashear la contraseña antes de guardarla
        String hashedPassword = BCrypt.hashpw(usuario.getPassword(), BCrypt.gensalt());
        usuario.setPassword(hashedPassword);

        usuarioDAO.create(usuario);
        return usuario;
    }

    public Usuario autenticar(String username, String password) {
        Usuario usuario = usuarioDAO.findByUsername(username);
        if (usuario != null && BCrypt.checkpw(password, usuario.getPassword())) {
            return usuario; // Autenticación exitosa
        }
        return null; // Falló la autenticación
    }
}
EOF
 

# =================================================================
# UTILIDADES Y SEGURIDAD
# =================================================================
log "Creando utilidades y filtro de seguridad"

# --- FacesUtil.java ---
cat > "$BASE_PACKAGE_PATH/shared/util/FacesUtil.java" << 'EOF'
package com.simu.shared.util;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

public class FacesUtil {

    public static void addMessage(FacesMessage.Severity severity, String summary, String detail) {
        FacesContext.getCurrentInstance().addMessage(null, new FacesMessage(severity, summary, detail));
    }
    
    public static void addInfoMessage(String summary, String detail) {
        addMessage(FacesMessage.SEVERITY_INFO, summary, detail);
    }

    public static void addErrorMessage(String summary, String detail) {
        addMessage(FacesMessage.SEVERITY_ERROR, summary, detail);
    }
}
EOF

# --- AuthFilter.java ---
# Crea un SessionBean primero para manejar la sesión del usuario.
touch "$BASE_PACKAGE_PATH/usuarios/bean/SessionBean.java"
cat > "$BASE_PACKAGE_PATH/usuarios/bean/SessionBean.java" << 'EOF'
package com.simu.usuarios.bean;

import com.simu.usuarios.entity.Usuario;
import javax.enterprise.context.SessionScoped;
import javax.inject.Named;
import java.io.Serializable;

@Named
@SessionScoped
public class SessionBean implements Serializable {
    private static final long serialVersionUID = 1L;
    
    private Usuario usuarioLogueado;

    public boolean isLoggedIn() {
        return usuarioLogueado != null;
    }
    
    public boolean isAdmin() {
        return isLoggedIn() && "ADMINISTRADOR".equals(usuarioLogueado.getRol().getNombre());
    }
    
    public boolean isPasajero() {
        return isLoggedIn() && "PASAJERO".equals(usuarioLogueado.getRol().getNombre());
    }

    public Usuario getUsuarioLogueado() {
        return usuarioLogueado;
    }

    public void setUsuarioLogueado(Usuario usuarioLogueado) {
        this.usuarioLogueado = usuarioLogueado;
    }
}
EOF

# Ahora el filtro
cat > "$BASE_PACKAGE_PATH/shared/security/AuthFilter.java" << 'EOF'
package com.simu.shared.security;

import com.simu.usuarios.bean.SessionBean;
import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebFilter(filterName = "AuthFilter", urlPatterns = {"/admin/*", "/pasajero/*"})
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        
        SessionBean sessionBean = (SessionBean) req.getSession().getAttribute("sessionBean");

        String reqURI = req.getRequestURI();

        if (sessionBean == null || !sessionBean.isLoggedIn()) {
            res.sendRedirect(req.getContextPath() + "/login.xhtml");
        } else if (reqURI.contains("/admin/") && !sessionBean.isAdmin()) {
            res.sendRedirect(req.getContextPath() + "/accesoDenegado.xhtml");
        } else if (reqURI.contains("/pasajero/") && !sessionBean.isPasajero()) {
            res.sendRedirect(req.getContextPath() + "/accesoDenegado.xhtml");
        } else {
            chain.doFilter(request, response);
        }
    }

    @Override
    public void init(FilterConfig filterConfig) {}

    @Override
    public void destroy() {}
}
EOF

# =================================================================
# CAPA DE PRESENTACIÓN (BEANS Y XHTML)
# =================================================================
log "Creando Managed Beans: LoginBean, RegistroBean, GestionUsuariosBean"

# --- LoginBean.java ---
cat > "$BASE_PACKAGE_PATH/usuarios/bean/LoginBean.java" << 'EOF'
package com.simu.usuarios.bean;

import com.simu.shared.util.FacesUtil;
import com.simu.usuarios.entity.Usuario;
import com.simu.usuarios.service.UsuarioService;
import javax.enterprise.context.RequestScoped;
import javax.faces.context.FacesContext;
import javax.inject.Inject;
import javax.inject.Named;

@Named
@RequestScoped
public class LoginBean {

    @Inject
    private UsuarioService usuarioService;
    
    @Inject
    private SessionBean sessionBean;

    private String username;
    private String password;

    public String iniciarSesion() {
        Usuario usuario = usuarioService.autenticar(username, password);
        if (usuario != null) {
            // 1. Establecer el usuario en el bean de sesión de CDI
            sessionBean.setUsuarioLogueado(usuario);

            // 2. ======== CORRECCIÓN CLAVE ========
            // Poner manualmente el bean de sesión en el HttpSession estándar
            // para que el AuthFilter (que no es de CDI) pueda encontrarlo.
            FacesContext.getCurrentInstance().getExternalContext().getSessionMap().put("sessionBean", sessionBean);
            
            // 3. Redirigir según el rol
            String rol = usuario.getRol().getNombre();
            switch (rol) {
                case "ADMINISTRADOR":
                    return "/admin/dashboard.xhtml?faces-redirect=true";
                case "PASAJERO":
                    return "/pasajero/dashboard.xhtml?faces-redirect=true";
                default:
                    FacesUtil.addErrorMessage("Rol no reconocido", "No hay una página de inicio para tu perfil.");
                    return null;
            }

        } else {
            FacesUtil.addErrorMessage("Error de Autenticación", "Usuario o contraseña incorrectos.");
            return null;
        }
    }
    
    public String cerrarSesion() {
        FacesContext.getCurrentInstance().getExternalContext().invalidateSession();
        return "/login.xhtml?faces-redirect=true";
    }

    // Getters y Setters
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
}
EOF


# --- RegistroBean.java ---
cat > "$BASE_PACKAGE_PATH/usuarios/bean/RegistroBean.java" << 'EOF'
package com.simu.usuarios.bean;

import com.simu.shared.util.FacesUtil;
import com.simu.usuarios.entity.Usuario;
import com.simu.usuarios.service.UsuarioService;
import javax.annotation.PostConstruct;
import javax.enterprise.context.RequestScoped;
import javax.inject.Inject;
import javax.inject.Named;

@Named
@RequestScoped
public class RegistroBean {
    
    @Inject
    private UsuarioService usuarioService;
    
    private Usuario nuevoUsuario;

    @PostConstruct
    public void init() {
        nuevoUsuario = new Usuario();
    }
    
    public String registrar() {
        try {
            // Por defecto, todos los que se registran son pasajeros
            usuarioService.registrarUsuario(nuevoUsuario, "PASAJERO");
            FacesUtil.addInfoMessage("Registro Exitoso", "Ahora puedes iniciar sesión.");
            return "/login?faces-redirect=true";
        } catch (Exception e) {
            // AHORA MOSTRAMOS EL MENSAJE DE LA EXCEPCIÓN ESPECÍFICA
            FacesUtil.addErrorMessage("Error en el Registro", e.getMessage());
            return null;
        }
    }
    
    // Getter y Setter
    public Usuario getNuevoUsuario() { return nuevoUsuario; }
    public void setNuevoUsuario(Usuario nuevoUsuario) { this.nuevoUsuario = nuevoUsuario; }
}
EOF

# --- GestionUsuariosBean.java ---
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

    @Inject
    private UsuarioDAO usuarioDAO;
    @Inject
    private RolDAO rolDAO;

    private List<Usuario> usuarios;
    private Usuario usuarioSeleccionado;
    private List<Rol> rolesDisponibles;
    private Long rolIdSeleccionado;
    private String newPassword;

    @PostConstruct
    public void init() {
        usuarios = usuarioDAO.findAll();
        rolesDisponibles = rolDAO.findAll();
        nuevo();
    }
    
    public void nuevo() {
        usuarioSeleccionado = new Usuario();
        rolIdSeleccionado = null;
        newPassword = null;
    }

    public void guardar() {
        try {
            if (rolIdSeleccionado != null) {
                Rol rol = rolDAO.findById(rolIdSeleccionado);
                usuarioSeleccionado.setRol(rol);
            } else {
                 FacesUtil.addErrorMessage("Error", "Debe seleccionar un rol.");
                 return;
            }

            if (usuarioSeleccionado.getId() == null) { // Creando nuevo usuario
                if (newPassword == null || newPassword.isEmpty()) {
                    FacesUtil.addErrorMessage("Error", "La contraseña es obligatoria para nuevos usuarios.");
                    return;
                }
                String hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
                usuarioSeleccionado.setPassword(hashedPassword);
                usuarioDAO.create(usuarioSeleccionado);
                FacesUtil.addInfoMessage("Éxito", "Usuario creado correctamente.");
            } else { // Actualizando usuario existente
                if (newPassword != null && !newPassword.isEmpty()) {
                    String hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
                    usuarioSeleccionado.setPassword(hashedPassword);
                }
                usuarioDAO.update(usuarioSeleccionado);
                FacesUtil.addInfoMessage("Éxito", "Usuario actualizado correctamente.");
            }
            
            // Recargar lista y limpiar formulario
            usuarios = usuarioDAO.findAll();
            nuevo();
            
        } catch (Exception e) {
            FacesUtil.addErrorMessage("Error al guardar", e.getMessage());
        }
    }
    
    public void editar(Usuario usuario) {
        this.usuarioSeleccionado = usuario;
        this.rolIdSeleccionado = usuario.getRol().getId();
        this.newPassword = null; // Limpiar la contraseña al editar
    }

    public void eliminar(Long id) {
        try {
            usuarioDAO.delete(id);
            usuarios = usuarioDAO.findAll();
            FacesUtil.addInfoMessage("Éxito", "Usuario eliminado.");
        } catch (Exception e) {
            FacesUtil.addErrorMessage("Error al eliminar", e.getMessage());
        }
    }

    // Getters y Setters
    public List<Usuario> getUsuarios() { return usuarios; }
    public void setUsuarios(List<Usuario> usuarios) { this.usuarios = usuarios; }
    public Usuario getUsuarioSeleccionado() { return usuarioSeleccionado; }
    public void setUsuarioSeleccionado(Usuario usuarioSeleccionado) { this.usuarioSeleccionado = usuarioSeleccionado; }
    public List<Rol> getRolesDisponibles() { return rolesDisponibles; }
    public void setRolesDisponibles(List<Rol> rolesDisponibles) { this.rolesDisponibles = rolesDisponibles; }
    public Long getRolIdSeleccionado() { return rolIdSeleccionado; }
    public void setRolIdSeleccionado(Long rolIdSeleccionado) { this.rolIdSeleccionado = rolIdSeleccionado; }
    public String getNewPassword() { return newPassword; }
    public void setNewPassword(String newPassword) { this.newPassword = newPassword; }
}
EOF

log "Creando Vistas XHTML"
# --- template.xhtml (VERSIÓN FINAL CORREGIDA) ---
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



# --- login.xhtml ---
cat > "$WEBAPP_PATH/login.xhtml" << 'EOF'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:p="http://primefaces.org/ui">
<h:head>
    <title>Iniciar Sesión</title>
</h:head>
<h:body>
    <p:growl id="messages" showDetail="true" />
    <div style="width: 300px; margin: 100px auto;">
        <p:panel header="Acceso al Sistema">
            <h:form>
                <p:panelGrid columns="2" styleClass="ui-noborder">
                    <p:outputLabel for="username" value="Usuario:" />
                    <p:inputText id="username" value="#{loginBean.username}" required="true" label="Usuario"/>
                    
                    <p:outputLabel for="password" value="Contraseña:" />
                    <p:password id="password" value="#{loginBean.password}" required="true" label="Contraseña"/>
                </p:panelGrid>
                <p:commandButton value="Iniciar Sesión" action="#{loginBean.iniciarSesion}" update="@form messages"/>
                <p:link outcome="/registro" value="Registrarse" style="margin-left:10px;"/>
            </h:form>
        </p:panel>
    </div>
</h:body>
</html>
EOF

# --- registro.xhtml ---
cat > "$WEBAPP_PATH/registro.xhtml" << 'EOF'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:p="http://primefaces.org/ui">
<h:head>
    <title>Registro de Nuevo Usuario</title>
</h:head>
<h:body>
    <p:growl id="messages" showDetail="true" />
    <div style="width: 400px; margin: 150px auto;">
        <p:panel header="Crear Cuenta de Pasajero">
            <h:form>
                <p:panelGrid columns="2" styleClass="ui-noborder">
                    <p:outputLabel for="nombre" value="Nombre Completo:" />
                    <p:inputText id="nombre" value="#{registroBean.nuevoUsuario.nombreCompleto}" required="true" />

                    <p:outputLabel for="email" value="Email:" />
                    <p:inputText id="email" value="#{registroBean.nuevoUsuario.email}" required="true" />
                    
                    <p:outputLabel for="username" value="Nombre de Usuario:" />
                    <p:inputText id="username" value="#{registroBean.nuevoUsuario.username}" required="true" />
                    
                    <p:outputLabel for="password" value="Contraseña:" />
                    <p:password id="password" value="#{registroBean.nuevoUsuario.password}" required="true" match="passwordConfirm" />

                    <p:outputLabel for="passwordConfirm" value="Confirmar Contraseña:" />
                    <p:password id="passwordConfirm" required="true" />
                </p:panelGrid>
                <p:commandButton value="Registrar" action="#{registroBean.registrar}" update="@form messages"/>
                <p:link outcome="/login" value="Volver al Login" style="margin-left:10px;"/>
            </h:form>
        </p:panel>
    </div>
</h:body>
</html>
EOF

# --- admin/dashboard.xhtml ---
cat > "$WEBAPP_PATH/admin/dashboard.xhtml" << 'EOF'
<ui:composition template="/template.xhtml"
      xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:p="http://primefaces.org/ui">
    <ui:define name="title">Dashboard Administrador</ui:define>
    <ui:define name="content">
        <h1>Panel de Administración</h1>
        <p>Bienvenido, #{sessionBean.usuarioLogueado.nombreCompleto}.</p>
    </ui:define>
</ui:composition>
EOF

# --- pasajero/dashboard.xhtml ---
cat > "$WEBAPP_PATH/pasajero/dashboard.xhtml" << 'EOF'
<ui:composition template="/template.xhtml"
      xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:p="http://primefaces.org/ui">
    <ui:define name="title">Dashboard Pasajero</ui:define>
    <ui:define name="content">
        <h1>Portal del Pasajero</h1>
        <p>Bienvenido a tu portal, #{sessionBean.usuarioLogueado.nombreCompleto}.</p>
    </ui:define>
</ui:composition>
EOF

# --- accesoDenegado.xhtml ---
cat > "$WEBAPP_PATH/accesoDenegado.xhtml" << 'EOF'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html">
<h:head>
    <title>Acceso Denegado</title>
</h:head>
<h:body>
    <h1>Acceso Denegado</h1>
    <p>No tienes permisos para acceder a esta página.</p>
    <h:link value="Volver" outcome="/login.xhtml"/>
</h:body>
</html>
EOF

# --- admin/usuarios/lista.xhtml (CRUD) ---
cat > "$WEBAPP_PATH/admin/usuarios/lista.xhtml" << 'EOF'
<ui:composition template="/template.xhtml"
      xmlns="http://www.w3.org/1999/xhtml"
      xmlns:h="http://xmlns.jcp.org/jsf/html"
      xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
      xmlns:f="http://xmlns.jcp.org/jsf/core"
      xmlns:p="http://primefaces.org/ui">
      
    <ui:define name="title">Gestión de Usuarios</ui:define>
    
    <ui:define name="content">
        <h:form id="formUsuarios">
            <p:panel header="Lista de Usuarios">
                <p:dataTable id="tablaUsuarios" var="user" value="#{gestionUsuariosBean.usuarios}"
                             paginator="true" rows="10">
                    <p:column headerText="ID">
                        <h:outputText value="#{user.id}" />
                    </p:column>
                    <p:column headerText="Username">
                        <h:outputText value="#{user.username}" />
                    </p:column>
                    <p:column headerText="Nombre Completo">
                        <h:outputText value="#{user.nombreCompleto}" />
                    </p:column>
                    <p:column headerText="Email">
                        <h:outputText value="#{user.email}" />
                    </p:column>
                    <p:column headerText="Rol">
                        <h:outputText value="#{user.rol.nombre}" />
                    </p:column>
                    <p:column headerText="Acciones">
                        <p:commandButton icon="pi pi-pencil" title="Editar" 
                                         actionListener="#{gestionUsuariosBean.editar(user)}"
                                         update=":formFormulario"
                                         oncomplete="PF('dialogFormulario').show()"/>
                        <p:commandButton icon="pi pi-trash" title="Eliminar"
                                         actionListener="#{gestionUsuariosBean.eliminar(user.id)}"
                                         update="tablaUsuarios">
                            <p:confirm header="Confirmación" message="¿Seguro que deseas eliminar este usuario?" icon="pi pi-exclamation-triangle"/>
                        </p:commandButton>
                    </p:column>
                </p:dataTable>
                <p:toolbar>
                    <p:toolbarGroup>
                        <p:commandButton value="Nuevo Usuario" icon="pi pi-plus"
                                         actionListener="#{gestionUsuariosBean.nuevo()}"
                                         update=":formFormulario"
                                         oncomplete="PF('dialogFormulario').show()"/>
                    </p:toolbarGroup>
                </p:toolbar>
            </p:panel>
        </h:form>

        <p:dialog header="Formulario de Usuario" widgetVar="dialogFormulario" modal="true" resizable="false">
            <h:form id="formFormulario">
                <p:panelGrid columns="2" styleClass="ui-noborder">
                    <p:outputLabel for="nombre" value="Nombre Completo:"/>
                    <p:inputText id="nombre" value="#{gestionUsuariosBean.usuarioSeleccionado.nombreCompleto}" required="true"/>

                    <p:outputLabel for="email" value="Email:"/>
                    <p:inputText id="email" value="#{gestionUsuariosBean.usuarioSeleccionado.email}" required="true"/>

                    <p:outputLabel for="username" value="Username:"/>
                    <p:inputText id="username" value="#{gestionUsuariosBean.usuarioSeleccionado.username}" required="true"/>
                    
                    <p:outputLabel for="rol" value="Rol:"/>
                    <p:selectOneMenu id="rol" value="#{gestionUsuariosBean.rolIdSeleccionado}" required="true">
                        <f:selectItem itemLabel="Seleccione un rol" itemValue="#{null}" />
                        <f:selectItems value="#{gestionUsuariosBean.rolesDisponibles}" var="rol" itemLabel="#{rol.nombre}" itemValue="#{rol.id}"/>
                    </p:selectOneMenu>

                    <p:outputLabel for="password" value="Nueva Contraseña (opcional):"/>
                    <p:password id="password" value="#{gestionUsuariosBean.newPassword}"/>
                </p:panelGrid>

                <p:commandButton value="Guardar" actionListener="#{gestionUsuariosBean.guardar}" 
                                 update=":formUsuarios:tablaUsuarios :formFormulario"
                                 oncomplete="if (!args.validationFailed) { PF('dialogFormulario').hide(); }"/>
            </h:form>
        </p:dialog>
        
        <p:confirmDialog global="true">
            <p:commandButton value="Sí" type="button" styleClass="ui-confirmdialog-yes" icon="pi pi-check"/>
            <p:commandButton value="No" type="button" styleClass="ui-confirmdialog-no" icon="pi pi-times"/>
        </p:confirmDialog>
    </ui:define>
</ui:composition>
EOF

# =================================================================
# ACTUALIZACIÓN DE ARCHIVOS DE CONFIGURACIÓN
# =================================================================
log "Actualizando archivos de configuración: persistence.xml y faces-config.xml"
# --- persistence.xml (CORREGIDO) ---
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
        <exclude-unlisted-classes>true</exclude-unlisted-classes>
        <properties>
            <property name="javax.persistence.schema-generation.database.action" value="drop-and-create"/>
        </properties>
    </persistence-unit>
</persistence>
EOF


# --- faces-config.xml ---
# Añade reglas de navegación para login Y para las vistas principales (Dashboard)
cat > "$WEBAPP_PATH/WEB-INF/faces-config.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<faces-config
    xmlns="http://xmlns.jcp.org/xml/ns/javaee"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-facesconfig_2_2.xsd"
    version="2.2">
    
    <!-- REGLAS DE NAVEGACIÓN DEL LOGIN -->
    <navigation-rule>
        <from-view-id>/login.xhtml</from-view-id>
        <navigation-case>
            <from-outcome>login_success_admin</from-outcome>
            <to-view-id>/admin/dashboard.xhtml</to-view-id>
            <redirect/>
        </navigation-case>
        <navigation-case>
            <from-outcome>login_success_pasajero</from-outcome>
            <to-view-id>/pasajero/dashboard.xhtml</to-view-id>
            <redirect/>
        </navigation-case>
    </navigation-rule>
    
    <!-- REGLAS DE NAVEGACIÓN DE LOS MENÚES (Para outcome="pasajero/dashboard") -->
    <navigation-rule>
        <from-view-id>*</from-view-id> <!-- Aplica a todas las vistas -->
        <navigation-case>
            <from-outcome>pasajero/dashboard</from-outcome>
            <to-view-id>/pasajero/dashboard.xhtml</to-view-id>
            <redirect/>
        </navigation-case>
        <navigation-case>
            <from-outcome>pasajero/billetera</from-outcome>
            <to-view-id>/pasajero/billetera.xhtml</to-view-id>
            <redirect/>
        </navigation-case>
        <navigation-case>
            <from-outcome>pasajero/planificarViaje</from-outcome>
            <to-view-id>/pasajero/planificarViaje.xhtml</to-view-id>
            <redirect/>
        </navigation-case>
        <navigation-case>
            <from-outcome>pasajero/historial</from-outcome>
            <to-view-id>/pasajero/historial.xhtml</to-view-id>
            <redirect/>
        </navigation-case>

        <!-- Reglas para Admin (usando outcome para consistencia) -->
        <navigation-case>
            <from-outcome>admin/dashboard</from-outcome>
            <to-view-id>/admin/dashboard.xhtml</to-view-id>
            <redirect/>
        </navigation-case>
        <navigation-case>
            <from-outcome>admin/usuarios/lista</from-outcome>
            <to-view-id>/admin/usuarios/lista.xhtml</to-view-id>
            <redirect/>
        </navigation-case>
    </navigation-rule>
</faces-config>
EOF



# --- 4. MENSAJE FINAL ---
echo ""
header "Módulo 1: Gestión de Usuarios - IMPLEMENTACIÓN COMPLETA"
log "Se han creado y poblado todos los archivos necesarios para el Módulo de Usuarios."
warn "Recuerda que necesitarás tener los roles 'ADMINISTRADOR' y 'PASAJERO' en tu base de datos."
warn "El servicio de registro crea 'PASAJERO' si no existe. El rol 'ADMINISTRADOR' debe ser creado manualmente en la BD para el primer acceso."
echo ""
log "Para construir y desplegar los cambios, ejecuta:"
echo -e "   ${YELLOW}cd $PROJECT_DIR && ./deploy.sh${NC}"