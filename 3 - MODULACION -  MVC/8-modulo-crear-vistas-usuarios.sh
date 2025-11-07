#!/bin/bash
# 8-crear-vistas-usuarios.sh
# Crea/actualiza las vistas XHTML para el Módulo 1.

set -euo pipefail
header() { echo -e "\n\033[0;36m--- $1 ---\033[0m"; }
log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
PROJECT_ENV_FILE="$HOME/.project-env"; source "$PROJECT_ENV_FILE"
cd "$PROJECT_DIR" || exit 1
WEBAPP_PATH="src/main/webapp"

header "Creando Vistas del Módulo de Usuarios"

log "Creando template.xhtml (base)..."
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
    <style type="text/css">
        html, body { height: 100%; margin: 0; padding: 0; font-family: Arial, sans-serif; font-size: 14px; }
        .main-container { display: flex; flex-direction: column; height: 100vh; }
        .header { flex-shrink: 0; height: 60px; background-color: #f5f5f5; border-bottom: 1px solid #ddd; display: flex; align-items: center; padding: 0 20px; box-sizing: border-box; }
        .header h2 { margin: 0; flex-grow: 1; }
        .body-container { display: flex; flex-grow: 1; overflow: hidden; }
        .sidebar { flex-shrink: 0; width: 250px; background-color: #fafafa; border-right: 1px solid #ddd; padding: 15px; box-sizing: border-box; overflow-y: auto; }
        .content { flex-grow: 1; padding: 20px; overflow-y: auto; }
    </style>
</h:head>

<h:body>
    <div class="main-container">
        <div class="header">
            <h2>Sistema de Transporte Urbano</h2>
            <h:form rendered="#{sessionBean.isLoggedIn()}">
                 <p:outputLabel value="Bienvenido, #{sessionBean.usuarioLogueado.nombreCompleto}" style="margin-right:20px; vertical-align: middle;"/>
                 <p:commandButton value="Cerrar Sesión" action="#{loginBean.cerrarSesion}" icon="pi pi-sign-out" styleClass="ui-button-warning"/>
            </h:form>
        </div>
        <div class="body-container">
            <div class="sidebar">
                <h:form rendered="#{sessionBean.isLoggedIn()}">
                    <h3>Menú</h3>
                     <p:menu>
                        <p:menuitem value="Dashboard" outcome="/pasajero/dashboard.xhtml" icon="pi pi-home" rendered="#{sessionBean.isPasajero()}"/>
                        <p:menuitem value="Mi Billetera" outcome="/pasajero/billetera.xhtml" icon="pi pi-wallet" rendered="#{sessionBean.isPasajero()}"/>
                        <p:menuitem value="Planificar Viaje" outcome="/pasajero/planificarViaje.xhtml" icon="pi pi-map-marker" rendered="#{sessionBean.isPasajero()}"/>
                        <p:menuitem value="Mi Historial" outcome="/pasajero/historial.xhtml" icon="pi pi-history" rendered="#{sessionBean.isPasajero()}"/>
                        <p:menuitem value="Dashboard Admin" outcome="/admin/dashboard.xhtml" icon="pi pi-chart-bar" rendered="#{sessionBean.isAdmin()}"/>
                        <p:menuitem value="Gestión Usuarios" outcome="/admin/usuarios/lista.xhtml" icon="pi pi-users" rendered="#{sessionBean.isAdmin()}"/>
                        <p:menuitem value="Gestión Rutas" outcome="/admin/rutas/lista.xhtml" icon="pi pi-sitemap" rendered="#{sessionBean.isAdmin()}"/>
                        <p:menuitem value="Gestión Paradas" outcome="/admin/paradas/lista.xhtml" icon="pi pi-map" rendered="#{sessionBean.isAdmin()}"/>
                        <p:menuitem value="Gestión Flota" outcome="/admin/flota/lista.xhtml" icon="pi pi-truck" rendered="#{sessionBean.isAdmin()}"/>
                    </p:menu>
                </h:form>
            </div>
            <div class="content">
                <p:growl id="messages" showDetail="true" life="4000" />
                <ui:insert name="content"/>
            </div>
        </div>
    </div>
</h:body>
</html>
EOF

log "Creando login.xhtml, registro.xhtml y dashboards..."
cat > "$WEBAPP_PATH/login.xhtml" << 'EOF'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" 
      xmlns:h="http://xmlns.jcp.org/jsf/html" 
      xmlns:p="http://primefaces.org/ui">
<h:head>
    <title>Iniciar Sesión</title>
    <h:outputStylesheet library="css" name="style.css" />
</h:head>
<h:body class="login-body">
    <div class="login-panel-container">
        <p:panel header="Acceso al Sistema">
            <h:form>
                <p:growl id="messages" showDetail="true" />
                <p:panelGrid columns="1" styleClass="ui-noborder">
                    <p:outputLabel for="username" value="Usuario:" />
                    <p:inputText id="username" value="#{loginBean.username}" required="true" label="Usuario" style="width:100%"/>
                    <p:outputLabel for="password" value="Contraseña:" />
                    <p:password id="password" value="#{loginBean.password}" required="true" label="Contraseña" style="width:100%"/>
                    <p:selectBooleanCheckbox id="rememberMe" value="#{loginBean.rememberMe}" itemLabel="Recordar mi usuario"/>
                </p:panelGrid>
                <div style="text-align:center; margin-top:10px;">
                    <p:commandButton value="Iniciar Sesión" action="#{loginBean.iniciarSesion}" ajax="false" icon="pi pi-sign-in"/>
                    <br/><br/>
                    <p:link outcome="/registro" value="¿No tienes cuenta? Regístrate"/>
                </div>
            </h:form>
        </p:panel>
    </div>
</h:body>
</html>
EOF

# --- registro.xhtml CORREGIDO Y LEGIBLE ---
cat > "$WEBAPP_PATH/registro.xhtml" << 'EOF'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" 
      xmlns:h="http://xmlns.jcp.org/jsf/html" 
      xmlns:p="http://primefaces.org/ui">
<h:head>
    <title>Registro de Usuario</title>
    <h:outputStylesheet library="css" name="style.css" />
</h:head>
<h:body class="login-body">
    <div class="login-panel-container">
        <p:panel header="Crear Cuenta de Pasajero">
            <h:form>
                <p:growl id="messages" showDetail="true" life="6000" />
                <p:panelGrid columns="1" styleClass="ui-noborder">
                    <p:outputLabel for="nombre" value="Nombre Completo:"/>
                    <p:inputText id="nombre" value="#{registroBean.nuevoUsuario.nombreCompleto}" required="true" style="width:100%"/>

                    <p:outputLabel for="email" value="Email:"/>
                    <p:inputText id="email" value="#{registroBean.nuevoUsuario.email}" required="true" style="width:100%"/>

                    <p:outputLabel for="username" value="Nombre de Usuario:"/>
                    <p:inputText id="username" value="#{registroBean.nuevoUsuario.username}" required="true" style="width:100%"/>

                    <p:outputLabel for="password" value="Contraseña:"/>
                    <p:password id="password" value="#{registroBean.nuevoUsuario.password}" required="true" match="passwordConfirm" feedback="true" style="width:100%"/>

                    <p:outputLabel for="passwordConfirm" value="Confirmar Contraseña:"/>
                    <p:password id="passwordConfirm" required="true" style="width:100%"/>
                </p:panelGrid>
                <div style="text-align:center; margin-top:10px;">
                    <!-- CORRECCIÓN: Usar AJAX para el envío del formulario -->
                    <p:commandButton value="Registrar" actionListener="#{registroBean.registrar}" process="@form" update="@form messages" icon="pi pi-user-plus"/>
                    <br/><br/>
                    <p:link outcome="/login" value="Volver a Iniciar Sesión"/>
                </div>
            </h:form>
        </p:panel>
    </div>
</h:body>
</html>
EOF

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
    <h:link value="Volver a la página de inicio" outcome="/login.xhtml"/>
</h:body>
</html>
EOF

cat > "$WEBAPP_PATH/admin/dashboard.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" 
    xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:ui="http://xmlns.jcp.org/jsf/facelets"
    xmlns:p="http://primefaces.org/ui">

    <ui:define name="title">Dashboard Administrador</ui:define>
    
    <ui:define name="content">
        <h1>Panel de Administración</h1>
        <p>Bienvenido, #{sessionBean.usuarioLogueado.nombreCompleto}.</p>
    </ui:define>
</ui:composition>
EOF

cat > "$WEBAPP_PATH/pasajero/dashboard.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:h="http://xmlns.jcp.org/jsf/html"
    xmlns:ui="http://xmlns.jcp.org/jsf/facelets">

    <ui:define name="title">Dashboard Pasajero</ui:define>
    
    <ui:define name="content">
        <h1>Portal del Pasajero</h1>
        <p>Bienvenido a tu portal, #{sessionBean.usuarioLogueado.nombreCompleto}.</p>
        
        <h:panelGrid columns="1" style="margin-top:20px;">
            <h:link outcome="/pasajero/billetera.xhtml" value="Ir a Mi Billetera"/>
            <h:link outcome="/pasajero/planificarViaje.xhtml" value="Ir a Planificar Viaje"/>
            <h:link outcome="/pasajero/historial.xhtml" value="Ir a Mi Historial"/>
        </h:panelGrid>

    </ui:define>
</ui:composition>
EOF

log "Creando vista de gestión de usuarios..."
cat > "$WEBAPP_PATH/admin/usuarios/lista.xhtml" << 'EOF'
<ui:composition template="/template.xhtml" 
    xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:h="http://xmlns.jcp.org/jsf/html" 
    xmlns:ui="http://xmlns.jcp.org/jsf/facelets" 
    xmlns:f="http://xmlns.jcp.org/jsf/core" 
    xmlns:p="http://primefaces.org/ui">

    <ui:define name="title">Gestión de Usuarios</ui:define>
    
    <ui:define name="content">
        <h:form id="formPrincipal">
            <p:panel header="Lista de Usuarios">
                <p:dataTable id="tablaUsuarios" var="user" value="#{gestionUsuariosBean.usuarios}" 
                    paginator="true" rows="10" emptyMessage="No se encontraron usuarios.">
                    <p:column headerText="ID" sortBy="#{user.id}" filterBy="#{user.id}" filterMatchMode="contains"> <h:outputText value="#{user.id}" /> </p:column>
                    <p:column headerText="Username" sortBy="#{user.username}" filterBy="#{user.username}" filterMatchMode="contains"> <h:outputText value="#{user.username}" /> </p:column>
                    <p:column headerText="Nombre Completo" sortBy="#{user.nombreCompleto}" filterBy="#{user.nombreCompleto}" filterMatchMode="contains"> <h:outputText value="#{user.nombreCompleto}" /> </p:column>
                    <p:column headerText="Email" sortBy="#{user.email}" filterBy="#{user.email}" filterMatchMode="contains"> <h:outputText value="#{user.email}" /> </p:column>
                    <p:column headerText="Rol" sortBy="#{user.rol.nombre}" filterBy="#{user.rol.nombre}" filterMatchMode="contains"> <h:outputText value="#{user.rol.nombre}" /> </p:column>
                    <p:column headerText="Acciones" style="width:120px; text-align:center;">
                        <p:commandButton icon="pi pi-pencil" title="Editar" actionListener="#{gestionUsuariosBean.editar(user)}" update=":formDialogoUsuario" oncomplete="PF('dialogoUsuarioWV').show()" styleClass="rounded-button ui-button-success"/>
                        <p:commandButton icon="pi pi-trash" title="Eliminar" actionListener="#{gestionUsuariosBean.eliminar(user.id)}" update="tablaUsuarios :messages" styleClass="rounded-button ui-button-danger">
                            <p:confirm header="Confirmación" message="¿Eliminar usuario '#{user.username}'?" icon="pi pi-exclamation-triangle"/>
                        </p:commandButton>
                    </p:column>
                </p:dataTable>
                <p:toolbar>
                    <p:toolbarGroup>
                        <p:commandButton value="Nuevo Usuario" icon="pi pi-plus" actionListener="#{gestionUsuariosBean.nuevo()}" update=":formDialogoUsuario" oncomplete="PF('dialogoUsuarioWV').show(); PrimeFaces.focus('formDialogoUsuario:nombre');"/>
                    </p:toolbarGroup>
                </p:toolbar>
            </p:panel>
        </h:form>
        
        <p:dialog header="Formulario de Usuario" widgetVar="dialogoUsuarioWV" modal="true" resizable="false" width="500" appendTo="@(body)">
            <h:form id="formDialogoUsuario">
                <p:panelGrid columns="2" layout="grid" styleClass="ui-panelgrid-blank">
                    <p:outputLabel for="nombre" value="Nombre Completo:"/><p:inputText id="nombre" value="#{gestionUsuariosBean.usuarioSeleccionado.nombreCompleto}" required="true"/>
                    <p:outputLabel for="email" value="Email:"/><p:inputText id="email" value="#{gestionUsuariosBean.usuarioSeleccionado.email}" required="true"/>
                    <p:outputLabel for="username" value="Username:"/><p:inputText id="username" value="#{gestionUsuariosBean.usuarioSeleccionado.username}" required="true"/>
                    <p:outputLabel for="rol" value="Rol:"/><p:selectOneMenu id="rol" value="#{gestionUsuariosBean.rolIdSeleccionado}" required="true"><f:selectItem itemLabel="Seleccione un rol" itemValue="#{null}" noSelectionOption="true"/><f:selectItems value="#{gestionUsuariosBean.rolesDisponibles}" var="rol" itemLabel="#{rol.nombre}" itemValue="#{rol.id}"/></p:selectOneMenu>
                    <p:outputLabel for="password" value="Nueva Contraseña (opcional):"/><p:password id="password" value="#{gestionUsuariosBean.newPassword}"/>
                </p:panelGrid>
                <p:commandButton value="Guardar" actionListener="#{gestionUsuariosBean.guardar}" update=":formPrincipal:tablaUsuarios :messages" oncomplete="if (!args.validationFailed) { PF('dialogoUsuarioWV').hide(); }"/>
            </h:form>
        </p:dialog>
        
        <p:confirmDialog global="true"><p:commandButton value="Sí" type="button" styleClass="ui-confirmdialog-yes" icon="pi pi-check"/><p:commandButton value="No" type="button" styleClass="ui-confirmdialog-no ui-button-secondary" icon="pi pi-times"/></p:confirmDialog>
    </ui:define>
</ui:composition>
EOF
log "Vistas del Módulo 1 creadas."