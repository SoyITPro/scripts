#requires -RunAsAdministrator

<#
.SYNOPSIS
    Destruye deliberadamente el estado de Active Directory de un DC
    para realizar un laboratorio de restauración desde Windows Server Backup.

.DESCRIPTION
    El script:
      1. Verifica que el equipo sea un Domain Controller.
      2. Solicita confirmación explícita.
      3. Detiene servicios relacionados con AD.
      4. Detiene NTDS.
      5. Elimina NTDS.dit.
      6. Elimina SYSVOL.
      7. Elimina NETLOGON.
      8. Elimina las zonas DNS integradas en AD.
      9. Deshabilita los servicios AD DS.

    NO elimina el sistema operativo ni particiones/discos.

.WARNING
    DESTRUCTIVO. SOLO PARA LABORATORIOS.
#>

$ErrorActionPreference = "Stop"

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host "      DESTRUCCION DEL ESTADO DE ACTIVE DIRECTORY" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""

# ------------------------------------------------------------
# 1. Comprobar privilegios administrativos
# ------------------------------------------------------------

$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    throw "Este script debe ejecutarse como Administrador."
}

# ------------------------------------------------------------
# 2. Comprobar que existe AD DS
# ------------------------------------------------------------

$adRole = Get-WindowsFeature -Name AD-Domain-Services

if (-not $adRole.Installed) {
    throw "Este servidor no tiene instalado el rol Active Directory Domain Services."
}

# ------------------------------------------------------------
# 3. Obtener información del DC
# ------------------------------------------------------------

$computerSystem = Get-CimInstance Win32_ComputerSystem

if (-not $computerSystem.PartOfDomain) {
    throw "El servidor no pertenece a un dominio."
}

$domain = $computerSystem.Domain
$computerName = $env:COMPUTERNAME

Write-Host "Equipo : $computerName" -ForegroundColor Cyan
Write-Host "Dominio: $domain" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 4. Obtener información de AD
# ------------------------------------------------------------

Import-Module ActiveDirectory

try {
    $domainInfo = Get-ADDomain
}
catch {
    throw "No fue posible consultar Active Directory."
}

Write-Host "Nombre NetBIOS : $($domainInfo.NetBIOSName)" -ForegroundColor Yellow
Write-Host "DNS Root       : $($domainInfo.DNSRoot)" -ForegroundColor Yellow
Write-Host ""

# ------------------------------------------------------------
# 5. Barrera de seguridad
# ------------------------------------------------------------

Write-Host "ATENCION" -ForegroundColor Red
Write-Host ""
Write-Host "Esta operación destruirá deliberadamente el estado de" -ForegroundColor Red
Write-Host "Active Directory de ESTE controlador de dominio." -ForegroundColor Red
Write-Host ""
Write-Host "Se eliminarán:" -ForegroundColor Yellow
Write-Host "  - NTDS.dit"
Write-Host "  - SYSVOL"
Write-Host "  - NETLOGON"
Write-Host "  - Datos DNS integrados en AD"
Write-Host "  - Estado funcional de AD DS"
Write-Host ""

$confirmation = Read-Host `
    "Escribe exactamente DESTRUIR $domain para continuar"

if ($confirmation -ne "DESTRUIR $domain") {
    Write-Host ""
    Write-Host "Operación cancelada." -ForegroundColor Green
    exit
}

# ------------------------------------------------------------
# 6. Segunda confirmación
# ------------------------------------------------------------

$confirmation2 = Read-Host `
    "Escribe RESTAURACION para confirmar el laboratorio"

if ($confirmation2 -ne "RESTAURACION") {
    Write-Host ""
    Write-Host "Operación cancelada." -ForegroundColor Green
    exit
}

Write-Host ""
Write-Host "Iniciando destrucción..." -ForegroundColor Red
Write-Host ""

# ------------------------------------------------------------
# 7. Registrar información antes de destruir
# ------------------------------------------------------------

$logPath = "C:\AD-Destruction-Lab.log"

"Laboratorio de destrucción de Active Directory" |
    Out-File $logPath

"Fecha: $(Get-Date)" |
    Out-File $logPath -Append

"Equipo: $computerName" |
    Out-File $logPath -Append

"Dominio: $domain" |
    Out-File $logPath -Append

# ------------------------------------------------------------
# 8. Detener servicios relacionados
# ------------------------------------------------------------

$services = @(
    "Netlogon",
    "KDC",
    "DNS",
    "DFSR",
    "NTDS"
)

foreach ($service in $services) {

    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue

    if ($svc) {

        Write-Host "Deteniendo servicio $service..." -ForegroundColor Yellow

        try {
            Stop-Service -Name $service -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "No fue posible detener $service"
        }
    }
}

Start-Sleep -Seconds 5

# ------------------------------------------------------------
# 9. Eliminar NTDS.dit
# ------------------------------------------------------------

