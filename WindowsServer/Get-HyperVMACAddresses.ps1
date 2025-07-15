<#
.SYNOPSIS
    Lista las direcciones MAC de todas las máquinas virtuales en un host Hyper-V
.DESCRIPTION
    Este script obtiene y muestra en consola las direcciones MAC de todos los adaptadores de red
    de cada máquina virtual presente en el host Hyper-V donde se ejecuta.
    Incluye información del nombre de la VM y de cada adaptador de red.
.NOTES
    File Name      : Get-HyperVMACAddresses.ps1
    Author         : @SoyITPro
    Prerequisite   : PowerShell 5.1 o superior con módulo Hyper-V
    Execution Policy: Recomendado ejecutar con permisos de administrador
.LINK
    https://github.com/SoyITPro/scripts
#>

#region PARAMETROS
param (
    [switch]$ExportCSV,
    [string]$CSVPath = "$env:USERPROFILE\Desktop\HyperV_MAC_Report.csv"
)
#endregion

#region FUNCIONES
function Get-MACAddresses {
    try {
        # Obtener todas las máquinas virtuales
        $VMs = Get-VM -ErrorAction Stop
        
        # Array para almacenar resultados
        $Results = @()

        foreach ($VM in $VMs) {
            $VMInfo = [PSCustomObject]@{
                VMName        = $VM.Name
                VMState      = $VM.State
                VMPath       = $VM.Path
                ProcessorCount = $VM.ProcessorCount
                MemoryAssigned = $VM.MemoryAssigned / 1GB
            }

            # Obtener adaptadores de red
            $VMNetworkAdapters = Get-VMNetworkAdapter -VMName $VM.Name -ErrorAction SilentlyContinue
            
            if ($VMNetworkAdapters) {
                foreach ($Adapter in $VMNetworkAdapters) {
                    $Results += [PSCustomObject]@{
                        VMName          = $VM.Name
                        AdapterName     = $Adapter.Name
                        MACAddress      = $Adapter.MacAddress
                        IPAddresses     = ($Adapter.IPAddresses -join ', ')
                        SwitchName      = $Adapter.SwitchName
                        VMState        = $VM.State
                        IsLegacy       = $Adapter.IsLegacy
                    }
                }
            } else {
                $Results += [PSCustomObject]@{
                    VMName          = $VM.Name
                    AdapterName     = "No adapters found"
                    MACAddress      = "N/A"
                    IPAddresses    = "N/A"
                    SwitchName      = "N/A"
                    VMState        = $VM.State
                    IsLegacy       = "N/A"
                }
            }
        }

        return $Results
    }
    catch {
        Write-Error "Error al obtener información de VMs: $_"
        return $null
    }
}
#endregion

#region EJECUCIÓN_PRINCIPAL
Clear-Host
Write-Host "=== Script de Reporte de MAC Addresses Hyper-V ===" -ForegroundColor Cyan
Write-Host "Iniciando proceso..." -ForegroundColor Yellow

$MACData = Get-MACAddresses

if ($MACData) {
    # Mostrar en consola
    $MACData | Format-Table -AutoSize
    
    # Exportar a CSV si se solicita
    if ($ExportCSV) {
        try {
            $MACData | Export-Csv -Path $CSVPath -NoTypeInformation -Encoding UTF8
            Write-Host "`nReporte exportado a: $CSVPath" -ForegroundColor Green
        }
        catch {
            Write-Host "Error al exportar CSV: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No se encontraron datos para mostrar." -ForegroundColor Red
}

Write-Host "`nProceso completado.`n" -ForegroundColor Yellow
#endregion