#Sripted by: Andreas Friedl
#Creation Date: 29.01.2022
#Version: 2.0

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

#Default-domains
$DefaultexternalDomain=Get-AcceptedDomain | Where{$_.Default -eq 'True'} | Select-Object DomainName | Format-Table -HideTableHeaders | Out-String
$DefaultexternalDomain = $DefaultexternalDomain -replace '\s',''
$DefaultinternalDomain=Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select-Object Domain | Format-Table -HideTableHeaders | Out-String
$DefaultinternalDomain = $DefaultinternalDomain -replace '\s',''

clear

#Willkommenstext
Write-Host "Exchange-URL-Konfig-Script v2.0"
Write-Host ""
write-host ""

Write-Host "Abfrage Domänen und URLs:" -ForegroundColor DarkYellow

write-host ""
write-host ""

$defaultValue = $DefaultinternalDomain
$internaldomain = Read-Host "Interne Domäne eingeben (Enter um Vorauswahl zu übernehmen): [$($defaultValue)]"
$internaldomain = ($defaultValue,$internaldomain)[[bool]$internaldomain]

$defaultValue = $DefaultexternalDomain
$externaldomain = Read-Host "Externe Domäne eingeben (Enter um Vorauswahl zu übernehmen) [$($defaultValue)]"
$externaldomain = ($defaultValue,$externaldomain)[[bool]$externaldomain]

write-host ""
write-host ""

#Urls - Abfrage
$internalhostname = "outlook." + $internaldomain
$externalhostname = "outlook." + $externaldomain
$externaleashostname = "outlook." + $externaldomain

$defaultValue = $internalhostname
$internalhostname = Read-Host "Interne Exchange-URL eingeben (Enter um Vorauswahl zu übernehmen) [$($defaultValue)]"
$internalhostname = ($defaultValue,$internalhostname)[[bool]$internalhostname]

$defaultValue = $externalhostname
$externalhostname = Read-Host "Externe Exchange-URL eingeben (Enter um Vorauswahl zu übernehmen) [$($defaultValue)]"
$externalhostname = ($defaultValue,$externalhostname)[[bool]$externalhostname]

$defaultValue = $externaleashostname
$externaleashostname = Read-Host "Externe ActiveSync-URL eingeben (Enter um Vorauswahl zu übernehmen) [$($defaultValue)]"
$externaleashostname = ($defaultValue,$externaleashostname)[[bool]$externaleashostname]

write-host ""
write-host ""

#Urls - fest
$autodiscoverhostname = "autodiscover." + $externaldomain

#Test
Write-Host "Übersicht Domänen und URLs:" -ForegroundColor DarkYellow

write-host ""
write-host ""

write-host "DNS-Einträge:"
write-host ""
write-host "Externer Hostname:     "$externalhostname
write-host "Interner Hostname:     "$internalhostname
write-host "ActiveSync Hostname:   "$externaleashostname
write-host "Autodisocver Hostname: "$autodiscoverhostname
write-host ""
write-host ""
write-host "DNS-Einträge prüfen...."
write-host ""

#DNS-Einträge
$name = $externalhostname
if($rec = Resolve-dnsName -Name $name -ErrorAction 0){
    $IP=""
    $IP= $rec.IPAddress 
    Write-Host "DNS-Eintrag $name vorhanden (IP: $IP)" -ForegroundColor Green
}else{
     Write-Host "DNS-Eintrag $name nicht vorhanden - bitte prüfen!" -ForegroundColor Red
}

$name = $internalhostname
if($rec = Resolve-dnsName -Name $name -ErrorAction 0){
    $IP=""
    $IP= $rec.IPAddress
    Write-Host "DNS-Eintrag $name vorhanden (IP: $IP)" -ForegroundColor Green
}else{
     Write-Host "DNS-Eintrag $name nicht vorhanden - bitte prüfen!" -ForegroundColor Red
}

$name = $externaleashostname
if($rec = Resolve-dnsName -Name $name -ErrorAction 0){
    $IP=""
    $IP= $rec.IPAddress
    Write-Host "DNS-Eintrag $name vorhanden (IP: $IP)" -ForegroundColor Green
}else{
     Write-Host "DNS-Eintrag $name nicht vorhanden - bitte prüfen!" -ForegroundColor Red
}

$name = $autodiscoverhostname
if($rec = Resolve-dnsName -Name $name -ErrorAction 0){
    $IP=""
    $IP= $rec.IPAddress
    Write-Host "DNS-Eintrag $name vorhanden (IP: $IP)" -ForegroundColor Green
}else{
     Write-Host "DNS-Eintrag $name nicht vorhanden - bitte prüfen!" -ForegroundColor Red
}


