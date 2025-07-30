# Script de Prueba Rápida - Verificación del entorno
# Prueba todos los componentes del escáner de seguridad

# Funciones de logging
function Write-LogInfo {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-LogWarning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Funciones de prueba
function Test-Docker {
    Write-LogInfo "🔍 Probando Docker..."
    
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            Write-LogSuccess "✅ Docker está funcionando"
            Write-Host "   $dockerVersion" -ForegroundColor Gray
            return $true
        } else {
            Write-LogError "❌ Docker no está funcionando correctamente"
            return $false
        }
    } catch {
        Write-LogError "❌ Docker no está instalado"
        return $false
    }
}

function Test-DockerCompose {
    Write-LogInfo "🔍 Probando Docker Compose..."
    
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($composeVersion) {
            Write-LogSuccess "✅ Docker Compose está funcionando"
            Write-Host "   $composeVersion" -ForegroundColor Gray
            return $true
        } else {
            Write-LogError "❌ Docker Compose no está funcionando correctamente"
            return $false
        }
    } catch {
        Write-LogError "❌ Docker Compose no está instalado"
        return $false
    }
}

function Test-Zap {
    Write-LogInfo "🔍 Probando OWASP ZAP..."
    
    try {
        $zapVersion = zap.sh -version 2>$null
        if ($zapVersion) {
            Write-LogSuccess "✅ OWASP ZAP está funcionando"
            Write-Host "   $($zapVersion | Select-Object -First 1)" -ForegroundColor Gray
            return $true
        } else {
            Write-LogError "❌ OWASP ZAP no está funcionando correctamente"
            return $false
        }
    } catch {
        Write-LogError "❌ OWASP ZAP no está instalado"
        return $false
    }
}

function Test-JuiceShop {
    Write-LogInfo "🔍 Probando OWASP Juice Shop..."
    
    try {
        $containers = docker ps --format "table {{.Names}}" 2>$null
        if ($containers -match "juice-shop-vulnerable-app") {
            Write-LogSuccess "✅ Juice Shop está ejecutándose"
            return $true
        } else {
            Write-LogWarning "⚠️  Juice Shop no está ejecutándose"
            return $false
        }
    } catch {
        Write-LogError "❌ Error verificando contenedores de Juice Shop"
        return $false
    }
}

function Test-NetworkConnectivity {
    Write-LogInfo "🔍 Probando conectividad de red..."
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-LogSuccess "✅ Juice Shop es accesible en http://localhost:3000"
            return $true
        } else {
            Write-LogWarning "⚠️  Juice Shop respondió con estado: $($response.StatusCode)"
            return $false
        }
    } catch {
        Write-LogWarning "⚠️  Juice Shop no es accesible en http://localhost:3000"
        return $false
    }
}

function Test-ZapConnectivity {
    Write-LogInfo "🔍 Probando conectividad de ZAP..."
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-LogSuccess "✅ ZAP es accesible en http://localhost:8080"
            return $true
        } else {
            Write-LogWarning "⚠️  ZAP respondió con estado: $($response.StatusCode)"
            return $false
        }
    } catch {
        Write-LogWarning "⚠️  ZAP no es accesible en http://localhost:8080"
        return $false
    }
}

function Test-Directories {
    Write-LogInfo "🔍 Probando estructura de directorios..."
    
    $directories = @("reports", "logs")
    $allExist = $true
    
    foreach ($dir in $directories) {
        if (Test-Path $dir) {
            Write-LogSuccess "✅ Directorio existe: $dir"
        } else {
            Write-LogWarning "⚠️  Directorio faltante: $dir"
            $allExist = $false
        }
    }
    
    return $allExist
}

function Test-Permissions {
    Write-LogInfo "🔍 Probando permisos de archivos..."
    
    try {
        $testFile = "logs/test-permissions.log"
        Add-Content -Path $testFile -Value "Test" -ErrorAction Stop
        Remove-Item -Path $testFile -ErrorAction Stop
        Write-LogSuccess "✅ Permisos de archivos correctos"
        return $true
    } catch {
        Write-LogError "❌ Problemas de permisos de archivos detectados"
        return $false
    }
}

# Función principal de prueba
function Start-QuickTest {
    Write-Host "=== PRUEBA RÁPIDA DEL ENTORNO ===" -ForegroundColor Blue
    Write-Host "Probando todos los componentes del escáner de seguridad..." -ForegroundColor Green
    
    $results = @{}
    
    # Ejecutar todas las pruebas
    $results["Docker"] = Test-Docker
    $results["DockerCompose"] = Test-DockerCompose
    $results["ZAP"] = Test-Zap
    $results["JuiceShop"] = Test-JuiceShop
    $results["NetworkConnectivity"] = Test-NetworkConnectivity
    $results["ZapConnectivity"] = Test-ZapConnectivity
    $results["Directories"] = Test-Directories
    $results["Permissions"] = Test-Permissions
    
    # Resumen
    Write-Host "`n=== RESUMEN DE PRUEBAS ===" -ForegroundColor Blue
    
    $passed = 0
    $total = $results.Count
    
    foreach ($test in $results.GetEnumerator()) {
        if ($test.Value) {
            Write-Host "✅ $($test.Key): PASÓ" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "❌ $($test.Key): FALLÓ" -ForegroundColor Red
        }
    }
    
    Write-Host "`nResultados: $passed/$total pruebas pasaron" -ForegroundColor Yellow
    
    if ($passed -eq $total) {
        Write-Host "🎉 ¡Todas las pruebas pasaron! Tu entorno está listo para el escaneo de seguridad." -ForegroundColor Green
        Write-Host "Ahora puedes ejecutar: .\scripts\security_scan.ps1" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️  Algunas pruebas fallaron. Por favor revisa los problemas arriba." -ForegroundColor Yellow
        Write-Host "Ejecuta .\scripts\setup.ps1 para configurar componentes faltantes." -ForegroundColor Blue
    }
}

# Ejecutar la prueba
Start-QuickTest 