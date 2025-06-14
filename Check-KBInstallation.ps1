<#
.SYNOPSIS
    Verifica si los servidores listados tienen instalada una actualización específica por su KB ID.
.DESCRIPTION
    Este script lee una lista de servidores desde un archivo .txt y verifica si cada uno tiene instalada
    la actualización de Windows especificada por su ID de Knowledge Base (KB).
.PARAMETER ServersFile
    Ruta del archivo .txt que contiene la lista de servidores (uno por línea).
.PARAMETER KBID
    ID de la actualización a verificar (ejemplo: "KB5005565").
.EXAMPLE
    .\Check-KBInstallation.ps1 -ServersFile "C:\servers.txt" -KBID "
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$ServersFile,
    
    [Parameter(Mandatory=$true)]
    [string]$KBID
)

# Limpiar el KBID por si acaso viene con formato diferente (ej: KB5005565 o 5005565)
$KBID = $KBID -replace "KB", ""  # Elimina "KB" si está presente
$KBID = $KBID.Trim()            # Elimina espacios en blanco

# Verificar si el archivo de servidores existe
if (-not (Test-Path -Path $ServersFile)) {
    Write-Host "Error: El archivo $ServersFile no existe." -ForegroundColor Red
    exit 1
}

# Leer la lista de servidores
try {
    $servers = Get-Content -Path $ServersFile | Where-Object { $_ -ne "" }
}
catch {
    Write-Host "Error al leer el archivo $ServersFile : $_" -ForegroundColor Red
    exit 1
}

if ($servers.Count -eq 0) {
    Write-Host "El archivo $ServersFile no contiene servidores válidos." -ForegroundColor Yellow
    exit 0
}

# Resultados
$results = @()

Write-Host "Verificando la actualizacion KB$KBID en $($servers.Count) servidores..." -ForegroundColor Cyan

foreach ($server in $servers) {
    try {
        # Verificar si el servidor está accesible
        if (-not (Test-Connection -ComputerName $server -Count 1 -Quiet)) {
            Write-Host "[$server] No responde a ping" -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                Server = $server
                Status = "Offline"
                HotfixID = "N/A"
                InstalledOn = "N/A"
                Error = "No responde a ping"
            }
            continue
        }
        
        # Verificar el hotfix
        $hotfix = Get-HotFix -ComputerName $server -Id "KB$KBID" -ErrorAction SilentlyContinue
        
        if ($hotfix) {
            Write-Host "[$server] Actualizacion KB$KBID instalada el $($hotfix.InstalledOn)" -ForegroundColor Green
            $results += [PSCustomObject]@{
                Server = $server
                Status = "Online"
                HotfixID = $hotfix.HotFixID
                InstalledOn = $hotfix.InstalledOn
                Error = "N/A"
            }
        } else {
            Write-Host "[$server] Actualizacion KB$KBID NO esta instalada" -ForegroundColor Red
            $results += [PSCustomObject]@{
                Server = $server
                Status = "Online"
                HotfixID = "N/A"
                InstalledOn = "N/A"
                Error = "Actualizacion no encontrada"
            }
        }
    }
    catch {
        Write-Host "[$server] Error al verificar: $_" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Server = $server
            Status = "Error"
            HotfixID = "N/A"
            InstalledOn = "N/A"
            Error = $_.Exception.Message
        }
    }
}

# Mostrar resumen
Write-Host "`nResumen de la verificacion:" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Exportar resultados a CSV
$outputFile = "KB_Verification_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Host "`nResultados exportados a $outputFile" -ForegroundColor Cyan