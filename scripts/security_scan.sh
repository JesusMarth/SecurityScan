#!/bin/bash

# =============================================================================
# OWASP ZAP Security Scanner - Automated Vulnerability Assessment
# DevSecOps Script for OWASP Juice Shop Application
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# =============================================================================
# CONFIGURACIÓN Y VARIABLES
# =============================================================================

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuración de la aplicación
readonly APP_URL="http://localhost:3000"
readonly APP_NAME="OWASP Juice Shop"
readonly CONTAINER_NAME="juice-shop-vulnerable-app"

# Configuración de ZAP
readonly ZAP_HOST="localhost"
readonly ZAP_PORT="8080"
readonly ZAP_API_URL="http://${ZAP_HOST}:${ZAP_PORT}"
readonly ZAP_API_KEY=""

# Directorios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly REPORTS_DIR="${PROJECT_ROOT}/reports"
readonly LOGS_DIR="${PROJECT_ROOT}/logs"

# Archivos de salida
readonly ZAP_REPORT_HTML="${REPORTS_DIR}/zap-report.html"
readonly ZAP_REPORT_JSON="${REPORTS_DIR}/zap-report.json"
readonly ZAP_REPORT_XML="${REPORTS_DIR}/zap-report.xml"
readonly SCAN_LOG="${LOGS_DIR}/security-scan.log"

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$SCAN_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$SCAN_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$SCAN_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$SCAN_LOG"
}

# =============================================================================
# FUNCIONES DE VERIFICACIÓN
# =============================================================================

check_dependencies() {
    log_info "Verificando dependencias..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está instalado. Por favor instálalo primero."
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose no está instalado. Por favor instálalo primero."
        exit 1
    fi
    
    # Verificar curl
    if ! command -v curl &> /dev/null; then
        log_error "curl no está instalado. Por favor instálalo primero."
        exit 1
    fi
    
    log_success "Todas las dependencias están instaladas"
}

check_ports() {
    log_info "Verificando disponibilidad de puertos..."
    
    # Verificar puerto 3000
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "Puerto 3000 ya está en uso. Verificando si es Juice Shop..."
        if curl -s "$APP_URL" > /dev/null 2>&1; then
            log_info "Juice Shop ya está ejecutándose en puerto 3000"
            return 0
        else
            log_error "Puerto 3000 está ocupado por otra aplicación"
            exit 1
        fi
    fi
    
    log_success "Puertos disponibles"
}

# =============================================================================
# FUNCIONES DE DOCKER
# =============================================================================

start_juice_shop() {
    log_info "Iniciando $APP_NAME con Docker Compose..."
    
    cd "$PROJECT_ROOT"
    
    # Detener contenedores existentes si los hay
    if docker-compose ps | grep -q "$CONTAINER_NAME"; then
        log_info "Deteniendo contenedores existentes..."
        docker-compose down
    fi
    
    # Levantar la aplicación
    if docker-compose up -d; then
        log_success "$APP_NAME iniciado correctamente"
    else
        log_error "Error al iniciar $APP_NAME"
        exit 1
    fi
}

wait_for_app_ready() {
    log_info "Esperando a que $APP_NAME esté listo..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$APP_URL" > /dev/null 2>&1; then
            log_success "$APP_NAME está accesible en $APP_URL"
            return 0
        fi
        
        log_info "Intento $attempt/$max_attempts - Esperando 10 segundos..."
        sleep 10
        ((attempt++))
    done
    
    log_error "Timeout: $APP_NAME no está accesible después de $((max_attempts * 10)) segundos"
    exit 1
}

# =============================================================================
# FUNCIONES DE ZAP
# =============================================================================

