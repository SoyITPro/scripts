<#
.SYNOPSIS
    Exportar registros DNS.
.DESCRIPTION
    Este script exporta todos los registros DNS de todas las zonas DNS en el DNS Server de Windows Server
.NOTES
    Author         : @SoyITPro
    Prerequisite   : PowerShell 5.1 o superior
    
#>
$dnsRecords = @()
$zones = Get-DnsServerZone
foreach ($zone in $zones) {
    $zoneInfo = Get-DnsServerResourceRecord -ZoneName $zone.ZoneName
    foreach ($info in $zoneInfo) {
        $timestamp = if ($info.Timestamp) { $info.Timestamp } else { "static" }
        $timetolive = $info.TimeToLive.TotalSeconds
        $recordData = switch ($info.RecordType) {
            'A' { $info.RecordData.IPv4Address }
            'CNAME' { $info.RecordData.HostnameAlias }
            'NS' { $info.RecordData.NameServer }
            'SOA' { "[$($info.RecordData.SerialNumber)] $($info.RecordData.PrimaryServer), $($info.RecordData.ResponsiblePerson)" }
            'SRV' { $info.RecordData.DomainName }
            'PTR' { $info.RecordData.PtrDomainName }
            'MX' { $info.RecordData.MailExchange }
            'AAAA' { $info.RecordData.IPv6Address }
            'TXT' { $info.RecordData.DescriptiveText }
            default { $null }
        }
        $dnsRecords += [pscustomobject]@{
            Name       = $zone.ZoneName
            Hostname   = $info.Hostname
            Type       = $info.RecordType
            Data       = $recordData
            Timestamp  = $timestamp
            TimeToLive = $timetolive
        }