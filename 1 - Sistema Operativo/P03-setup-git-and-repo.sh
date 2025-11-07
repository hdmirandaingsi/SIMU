#!/bin/bash

# === CONFIGURACIÓN ===
EMAIL="hdmirandaingelec15@gmail.com"
GITHUB_USER="Hdmiranda15"
REPO_NAME="jdk8-gf-psql"
REPO_URL="git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
PROJECT_DIR="$HOME/${REPO_NAME}"
LOG_FILE="$HOME/setup-git-repo.log"

# Función de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Iniciando configuración automática de Git y repositorio ==="

# 1. Instalar git si no está presente
if ! command -v git &> /dev/null; then
    log "Git no encontrado. Instalando..."
    sudo apt update && sudo apt install -y git
else
    log "Git ya está instalado."
fi

# 2. Configurar Git globalmente (solo si no está configurado)
if ! git config --global user.email &> /dev/null || [ "$(git config --global user.email)" != "$EMAIL" ]; then
    log "Configurando Git global..."
    git config --global user.name "Hdmiranda15"
    git config --global user.email "$EMAIL"
fi

# 3. Verificar o generar clave SSH
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    log "Generando nueva clave SSH ed25519..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""
else
    log "Clave SSH ya existe en $SSH_KEY"
fi

# 4. Iniciar el agente SSH y añadir la clave
log "Iniciando agente SSH y añadiendo clave..."
eval "$(ssh-agent -s)" > /dev/null
ssh-add "$SSH_KEY" 2>/dev/null

# 5. Asegurar permisos de .ssh
chmod 700 "$HOME/.ssh"
chmod 600 "$SSH_KEY"
chmod 644 "${SSH_KEY}.pub"

# 6. Clonar o actualizar repositorio
if [ -d "$PROJECT_DIR/.git" ]; then
    log "Repositorio ya existe. Actualizando..."
    cd "$PROJECT_DIR" || { log "Error: No se pudo entrar al directorio."; exit 1; }
    git pull origin main 2>&1 | tee -a "$LOG_FILE"
else
    log "Clonando repositorio: $REPO_URL"
    git clone "$REPO_URL" "$PROJECT_DIR" 2>&1 | tee -a "$LOG_FILE"
fi

# 7. Mostrar clave pública para que la copies a GitHub
log "=== CONFIGURACIÓN COMPLETADA ==="
log "👉 COPIA LA SIGUIENTE CLAVE PÚBLICA Y AGREGA EN:"
log "   https://github.com/settings/keys"
echo ""
cat "${SSH_KEY}.pub"
echo ""
log "Después de agregarla en GitHub, prueba con: ssh -T git@github.com"
log "Log guardado en: $LOG_FILE"