$ntdsPath = "$env:SystemRoot\NTDS\ntds.dit"

if (Test-Path $ntdsPath) {

    Write-Host ""
    Write-Host "Eliminando NTDS.dit..." -ForegroundColor Red

    Remove-Item `
        -Path $ntdsPath `
        -Force `
        -ErrorAction Stop
}

# ------------------------------------------------------------
# 10. Eliminar archivos de logs de NTDS
# ------------------------------------------------------------

$ntdsLogFiles = Get-ChildItem `
    "$env:SystemRoot\NTDS" `
    -Filter "*.log" `
    -ErrorAction SilentlyContinue

foreach ($file in $ntdsLogFiles) {

    Write-Host "Eliminando $($file.Name)" -ForegroundColor DarkRed

    Remove-Item `
        $file.FullName `
        -Force `
        -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# 11. Destruir SYSVOL
# ------------------------------------------------------------

$sysvolPath = "$env:SystemRoot\SYSVOL"

if (Test-Path $sysvolPath) {

    Write-Host ""
    Write-Host "Eliminando SYSVOL..." -ForegroundColor Red

    Get-ChildItem `
        $sysvolPath `
        -Force `
        -ErrorAction SilentlyContinue |
        Remove-Item `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# 12. Destruir NETLOGON
# ------------------------------------------------------------

$netlogonPath = "$env:SystemRoot\SYSVOL\sysvol\$domain\scripts"

if (Test-Path $netlogonPath) {

    Write-Host ""
    Write-Host "Eliminando scripts NETLOGON..." -ForegroundColor Red

    Remove-Item `
        $netlogonPath `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# 13. Eliminar zonas DNS integradas en AD
# ------------------------------------------------------------

Write-Host ""
Write-Host "Procesando zonas DNS..." -ForegroundColor Yellow

Import-Module DnsServer -ErrorAction SilentlyContinue

if (Get-Command Get-DnsServerZone -ErrorAction SilentlyContinue) {

    $zones = Get-DnsServerZone -ErrorAction SilentlyContinue

    foreach ($zone in $zones) {

        if (
            $zone.IsDsIntegrated -and
            $zone.ZoneName -notlike "_msdcs.*" -and
            $zone.ZoneName -ne "TrustAnchors"
        ) {

            Write-Host `
                "Eliminando zona DNS integrada: $($zone.ZoneName)" `
                -ForegroundColor Red

            try {

                Remove-DnsServerZone `
                    -Name $zone.ZoneName `
                    -Force `
                    -ErrorAction Stop

            }
            catch {

                Write-Warning `
                    "No fue posible eliminar $($zone.ZoneName)"
            }
        }
    }
}

# ------------------------------------------------------------
# 14. Deshabilitar servicios
# ------------------------------------------------------------

Write-Host ""
Write-Host "Deshabilitando servicios AD..." -ForegroundColor Yellow

foreach ($service in $services) {

    $svc = Get-Service `
        -Name $service `
        -ErrorAction SilentlyContinue

    if ($svc) {

        try {

            Set-Service `
                -Name $service `
                -StartupType Disabled `
                -ErrorAction Stop

        }
        catch {

            Write-Warning `
                "No fue posible cambiar el inicio de $service"
        }
    }
}

# ------------------------------------------------------------
# 15. Crear indicador de destrucción
# ------------------------------------------------------------

$marker = "C:\AD-LAB-DESTROYED.txt"

@"
============================================================
ACTIVE DIRECTORY LABORATORY DESTROYED
============================================================

Computer : $computerName
Domain   : $domain
Date     : $(Get-Date)

NTDS.dit      : DESTROYED
SYSVOL        : DESTROYED
NETLOGON      : DESTROYED
AD-integrated
DNS zones     : DESTROYED

Purpose:
Laboratorio de restauración de Active Directory
desde Windows Server Backup.

============================================================
"@ | Set-Content $marker

# ------------------------------------------------------------
# 16. Resultado
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Red

Write-Host " ACTIVE DIRECTORY HA SIDO DESTRUIDO" `
    -ForegroundColor Red

Write-Host "============================================================" `
    -ForegroundColor Red

Write-Host ""
Write-Host "El sistema operativo NO ha sido eliminado." `
    -ForegroundColor Green

Write-Host ""
Write-Host "Ahora puedes:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Reiniciar la VM."
Write-Host "2. Arrancar desde el ISO de Windows Server 2025."
Write-Host "3. Seleccionar Reparar el equipo."
Write-Host "4. Troubleshoot / Solucionar problemas."
Write-Host "5. System Image Recovery / Recuperación de imagen del sistema."
Write-Host "6. Seleccionar el backup de Windows Server Backup."
Write-Host "7. Restaurar el servidor/DC."
Write-Host ""

Write-Host "NO reinicies todavía si necesitas revisar el laboratorio." `
    -ForegroundColor Yellow

Write-Host ""