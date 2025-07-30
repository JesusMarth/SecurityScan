#!/bin/bash

# =============================================================================
# Quick Test Script - Verificación rápida del entorno
# DevSecOps Environment Test
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
# FUNCIONES DE TEST
# =============================================================================

test_docker() {
    log_info "🔍 Probando Docker..."
    
    if command -v docker &> /dev/null; then
        if docker --version > /dev/null 2>&1; then
            log_success "✅ Docker está funcionando"
            docker --version
            return 0
        else
            log_error "❌ Docker no está funcionando correctamente"
            return 1
        fi
    else
        log_error "❌ Docker no está instalado"
        return 1
    fi
}

test_docker_compose() {
    log_info "🔍 Probando Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        if docker-compose --version > /dev/null 2>&1; then
            log_success "✅ Docker Compose está funcionando"
            docker-compose --version
            return 0
        else
            log_error "❌ Docker Compose no está funcionando correctamente"
            return 1
        fi
    else
        log_error "❌ Docker Compose no está instalado"
        return 1
    fi
}

test_zap() {
    log_info "🔍 Probando OWASP ZAP..."
    
    if command -v zap.sh &> /dev/null; then
        if zap.sh -version > /dev/null 2>&1; then
            log_success "✅ OWASP ZAP está funcionando"
            zap.sh -version | head -1
            return 0
        else
            log_error "❌ OWASP ZAP no está funcionando correctamente"
            return 1
        fi
    else
        log_error "❌ OWASP ZAP no está instalado"
        return 1
    fi
}

test_juice_shop() {
    log_info "🔍 Probando OWASP Juice Shop..."
    
    # Verificar si el contenedor está corriendo
    if docker ps | grep -q "juice-shop-vulnerable-app"; then
        log_success "✅ Juice Shop está ejecutándose"
        return 0
    else
        log_warning "⚠️  Juice Shop no está ejecutándose"
        log_info "Para iniciarlo: docker-compose up -d"
        return 1
    fi
}

test_ports() {
    log_info "🔍 Verificando puertos..."
    
    # Verificar puerto 3000
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_success "✅ Puerto 3000 está en uso"
        return 0
    else
        log_warning "⚠️  Puerto 3000 no está en uso"
        return 1
    fi
}

test_curl() {
    log_info "🔍 Probando curl..."
    
    if command -v curl &> /dev/null; then
        log_success "✅ curl está disponible"
        return 0
    else
        log_error "❌ curl no está instalado"
        return 1
    fi
}

test_jq() {
    log_info "🔍 Probando jq..."
    
    if command -v jq &> /dev/null; then
        log_success "✅ jq está disponible"
        return 0
    else
        log_error "❌ jq no está instalado"
        return 1
    fi
}

test_network() {
    log_info "🔍 Probando conectividad de red..."
    
    if curl -s --connect-timeout 5 http://localhost:3000 > /dev/null 2>&1; then
        log_success "✅ Juice Shop es accesible en http://localhost:3000"
        return 0
    else
        log_warning "⚠️  Juice Shop no es accesible en http://localhost:3000"
        return 1
    fi
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    log_info "=== PRUEBA RÁPIDA DEL ENTORNO DE ESCANEO DE SEGURIDAD ==="
    log_info "Fecha: $(date)"
    
    local tests_passed=0
    local tests_total=0
    
    # Ejecutar tests
    test_docker && ((tests_passed++))
    ((tests_total++))
    
    test_docker_compose && ((tests_passed++))
    ((tests_total++))
    
    test_zap && ((tests_passed++))
    ((tests_total++))
    
    test_curl && ((tests_passed++))
    ((tests_total++))
    
    test_jq && ((tests_passed++))
    ((tests_total++))
    
    test_ports && ((tests_passed++))
    ((tests_total++))
    
    test_juice_shop && ((tests_passed++))
    ((tests_total++))
    
    test_network && ((tests_passed++))
    ((tests_total++))
    
    # Mostrar resumen
    log_info ""
    log_info "=== RESUMEN DE PRUEBAS ==="
    log_info "Pruebas pasadas: $tests_passed/$tests_total"
    
    if [ $tests_passed -eq $tests_total ]; then
        log_success "🎉 ¡Todas las pruebas pasaron! El entorno está listo."
        log_info ""
        log_info "Para ejecutar el escaneo completo:"
        log_info "  ./scripts/security_scan.sh"
    else
        log_warning "⚠️  Algunas pruebas fallaron. Revisa los errores arriba."
        log_info ""
        log_info "Para configurar el entorno:"
        log_info "  ./scripts/setup.sh"
    fi
    
    log_info ""
    log_info "Para más información, consulta el README.md"
}

# Ejecutar función principal
main "$@" 