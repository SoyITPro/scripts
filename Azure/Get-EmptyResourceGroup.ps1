<#
.SYNOPSIS
Lista todos los Resource Groups vacíos en la suscripción actual de Azure.

.DESCRIPTION
Este script se conecta a Azure utilizando el contexto autenticado del módulo Az
y recorre todos los Resource Groups de la suscripción actual. Para cada grupo
de recursos consulta los recursos asociados y muestra únicamente aquellos que
no contienen ningún recurso desplegado.

La salida incluye el nombre del Resource Group y la región donde se encuentra.

.NOTES
Requisitos:
- Módulo Az PowerShell instalado.
- Azure Cloud Shell
- Permisos para leer Resource Groups y recursos en la suscripción.
- Sesión autenticada mediante Connect-AzAccount.

.EXAMPLE
PS> .\Get-EmptyResourceGroups.ps1

ResourceGroup               Location
-------------               --------
RG-LAB-TEST                 eastus
RG-DECOMMISSIONED           westus2

Muestra todos los Resource Groups vacíos de la suscripción actual.
#>


Connect-AzAccount

Get-AzResourceGroup | ForEach-Object {
    $rg = $_

    $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName

    if ($resources.Count -eq 0) {
        [PSCustomObject]@{
            ResourceGroup = $rg.ResourceGroupName
            Location      = $rg.Location
        }
    }
} | Format-Table -AutoSize
