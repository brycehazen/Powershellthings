$list = Get-Content C:\script\HostNameList.txt #Defines content it pulls as list 
$DHServers = Get-DhcpServerInDC #gives variable name for loop

 #function that takes the hostname, Goes through DHCP scopes comparing looking for a match 
    foreach ($Server in $DHServers){
        $scopes = Get-DHCPServerv4Scope -ComputerName $Server.dnsname #get all scopes
    }
        

$Output = foreach ($hostname in $list) { #Calls each item in list a hostname and sends to output
    if (test-connection -count 1 -computername $hostname -quiet) #With 1 ping, check if hostname is online
    {   
        foreach ($scope in $scopes){ 
            if($scope | Get-DhcpServerV4Lease -ComputerName $server.dnsname | Where-Object HostName -like "$hostName*" ) #compares the hostname to find which scope it is in
            { $scope.name } #return scope it found hostname in
        }
        [PSCustomObject]@{ #Rename varibles in data pull for output file
        Asset = $hostname
        Location = $scope.name #only want the name of the scope
        Status = "Online"
        }
    }   

    else #statement if hostname is not online
    { 
        Write-host "$hostname Is offline, only Last Location is known. $hostname was added to the output file." -BackgroundColor DarkRed
        [PSCustomObject]@{
        Asset = $hostname
        Location = $scope.name #only want the name of the scope
        Status = "Offline"
        }
    }
}
$Output
$Output | Export-Csv -Path C:\script\Asset_Result.csv -NoTypeInformation #outputs .csv