Write-host ""
Read-host "Wenn die URLs passen -> any key to continue :-) "

write-host ""
write-host ""

Write-Host "Konfiguation Domänen und URLs:" -ForegroundColor DarkYellow

write-host ""
write-host ""

#Variablen
$servername = $env:COMPUTERNAME
$owainturl = "https://" + "$internalhostname" + "/owa"
$owaexturl = "https://" + "$externalhostname" + "/owa"
$ecpinturl = "https://" + "$internalhostname" + "/ecp"
$ecpexturl = "https://" + "$externalhostname" + "/ecp"
$ewsinturl = "https://" + "$internalhostname" + "/EWS/Exchange.asmx"
$ewsexturl = "https://" + "$externalhostname" + "/EWS/Exchange.asmx"
$easinturl = "https://" + "$internalhostname" + "/Microsoft-Server-ActiveSync"
$easexturl = "https://" + "$externaleashostname" + "/Microsoft-Server-ActiveSync"
$oabinturl = "https://" + "$internalhostname" + "/OAB"
$oabexturl = "https://" + "$externalhostname" + "/OAB"
$mapiinturl = "https://" + "$internalhostname" + "/mapi"
$mapiexturl = "https://" + "$externalhostname" + "/mapi"
$aduri = "https://" + "$autodiscoverhostname" + "/Autodiscover/Autodiscover.xml"

write-host "URLs werden gesetzt...."
write-host ""
#Urls Setzen
Get-OwaVirtualDirectory -Server $servername | Set-OwaVirtualDirectory -internalurl $owainturl -externalurl $owaexturl -Confirm:$false
Get-EcpVirtualDirectory -server $servername | Set-EcpVirtualDirectory -internalurl $ecpinturl -externalurl $ecpexturl -Confirm:$false
Get-WebServicesVirtualDirectory -server $servername | Set-WebServicesVirtualDirectory -internalurl $ewsinturl -externalurl $ewsexturl -Confirm:$false
Get-ActiveSyncVirtualDirectory -Server $servername | Set-ActiveSyncVirtualDirectory -internalurl $easinturl -externalurl $easexturl -Confirm:$false
Get-OabVirtualDirectory -Server $servername | Set-OabVirtualDirectory -internalurl $oabinturl -externalurl $oabexturl -Confirm:$false
Get-MapiVirtualDirectory -Server $servername | Set-MapiVirtualDirectory -externalurl $mapiexturl -internalurl $mapiinturl -Confirm:$false
Get-OutlookAnywhere -Server $servername | Set-OutlookAnywhere -externalhostname $externalhostname -internalhostname $internalhostname -ExternalClientsRequireSsl:$true -InternalClientsRequireSsl:$true -ExternalClientAuthenticationMethod 'Negotiate'  -Confirm:$false
Get-ClientAccessService $servername | Set-ClientAccessService -AutoDiscoverServiceInternalUri $aduri -Confirm:$false

write-host "IIS wird angepasst...."
write-host ""
### IIS EWS
$iisSiteName = "Default Web Site"
$iisAppName = "EWS"
Write-Host Enable windows authentication
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/basicAuthentication' -Name 'enabled' -Value 'true' -PSPath 'IIS:\' -Location "$iisSiteName/$iisAppName"
### IIS MAPI
$iisSiteName = "Default Web Site"
$iisAppName = "mapi"
Write-Host Enable windows authentication
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/basicAuthentication' -Name 'enabled' -Value 'true' -PSPath 'IIS:\' -Location "$iisSiteName/$iisAppName"
### IIS reset
iisreset
write-host "Fertig!"
### Übersicht
write-host "."  
write-host ""
write-host "Übersicht der URLs:"
write-host ""
write-host "OWA:"
Get-OwaVirtualDirectory -Server $servername | fl internalurl, externalurl
write-host "ECP:" 
Get-EcpVirtualDirectory -server $servername | fl internalurl, externalurl 
write-host "WebServices:"
Get-WebServicesVirtualDirectory -server $servername | fl internalurl, externalurl
write-host "ActveSync:"
Get-ActiveSyncVirtualDirectory -Server $servername  | fl internalurl, externalurl 
write-host "OAB:"
Get-OabVirtualDirectory -Server $servername | fl internalurl, externalurl
write-host "MAPI:"
Get-MapiVirtualDirectory -Server $servername | fl externalurl,internalurl
write-host "OutlookAnywhere:"
Get-OutlookAnywhere -Server $servername | fl externalhostname, internalhostname 
write-host "CAS:"
Get-ClientAccessService $servername | fl AutoDiscoverServiceInternalUri

#Fertig
write-host ""
Write-Host "Fertig!" -ForegroundColor DarkYellow
write-host ""
pause
