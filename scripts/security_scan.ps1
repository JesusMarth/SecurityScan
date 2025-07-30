# Escáner de Seguridad con OWASP ZAP
# Automatiza el escaneo de vulnerabilidades en aplicaciones web

param(
    [string]$AppUrl = "http://localhost:3000",
    [string]$AppName = "OWASP Juice Shop",
    [string]$ContainerName = "juice-shop-vulnerable-app",
    [string]$ZapHost = "localhost",
    [int]$ZapPort = 8080,
    [string]$ZapApiKey = ""
)

# Configurar rutas
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ReportsDir = Join-Path $ProjectRoot "reports"
$LogsDir = Join-Path $ProjectRoot "logs"

# Archivos de salida
$ZapReportHtml = Join-Path $ReportsDir "zap-report.html"
$ZapReportJson = Join-Path $ReportsDir "zap-report.json"
$ZapReportXml = Join-Path $ReportsDir "zap-report.xml"
$ScanLog = Join-Path $LogsDir "security-scan.log"

# Funciones de logging
function Write-LogInfo {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[INFO] $Message"
    Write-Host $logMessage -ForegroundColor Blue
    Add-Content -Path $ScanLog -Value "[$timestamp] $logMessage"
}

function Write-LogSuccess {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[SUCCESS] $Message"
    Write-Host $logMessage -ForegroundColor Green
    Add-Content -Path $ScanLog -Value "[$timestamp] $logMessage"
}

function Write-LogWarning {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[WARNING] $Message"
    Write-Host $logMessage -ForegroundColor Yellow
    Add-Content -Path $ScanLog -Value "[$timestamp] $logMessage"
}

function Write-LogError {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[ERROR] $Message"
    Write-Host $logMessage -ForegroundColor Red
    Add-Content -Path $ScanLog -Value "[$timestamp] $logMessage"
}

# Verificar si todas las herramientas requeridas están instaladas
function Test-Dependencies {
    Write-LogInfo "Verificando dependencias..."
    
    # Verificar Docker
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            Write-LogSuccess "Docker está instalado: $dockerVersion"
        } else {
            Write-LogError "Docker no está instalado. Por favor instálalo primero."
            exit 1
        }
    } catch {
        Write-LogError "Docker no está instalado. Por favor instálalo primero."
        exit 1
    }
    
    # Verificar Docker Compose
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($composeVersion) {
            Write-LogSuccess "Docker Compose está instalado: $composeVersion"
        } else {
            Write-LogError "Docker Compose no está instalado. Por favor instálalo primero."
            exit 1
        }
    } catch {
        Write-LogError "Docker Compose no está instalado. Por favor instálalo primero."
        exit 1
    }
    
    # Verificar OWASP ZAP
    try {
        $zapPath = "C:\Program Files\ZAP\Zed Attack Proxy\zap.bat"
        if (Test-Path $zapPath) {
            $zapVersion = & $zapPath -version 2>$null
            if ($zapVersion) {
                Write-LogSuccess "OWASP ZAP está instalado: $zapVersion"
            } else {
                Write-LogError "OWASP ZAP no está funcionando correctamente. Por favor reinstálalo."
                exit 1
            }
        } else {
            Write-LogError "OWASP ZAP no está instalado. Por favor instálalo primero."
            exit 1
        }
    } catch {
        Write-LogError "OWASP ZAP no está instalado. Por favor instálalo primero."
        exit 1
    }
    
    Write-LogSuccess "Todas las dependencias están instaladas"
}

# Verificar si los puertos están disponibles
function Test-Ports {
    Write-LogInfo "Verificando disponibilidad de puertos..."
    
    # Verificar puerto 3000
    $port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
    if ($port3000) {
        Write-LogWarning "Puerto 3000 ya está en uso. Verificando si es Juice Shop..."
        try {
            $response = Invoke-WebRequest -Uri $AppUrl -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-LogInfo "Juice Shop ya está ejecutándose en puerto 3000"
                return $true
            }
        } catch {
            Write-LogError "Puerto 3000 está ocupado por otra aplicación"
            exit 1
        }
    }
    
    Write-LogSuccess "Puertos disponibles"
    return $false
}

# Iniciar la aplicación vulnerable
function Start-JuiceShop {
    Write-LogInfo "Iniciando $AppName con Docker Compose..."
    
    Set-Location $ProjectRoot
    
    # Detener contenedores existentes si los hay
    $runningContainers = docker-compose ps --services --filter "status=running" 2>$null
    if ($runningContainers -and $runningContainers.Contains("juice-shop")) {
        Write-LogInfo "Deteniendo contenedores existentes..."
        docker-compose down
    }
    
    # Iniciar la aplicación
    try {
        docker-compose up -d
        Write-LogSuccess "$AppName iniciado correctamente"
    } catch {
        Write-LogError "Error al iniciar $AppName"
        exit 1
    }
}

# Esperar a que la aplicación esté lista
function Wait-ForAppReady {
    Write-LogInfo "Esperando a que $AppName esté listo..."
    
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri $AppUrl -TimeoutSec 10 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-LogSuccess "$AppName está accesible en $AppUrl"
                return
            }
        } catch {
            # Continuar intentando
        }
        
        Write-LogInfo "Intento $attempt/$maxAttempts - Esperando 10 segundos..."
        Start-Sleep -Seconds 10
        $attempt++
    }
    
    Write-LogError "Timeout: $AppName no está accesible después de $($maxAttempts * 10) segundos"
    exit 1
}

