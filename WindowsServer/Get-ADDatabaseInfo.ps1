<#
.SYNOPSIS
    Script para consultar ubicacion de base de datos y logs de Active Directory
.DESCRIPTION
    Este script muestra la ubicacion del archivo NTDS.dit, sus logs de transacciones,
    y el tamano de la base de datos en diferentes formatos.
.NOTES
    Requiere ejecucion con privilegios de administrador en un Controlador de Dominio
#>

# Configurar codificacion para evitar caracteres especiales
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Función para formatear el tamaño de archivo
function Get-FileSize {
    param([long]$SizeInBytes)
    
    if ($SizeInBytes -eq 0) { return "0 B" }
    
    $sizes = @("B", "KB", "MB", "GB", "TB")
    $index = [Math]::Floor([Math]::Log($SizeInBytes) / [Math]::Log(1024))
    $size = [Math]::Round($SizeInBytes / [Math]::Pow(1024, $index), 2)
    
    return "$size $($sizes[$index])"
}

# Funcion para obtener informacion de un directorio
function Get-DirectoryInfo {
    param([string]$Path)
    
    if (Test-Path $Path) {
        $items = Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue
        $totalSize = ($items | Measure-Object -Property Length -Sum).Sum
        $fileCount = $items.Count
        
        return @{
            Exists = $true
            TotalSize = $totalSize
            FileCount = $fileCount
            Items = $items
        }
    } else {
        return @{
            Exists = $false
            TotalSize = 0
            FileCount = 0
            Items = $null
        }
    }
}

# Limpiar la pantalla
Clear-Host

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ACTIVE DIRECTORY INFORMATION" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si estamos en un Controlador de Dominio
try {
    $isDC = Get-ADDomain -ErrorAction Stop
    Write-Host "[OK] Domain Controller detected" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Not a Domain Controller" -ForegroundColor Red
    Write-Host "Some paths may not exist or permissions may be limited" -ForegroundColor Yellow
    Write-Host ""
}

# 1. OBTENER UBICACION DE LA BASE DE DATOS (NTDS.dit)
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "DATABASE LOCATION" -ForegroundColor Magenta
Write-Host "------------------------------------------------" -ForegroundColor Cyan

