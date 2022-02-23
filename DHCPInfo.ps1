$DHServers = Get-DhcpServerInDC
foreach ($Server in $DHServers)
{

$scopes = Get-DHCPServerv4Scope -ComputerName $Server.DnsName | Select-Object Name, ScopeID #only getting the Name and ScopeID

ForEach ($Address in $scopes) 
    {
$DHCPServer = $Server.DnsName

$Address | Export-Csv "C:\script\Results\ServerScopes.csv" -Append -NoTypeInformation
    
    }
 }