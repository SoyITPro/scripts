<#
.SYNOPSIS
    Elimina automáticamente todas las carpetas vacías dentro de una ruta principal.
.DESCRIPTION
    Este script busca recursivamente todas las carpetas vacías (sin archivos ni subcarpetas)
    dentro de la ruta especificada y las elimina permanentemente. Incluye registro de logs,
    confirmación previa y opción de excluir carpetas específicas.
.PARAMETER Path
    Ruta principal donde comenzará la búsqueda de carpetas vacías.
.PARAMETER WhatIf
    Muestra qué carpetas se eliminarían sin ejecutar realmente la acción.
.PARAMETER ExcludeFolders
    Lista de nombres de carpetas que NO deben eliminarse (ej: "Temp,Logs").
.EXAMPLE
    .\Remove-EmptyFolders.ps1 -Path "D:\Carpetas"
.EXAMPLE
    .\Remove-EmptyFolders.ps1 -Path "C:\Users\Public" -WhatIf -ExcludeFolders "System,Backup"
.NOTES
    Autor: SoyITPro
    Fecha: 2026
#>

# ============================================
# PARÁMETROS DEL SCRIPT
# ============================================
param(
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la ruta principal")]
    [string]$Path,
    
    [Parameter(HelpMessage="Modo simulación: muestra qué se eliminaría sin borrar")]
    [switch]$WhatIf,
    
    [Parameter(HelpMessage="Carpetas a excluir separadas por coma (ej: Temp,Logs)")]
    [string]$ExcludeFolders = ""
)

# ============================================
# CONFIGURACIÓN INICIAL
# ============================================
# Crear lista de exclusión
$ExcludeList = $ExcludeFolders -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

# Crear archivo de log
$LogDate = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = "CarpetasEliminadas_$LogDate.log"
$LogPath = Join-Path $env:USERPROFILE "Desktop" $LogFile

# Contadores
$TotalCarpetas = 0
$Eliminadas = 0
$Omitidas = 0
$Errores = 0

# ============================================
# FUNCIONES
# ============================================
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogPath -Value $LogEntry
}

function Test-FolderExcluded {
    param([string]$FolderName)
    foreach ($Exclude in $ExcludeList) {
        if ($FolderName -eq $Exclude) {
            return $true
        }
    }
    return $false
}

# ============================================
# VALIDACIÓN INICIAL
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   ELIMINADOR DE CARPETAS VACÍAS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Log "Iniciando proceso de limpieza en: $Path"

# Verificar que la ruta existe
if (-not (Test-Path $Path)) {
    Write-Log "ERROR: La ruta '$Path' no existe." 
    Write-Host "⚠️  La ruta especificada no existe. Saliendo..." -ForegroundColor Red
    exit 1
}

if ($WhatIf) {
    Write-Host "`n🔍 MODO SIMULACIÓN ACTIVADO - No se eliminarán carpetas" -ForegroundColor Yellow
    Write-Host "   Solo se mostrará lo que se eliminaría`n" -ForegroundColor Yellow
}

if ($ExcludeList.Count -gt 0) {
    Write-Log "Carpetas EXCLUIDAS: $($ExcludeList -join ', ')"
}

# ============================================
# PROCESO PRINCIPAL
# ============================================
Write-Log "Buscando carpetas vacías..."

# Obtener todas las carpetas recursivamente (excluyendo la raíz)
$Carpetas = Get-ChildItem -Path $Path -Recurse -Directory | Where-Object { $_.FullName -ne $Path }

$TotalCarpetas = $Carpetas.Count
Write-Log "Total de carpetas encontradas: $TotalCarpetas"

# ============================================
# ITERAR Y ELIMINAR
# ============================================
foreach ($Carpeta in $Carpetas) {
    # Verificar si la carpeta está en la lista de exclusión
    if (Test-FolderExcluded -FolderName $Carpeta.Name) {
        $Omitidas++
        Write-Log "⏭️  OMITIDA (excluida): $($Carpeta.FullName)"
        continue
    }
    
    # Verificar si la carpeta está vacía
    $Contenido = Get-ChildItem -Path $Carpeta.FullName -Force -ErrorAction SilentlyContinue
    
    if ($Contenido -eq $null -or $Contenido.Count -eq 0) {
        try {
            if ($WhatIf) {
                # Modo simulación
                Write-Host "🔸 [SIMULACIÓN] Se eliminaría: $($Carpeta.FullName)" -ForegroundColor Yellow
                $Eliminadas++
            } else {
                # Eliminar la carpeta vacía
                Remove-Item -Path $Carpeta.FullName -Force -ErrorAction Stop
                Write-Log "✅ ELIMINADA: $($Carpeta.FullName)"
                $Eliminadas++
            }
        }
        catch {
            $Errores++
            Write-Log "❌ ERROR al eliminar $($Carpeta.FullName): $($_.Exception.Message)"
        }
    }
}

# ============================================
# RESUMEN FINAL
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "          RESUMEN DE EJECUCIÓN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📁 Total carpetas analizadas: $TotalCarpetas" -ForegroundColor White
Write-Host "🗑️  Carpetas eliminadas: $Eliminadas" -ForegroundColor Green
Write-Host "⏭️  Carpetas omitidas (excluidas): $Omitidas" -ForegroundColor Yellow
Write-Host "❌ Errores encontrados: $Errores" -ForegroundColor Red

if ($WhatIf) {
    Write-Host "`n⚠️  MODO SIMULACIÓN: Ninguna carpeta fue eliminada realmente." -ForegroundColor Yellow
    Write-Host "   Ejecuta sin el parámetro -WhatIf para eliminar realmente." -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Proceso completado." -ForegroundColor Green
    Write-Log "Proceso finalizado. $Eliminadas carpetas eliminadas."
}

Write-Host "`n📄 Log guardado en: $LogPath" -ForegroundColor Cyan

# Pausa opcional para ver resultados
if ($host.Name -notlike "*ISE*") {
    Write-Host "`nPresiona cualquier tecla para salir..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