# Iniciar OWASP ZAP
function Start-Zap {
    Write-LogInfo "Iniciando OWASP ZAP en modo headless..."
    
    # Detener ZAP si ya está ejecutándose
    $zapProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "java" }
    if ($zapProcess) {
        Write-LogInfo "Deteniendo ZAP existente..."
        Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    }
    
    # Iniciar ZAP en modo daemon
    $zapLogPath = Join-Path $LogsDir "zap.log"
    $zapErrorLogPath = Join-Path $LogsDir "zap-error.log"
    $zapPath = "C:\Program Files\ZAP\Zed Attack Proxy\zap.bat"
    $zapDir = "C:\Program Files\ZAP\Zed Attack Proxy"
    Start-Process -FilePath $zapPath -ArgumentList "-daemon", "-host", $ZapHost, "-port", $ZapPort, "-config", "api.key=$ZapApiKey" -RedirectStandardOutput $zapLogPath -RedirectStandardError $zapErrorLogPath -WindowStyle Hidden -WorkingDirectory $zapDir
    
    # Esperar a que ZAP esté listo
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://$ZapHost`:$ZapPort" -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-LogSuccess "OWASP ZAP iniciado correctamente en http://$ZapHost`:$ZapPort"
                return
            }
        } catch {
            # Continuar intentando
        }
        
        Write-LogInfo "Esperando a que ZAP esté listo... (intento $attempt/$maxAttempts)"
        Start-Sleep -Seconds 5
        $attempt++
    }
    
    Write-LogError "Timeout: ZAP no está accesible"
    exit 1
}

# Ejecutar el escaneo de seguridad
function Invoke-ZapScan {
    Write-LogInfo "Ejecutando escaneo de seguridad con OWASP ZAP..."
    
    # Crear directorio de reportes si no existe
    if (!(Test-Path $ReportsDir)) {
        New-Item -ItemType Directory -Path $ReportsDir -Force
    }
    
    # Usar la API de ZAP para ejecutar el escaneo
    try {
        $zapApiUrl = "http://$ZapHost`:$ZapPort"
        
        # 1. Acceder a la URL objetivo
        Write-LogInfo "Accediendo a la URL objetivo..."
        $accessUrl = "$zapApiUrl/JSON/core/action/accessUrl/?url=$AppUrl"
        $response = Invoke-RestMethod -Uri $accessUrl -Method GET
        
        # 2. Ejecutar spider scan
        Write-LogInfo "Ejecutando spider scan..."
        $spiderUrl = "$zapApiUrl/JSON/spider/action/scan/?url=$AppUrl"
        $response = Invoke-RestMethod -Uri $spiderUrl -Method GET
        
        # 3. Ejecutar active scan
        Write-LogInfo "Ejecutando active scan..."
        $activeScanUrl = "$zapApiUrl/JSON/ascan/action/scan/?url=$AppUrl"
        $response = Invoke-RestMethod -Uri $activeScanUrl -Method GET
        
        # 4. Generar reporte HTML
        Write-LogInfo "Generando reporte HTML..."
        $reportUrl = "$zapApiUrl/JSON/reports/action/generateReport/?title=Security+Scan+Report&template=traditional-html&theme=classic&descriptionDesc=Security+scan+report&contexts=&sites=&sections=&includedConfidences=&includedRisks=&reportFileName=zap-report.html&reportDir=$ReportsDir"
        $response = Invoke-RestMethod -Uri $reportUrl -Method GET
        
        Write-LogSuccess "Escaneo completado exitosamente"
        Write-LogSuccess "Reporte HTML generado: $ZapReportHtml"
        Write-LogInfo "Puedes abrir el reporte en tu navegador para ver los resultados detallados"
        
    } catch {
        Write-LogError "Error al ejecutar ZAP scan: $($_.Exception.Message)"
        exit 1
    }
}

# Función de limpieza
function Invoke-Cleanup {
    Write-LogInfo "Realizando limpieza..."
    
    # Detener ZAP
    $zapProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "java" }
    if ($zapProcess) {
        Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue
    }
    
    Write-LogSuccess "Limpieza completada"
}

# Función principal
function Start-SecurityScan {
    Write-LogInfo "=== INICIANDO ESCANEO DE SEGURIDAD AUTOMATIZADO ==="
    Write-LogInfo "Fecha: $(Get-Date)"
    Write-LogInfo "Aplicación objetivo: $AppName"
    Write-LogInfo "URL: $AppUrl"
    
    # Crear directorios necesarios
    if (!(Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force }
    if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force }
    
    # Ejecutar pasos del escaneo
    Test-Dependencies
    $isAlreadyRunning = Test-Ports
    
    if (!$isAlreadyRunning) {
        Start-JuiceShop
        Wait-ForAppReady
    }
    
    Start-Zap
    Invoke-ZapScan
    
    Write-LogSuccess "=== ESCANEO COMPLETADO EXITOSAMENTE ==="
    Write-LogInfo "Reporte HTML: $ZapReportHtml"
    Write-LogInfo "Reporte JSON: $ZapReportJson"
    Write-LogInfo "Reporte XML: $ZapReportXml"
    Write-LogInfo "Log del escaneo: $ScanLog"
    
    # Abrir reporte en navegador
    try {
        Start-Process $ZapReportHtml
        Write-LogInfo "Reporte abierto en el navegador"
    } catch {
        Write-LogInfo "Para ver el reporte, abre manualmente: $ZapReportHtml"
    }
}

# Manejar señales para limpieza
trap {
    Write-LogError "Script interrumpido por el usuario"
    Invoke-Cleanup
    exit 1
}

# Ejecutar función principal
try {
    Start-SecurityScan
} finally {
    Invoke-Cleanup
} 