try {
    # Obtener ruta del registro
    $dbPath = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "DSA Database file" -ErrorAction Stop).'DSA Database file'
    
    Write-Host "File path: $dbPath" -ForegroundColor White
    
    # Verificar si el archivo existe
    if (Test-Path $dbPath) {
        $dbFile = Get-Item -Path $dbPath
        $fileSizeBytes = $dbFile.Length
        $fileSizeFormatted = Get-FileSize -SizeInBytes $fileSizeBytes
        $lastModified = $dbFile.LastWriteTime
        
        Write-Host "  [OK] File exists" -ForegroundColor Green
        Write-Host "  Size: $fileSizeFormatted" -ForegroundColor Green
        Write-Host "  Last modified: $lastModified" -ForegroundColor Green
        
        # Mostrar en MB y GB para mayor claridad
        $sizeMB = [math]::Round($fileSizeBytes / 1MB, 2)
        $sizeGB = [math]::Round($fileSizeBytes / 1GB, 2)
        Write-Host "  Size in MB: $sizeMB MB" -ForegroundColor Gray
        Write-Host "  Size in GB: $sizeGB GB" -ForegroundColor Gray
        
        # Informacion adicional del archivo
        $attributes = $dbFile.Attributes
        Write-Host "  Attributes: $attributes" -ForegroundColor Gray
    } else {
        Write-Host "  [ERROR] File not found at specified path" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Could not get database path:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 2. OBTENER UBICACION DE LOS LOGS DE TRANSACCIONES
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "TRANSACTION LOGS" -ForegroundColor Magenta
Write-Host "------------------------------------------------" -ForegroundColor Cyan

try {
    # Obtener ruta de los logs de transacciones del registro
    $logsPath = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "DSA Working Directory" -ErrorAction SilentlyContinue).'DSA Working Directory'
    
    if ($logsPath) {
        Write-Host "Logs path: $logsPath" -ForegroundColor White
        
        # Obtener informacion del directorio
        $dirInfo = Get-DirectoryInfo -Path $logsPath
        
        if ($dirInfo.Exists) {
            Write-Host "  [OK] Directory exists" -ForegroundColor Green
            Write-Host "  Log files: $($dirInfo.FileCount)" -ForegroundColor Green
            
            if ($dirInfo.FileCount -gt 0) {
                $totalSizeFormatted = Get-FileSize -SizeInBytes $dirInfo.TotalSize
                Write-Host "  Total log size: $totalSizeFormatted" -ForegroundColor Green
                
                # Mostrar archivos de log mas recientes
                Write-Host ""
                Write-Host "  Main log files:" -ForegroundColor Yellow
                $latestLogs = $dirInfo.Items | Where-Object { $_.Extension -in '.log', '.jfm', '.edb' } | Sort-Object LastWriteTime -Descending | Select-Object -First 5
                
                foreach ($log in $latestLogs) {
                    $logSize = Get-FileSize -SizeInBytes $log.Length
                    Write-Host "    - $($log.Name) - $logSize - Modified: $($log.LastWriteTime)" -ForegroundColor Gray
                }
            } else {
                Write-Host "  No log files found" -ForegroundColor Yellow
            }
            
            # Mostrar estadisticas adicionales
            Write-Host ""
            Write-Host "  Directory statistics:" -ForegroundColor Yellow
            Write-Host "    - Used disk space: $([math]::Round($dirInfo.TotalSize / 1MB, 2)) MB" -ForegroundColor Gray
        } else {
            Write-Host "  [ERROR] Directory not found" -ForegroundColor Red
        }
    } else {
        Write-Host "  Logs path not found in registry" -ForegroundColor Yellow
        Write-Host "  Logs might be in the same directory as the database" -ForegroundColor Gray
    }
} catch {
    Write-Host "[ERROR] Could not get logs path:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 3. INFORMACION DE LOGS DE EVENTOS
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "AD EVENT LOGS" -ForegroundColor Magenta
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# Logs importantes de Active Directory
$adLogs = @(
    "Directory Service",
    "Active Directory Web Services",
    "File Replication Service",
    "DFS Replication"
)

foreach ($logName in $adLogs) {
    try {
        $log = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue
        
        if ($log -and $log.RecordCount -gt 0) {
            $recordCount = $log.RecordCount
            $isEnabled = $log.IsEnabled
            $sizeKB = [math]::Round($log.MaximumKilobytes / 1024, 2)
            
            Write-Host "  $logName" -ForegroundColor Yellow
            Write-Host "    - Records: $recordCount events" -ForegroundColor White
            Write-Host "    - Status: $(if($isEnabled){'Active'}else{'Inactive'})" -ForegroundColor White
            Write-Host "    - Max size: $($log.MaximumKilobytes) KB ($sizeKB MB)" -ForegroundColor White
            Write-Host "    - Last write: $($log.LastWriteTime)" -ForegroundColor White
        } else {
            Write-Host "  $logName - Not available or no events" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  $logName - Error querying" -ForegroundColor Red
    }
}

Write-Host ""

# 4. OTRAS UBICACIONES IMPORTANTES
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "OTHER RELEVANT LOCATIONS" -ForegroundColor Magenta
Write-Host "------------------------------------------------" -ForegroundColor Cyan

$otherPaths = @(
    @{Name = "DCPROMO installation logs"; Path = "$env:systemroot\debug\dcpromo.log"},
    @{Name = "DCPROMO GUI logs"; Path = "$env:systemroot\debug\dcpromoui.log"},
    @{Name = "SYSVOL logs"; Path = "$env:systemroot\SYSVOL\domain\NtFrs_PreExisting___See_EventLog"},
    @{Name = "AD diagnostic logs"; Path = "$env:windir\debug\adsdiag.log"}
)

foreach ($item in $otherPaths) {
    if (Test-Path $item.Path) {
        $file = Get-Item -Path $item.Path
        $size = Get-FileSize -SizeInBytes $file.Length
        Write-Host "  $($item.Name):" -ForegroundColor Green
        Write-Host "    - Path: $($item.Path)" -ForegroundColor White
        Write-Host "    - Size: $size" -ForegroundColor White
        Write-Host "    - Modified: $($file.LastWriteTime)" -ForegroundColor White
    } else {
        Write-Host "  $($item.Name): Not found" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  END OF REPORT" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Preguntar si desea exportar el reporte
Write-Host ""
Write-Host "Do you want to export this report to a text file? (Y/N): " -ForegroundColor Yellow -NoNewline
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    $reportPath = "C:\AD_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    # Recopilar información para el reporte
    $report = @"
========================================
  ACTIVE DIRECTORY REPORT
  Date: $(Get-Date)
  Server: $env:COMPUTERNAME
========================================

"@
    
    # Agregar información de la base de datos
    try {
        $dbPath = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "DSA Database file" -ErrorAction SilentlyContinue).'DSA Database file'
        if ($dbPath -and (Test-Path $dbPath)) {
            $dbFile = Get-Item -Path $dbPath
            $report += "DATABASE:`n"
            $report += "  Path: $dbPath`n"
            $report += "  Size: $(Get-FileSize -SizeInBytes $dbFile.Length)`n"
            $report += "  Last modified: $($dbFile.LastWriteTime)`n`n"
        }
    } catch {}
    
    # Agregar información de logs
    try {
        $logsPath = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "DSA Working Directory" -ErrorAction SilentlyContinue).'DSA Working Directory'
        if ($logsPath -and (Test-Path $logsPath)) {
            $dirInfo = Get-DirectoryInfo -Path $logsPath
            $report += "TRANSACTION LOGS:`n"
            $report += "  Path: $logsPath`n"
            $report += "  Files: $($dirInfo.FileCount)`n"
            $report += "  Total size: $(Get-FileSize -SizeInBytes $dirInfo.TotalSize)`n`n"
        }
    } catch {}
    
    # Guardar reporte
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host ""
    Write-Host "Report saved to: $reportPath" -ForegroundColor Green
}