start_zap() {
    log_info "Iniciando OWASP ZAP en modo headless..."
    
    # Detener ZAP si ya está ejecutándose
    if lsof -Pi :$ZAP_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_info "Deteniendo ZAP existente..."
        pkill -f "zap.sh" || true
        sleep 5
    fi
    
    # Iniciar ZAP en modo daemon
    nohup zap.sh -daemon -host $ZAP_HOST -port $ZAP_PORT -config api.key=$ZAP_API_KEY > "${LOGS_DIR}/zap.log" 2>&1 &
    local zap_pid=$!
    
    # Esperar a que ZAP esté listo
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$ZAP_API_URL" > /dev/null 2>&1; then
            log_success "OWASP ZAP iniciado correctamente en $ZAP_API_URL"
            return 0
        fi
        
        log_info "Esperando a que ZAP esté listo... (intento $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    log_error "Timeout: ZAP no está accesible"
    exit 1
}

run_zap_scan() {
    log_info "Ejecutando escaneo de seguridad con OWASP ZAP..."
    
    # Crear directorio de reportes si no existe
    mkdir -p "$REPORTS_DIR"
    
    # Ejecutar baseline scan
    if zap-baseline.py -t "$APP_URL" -J "$ZAP_REPORT_JSON" -r "$ZAP_REPORT_HTML" -x "$ZAP_REPORT_XML" --auto; then
        log_success "Escaneo completado exitosamente"
        
        # Mostrar resumen de vulnerabilidades
        if [ -f "$ZAP_REPORT_JSON" ]; then
            local high_count=$(jq '.site[] | .alerts[] | select(.risk == "High") | .name' "$ZAP_REPORT_JSON" 2>/dev/null | wc -l)
            local medium_count=$(jq '.site[] | .alerts[] | select(.risk == "Medium") | .name' "$ZAP_REPORT_JSON" 2>/dev/null | wc -l)
            local low_count=$(jq '.site[] | .alerts[] | select(.risk == "Low") | .name' "$ZAP_REPORT_JSON" 2>/dev/null | wc -l)
            
            log_info "Resumen de vulnerabilidades encontradas:"
            log_info "  - Críticas: $high_count"
            log_info "  - Medias: $medium_count"
            log_info "  - Bajas: $low_count"
        fi
    else
        log_error "Error durante el escaneo de seguridad"
        exit 1
    fi
}

# =============================================================================
# FUNCIONES DE LIMPIEZA
# =============================================================================

cleanup() {
    log_info "Realizando limpieza..."
    
    # Detener ZAP
    pkill -f "zap.sh" || true
    
    # Opcional: detener contenedores (comentado para mantener la app corriendo)
    # docker-compose down
    
    log_success "Limpieza completada"
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    log_info "=== INICIANDO ESCANEO DE SEGURIDAD AUTOMATIZADO ==="
    log_info "Fecha: $(date)"
    log_info "Aplicación objetivo: $APP_NAME"
    log_info "URL: $APP_URL"
    
    # Crear directorios necesarios
    mkdir -p "$REPORTS_DIR" "$LOGS_DIR"
    
    # Ejecutar pasos del escaneo
    check_dependencies
    check_ports
    start_juice_shop
    wait_for_app_ready
    start_zap
    run_zap_scan
    
    log_success "=== ESCANEO COMPLETADO EXITOSAMENTE ==="
    log_info "Reporte HTML generado: $ZAP_REPORT_HTML"
    log_info "Reporte JSON generado: $ZAP_REPORT_JSON"
    log_info "Reporte XML generado: $ZAP_REPORT_XML"
    log_info "Log del escaneo: $SCAN_LOG"
    
    # Abrir reporte en navegador (opcional)
    if command -v xdg-open &> /dev/null; then
        xdg-open "$ZAP_REPORT_HTML" &
    elif command -v open &> /dev/null; then
        open "$ZAP_REPORT_HTML" &
    elif command -v start &> /dev/null; then
        start "$ZAP_REPORT_HTML" &
    else
        log_info "Para ver el reporte, abre manualmente: $ZAP_REPORT_HTML"
    fi
}

# =============================================================================
# MANEJO DE SEÑALES Y EJECUCIÓN
# =============================================================================

# Capturar señales para limpieza
trap cleanup EXIT
trap 'log_error "Script interrumpido por el usuario"; exit 1' INT TERM

# Ejecutar función principal
main "$@" 