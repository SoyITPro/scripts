<#
.SYNOPSIS
    Obtiene claves de recuperación de BitLocker usando el módulo de PowerShell
#>

# Verificar e importar módulo BitLocker
if (-not (Get-Module -Name BitLocker -ListAvailable)) {
    Write-Warning "Módulo BitLocker no disponible. Intentando cargarlo..."
    Import-Module BitLocker -ErrorAction SilentlyContinue
}

if (Get-Command -Name Get-BitLockerVolume -ErrorAction SilentlyContinue) {
    # Configurar archivo de salida
    $OutputFile = "C:\Temp\BitLockerKeys_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    # Crear directorio si no existe
    if (-not (Test-Path -Path "C:\Temp")) {
        New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
    }

    # Obtener volúmenes protegidos con BitLocker
    $volumes = Get-BitLockerVolume | Where-Object { $_.ProtectionStatus -eq "On" }

    if ($volumes) {
        $results = @()
        foreach ($vol in $volumes) {
            $protectors = Get-BitLockerVolume -MountPoint $vol.MountPoint | `
                Select-Object -ExpandProperty KeyProtector | `
                Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
            
            foreach ($prot in $protectors) {
                $results += "[$($prot.KeyProtectorId)] $($prot.RecoveryPassword)"
            }
        }

        if ($results) {
            $results | Out-File -FilePath $OutputFile -Encoding UTF8
            Write-Host "Claves encontradas y guardadas en: $OutputFile" -ForegroundColor Green
            Get-Content $OutputFile
        } else {
            Write-Warning "No se encontraron protectores de clave de recuperación, pero BitLocker está activo."
        }
    } else {
        Write-Warning "No se encontraron volúmenes con BitLocker activado."
    }
} else {
    Write-Error "No se pudo cargar el módulo BitLocker. Pruebe el Método 2."
}