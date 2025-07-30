#!/bin/bash

# =============================================================================
# Setup Script - Configuración inicial del proyecto de escaneo de seguridad
# DevSecOps Environment Setup
# =============================================================================

set -euo pipefail

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# FUNCIONES DE INSTALACIÓN
# =============================================================================

install_docker() {
    log_info "Instalando Docker..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker ya está instalado"
        return 0
    fi
    
    # Detectar sistema operativo
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        log_warning "Para macOS, instala Docker Desktop desde: https://www.docker.com/products/docker-desktop"
        return 1
    else
        log_error "Sistema operativo no soportado"
        return 1
    fi
    
    log_success "Docker instalado correctamente"
}

install_docker_compose() {
    log_info "Instalando Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose ya está instalado"
        return 0
    fi
    
    # Instalar Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker Compose instalado correctamente"
}

install_zap() {
    log_info "Instalando OWASP ZAP..."
    
    if command -v zap.sh &> /dev/null; then
        log_success "OWASP ZAP ya está instalado"
        return 0
    fi
    
    # Detectar sistema operativo
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - Instalar desde repositorio
        sudo apt-get update
        sudo apt-get install -y zaproxy
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - Instalar con Homebrew
        if command -v brew &> /dev/null; then
            brew install zaproxy
        else
            log_warning "Homebrew no está instalado. Instala ZAP manualmente desde: https://www.zaproxy.org/download/"
            return 1
        fi
    else
        log_error "Sistema operativo no soportado"
        return 1
    fi
    
    log_success "OWASP ZAP instalado correctamente"
}

install_jq() {
    log_info "Instalando jq (JSON processor)..."
    
    if command -v jq &> /dev/null; then
        log_success "jq ya está instalado"
        return 0
    fi
    
    # Detectar sistema operativo
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update
        sudo apt-get install -y jq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install jq
        else
            log_warning "Homebrew no está instalado. Instala jq manualmente"
            return 1
        fi
    else
        log_error "Sistema operativo no soportado"
        return 1
    fi
    
    log_success "jq instalado correctamente"
}

# =============================================================================
# FUNCIONES DE CONFIGURACIÓN
# =============================================================================

create_directories() {
    log_info "Creando estructura de directorios..."
    
    mkdir -p reports logs scripts
    
    log_success "Directorios creados correctamente"
}

setup_permissions() {
    log_info "Configurando permisos..."
    
    # Hacer ejecutable el script principal
    chmod +x scripts/security_scan.sh
    
    log_success "Permisos configurados correctamente"
}

test_environment() {
    log_info "Probando el entorno..."
    
    # Verificar Docker
    if docker --version; then
        log_success "Docker funciona correctamente"
    else
        log_error "Docker no funciona correctamente"
        return 1
    fi
    
    # Verificar Docker Compose
    if docker-compose --version; then
        log_success "Docker Compose funciona correctamente"
    else
        log_error "Docker Compose no funciona correctamente"
        return 1
    fi
    
    # Verificar ZAP
    if zap.sh -version; then
        log_success "OWASP ZAP funciona correctamente"
    else
        log_error "OWASP ZAP no funciona correctamente"
        return 1
    fi
    
    log_success "Todas las herramientas funcionan correctamente"
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    log_info "=== CONFIGURACIÓN INICIAL DEL PROYECTO DE ESCANEO DE SEGURIDAD ==="
    
    # Instalar dependencias
    install_docker
    install_docker_compose
    install_zap
    install_jq
    
    # Configurar entorno
    create_directories
    setup_permissions
    
    # Probar entorno
    test_environment
    
    log_success "=== CONFIGURACIÓN COMPLETADA EXITOSAMENTE ==="
    log_info ""
    log_info "Para ejecutar el escaneo de seguridad:"
    log_info "  ./scripts/security_scan.sh"
    log_info ""
    log_info "Para ver la aplicación vulnerable:"
    log_info "  docker-compose up -d"
    log_info "  # Luego abre http://localhost:3000 en tu navegador"
}

# Ejecutar función principal
main "$@" 