# Script de Configuración - Configuración inicial del proyecto de escaneo de seguridad

Write-Host "=== CONFIGURACIÓN DEL ESCÁNER DE SEGURIDAD ===" -ForegroundColor Blue
Write-Host "Sistema operativo: $($env:OS)" -ForegroundColor Green
Write-Host "PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Verificar Docker
Write-Host "`n[INFO] Verificando Docker..." -ForegroundColor Blue

try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "[SUCCESS] Docker ya está instalado: $dockerVersion" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Docker no está instalado" -ForegroundColor Yellow
        Write-Host "[INFO] Por favor descarga e instala Docker Desktop desde: https://www.docker.com/products/docker-desktop" -ForegroundColor Blue
        Start-Process "https://www.docker.com/products/docker-desktop"
    }
} catch {
    Write-Host "[ERROR] Error verificando Docker" -ForegroundColor Red
}

# Verificar Docker Compose
Write-Host "`n[INFO] Verificando Docker Compose..." -ForegroundColor Blue

try {
    $composeVersion = docker-compose --version 2>$null
    if ($composeVersion) {
        Write-Host "[SUCCESS] Docker Compose ya está instalado: $composeVersion" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Docker Compose no está instalado" -ForegroundColor Yellow
        Write-Host "[INFO] Docker Compose viene incluido con Docker Desktop" -ForegroundColor Blue
    }
} catch {
    Write-Host "[ERROR] Error verificando Docker Compose" -ForegroundColor Red
}

# Verificar OWASP ZAP
Write-Host "`n[INFO] Verificando OWASP ZAP..." -ForegroundColor Blue

try {
    $zapVersion = zap.sh -version 2>$null
    if ($zapVersion) {
        Write-Host "[SUCCESS] OWASP ZAP ya está instalado: $zapVersion" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] OWASP ZAP no está instalado" -ForegroundColor Yellow
        Write-Host "[INFO] Por favor descarga ZAP desde: https://www.zaproxy.org/download/" -ForegroundColor Blue
        Start-Process "https://www.zaproxy.org/download/"
    }
} catch {
    Write-Host "[ERROR] Error verificando OWASP ZAP" -ForegroundColor Red
}

# Verificar jq
Write-Host "`n[INFO] Verificando jq..." -ForegroundColor Blue

try {
    $jqVersion = jq --version 2>$null
    if ($jqVersion) {
        Write-Host "[SUCCESS] jq ya está instalado: $jqVersion" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] jq no está instalado" -ForegroundColor Yellow
        Write-Host "[INFO] Por favor descarga jq desde: https://stedolan.github.io/jq/download/" -ForegroundColor Blue
        Start-Process "https://stedolan.github.io/jq/download/"
    }
} catch {
    Write-Host "[ERROR] Error verificando jq" -ForegroundColor Red
}

# Crear directorios
Write-Host "`n[INFO] Creando estructura de directorios..." -ForegroundColor Blue

$directories = @("reports", "logs")

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "[SUCCESS] Directorio creado: $dir" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Directorio ya existe: $dir" -ForegroundColor Blue
    }
}

# Resumen
Write-Host "`n=== RESUMEN DE CONFIGURACIÓN ===" -ForegroundColor Blue
Write-Host "Para ejecutar el escaneo de seguridad:" -ForegroundColor Green
Write-Host "  .\scripts\security_scan.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para ver la aplicación vulnerable:" -ForegroundColor Green
Write-Host "  docker-compose up -d" -ForegroundColor Yellow
Write-Host "  # Luego abre http://localhost:3000 en tu navegador" -ForegroundColor Gray
Write-Host ""
Write-Host "Para probar el entorno rápidamente:" -ForegroundColor Green
Write-Host "  .\scripts\quick_test.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "=== CONFIGURACIÓN COMPLETADA ===" -ForegroundColor Green 