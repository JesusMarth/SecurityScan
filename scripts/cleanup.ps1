# Script de Limpieza - Eliminar archivos temporales y reportes antiguos

Write-Host "=== SCRIPT DE LIMPIEZA ===" -ForegroundColor Blue
Write-Host "Eliminando archivos temporales y reportes antiguos..." -ForegroundColor Green

# Obtener directorio del script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ReportsDir = Join-Path $ProjectRoot "reports"
$LogsDir = Join-Path $ProjectRoot "logs"

# Eliminar reportes antiguos
if (Test-Path $ReportsDir) {
    $reports = Get-ChildItem -Path $ReportsDir -File
    if ($reports.Count -gt 0) {
        Write-Host "Eliminando reportes antiguos..." -ForegroundColor Yellow
        Remove-Item -Path "$ReportsDir\*" -Force
        Write-Host "✅ Reportes antiguos eliminados" -ForegroundColor Green
    } else {
        Write-Host "No hay reportes para eliminar" -ForegroundColor Blue
    }
}

# Eliminar logs antiguos
if (Test-Path $LogsDir) {
    $logs = Get-ChildItem -Path $LogsDir -File
    if ($logs.Count -gt 0) {
        Write-Host "Eliminando logs antiguos..." -ForegroundColor Yellow
        Remove-Item -Path "$LogsDir\*" -Force
        Write-Host "✅ Logs antiguos eliminados" -ForegroundColor Green
    } else {
        Write-Host "No hay logs para eliminar" -ForegroundColor Blue
    }
}

# Detener contenedores en ejecución
Write-Host "Deteniendo contenedores Docker..." -ForegroundColor Yellow
try {
    docker-compose down 2>$null
    Write-Host "✅ Contenedores Docker detenidos" -ForegroundColor Green
} catch {
    Write-Host "No hay contenedores ejecutándose" -ForegroundColor Blue
}

# Detener ZAP si está ejecutándose
$zapProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "java" }
if ($zapProcess) {
    Write-Host "Deteniendo ZAP..." -ForegroundColor Yellow
    Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue
    Write-Host "✅ ZAP detenido" -ForegroundColor Green
}

Write-Host "`n=== LIMPIEZA COMPLETADA ===" -ForegroundColor Green
Write-Host "¡Tu proyecto está limpio y listo para un escaneo fresco!" -ForegroundColor Blue 