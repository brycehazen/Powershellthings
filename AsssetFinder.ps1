#>>>>>Written by Bryce Hazen Howard and John Williamson<<<<<
 
write-host 'Developed by: Bryce Hazen Howard and John Williamson' -ForegroundColor Green

$servers = Get-DHCPServerInDC
$hashtable = @{}

# scopes into the leases to go into the PsCustomObject to be matched later
Write-Progress -Activity Updating -Status 'Getting Asset list and connecting to the Orlando Health network....'

$leases = $servers <#;$counter = 0#> | ForEach-Object {
    $server = $_.dnsname
    Get-DHCPServerv4Scope -computerName $server  #get scopes on DHCP serves
   
    } | ForEach-Object {
     $scope = $_
    $_ | Get-DHCPServerV4Lease -ComputerName $server | #get leases in all the scopes
   
     ForEach-Object  {
        [pscustomobject]@{ # Make object to match later
        ScopeName = $scope.name #want name of scope only
        HostName  = $_.hostname #want hostname of leases
        }
    }
}

Write-Progress -Activity Updating -Status 'Locational Information has been gathered, now looking for matches'
 

$assets = (Import-CSV c:\script\Asset_List.csv).asset #pull asset list
 
$assets | ForEach-Object { $asset = $_ #Go through hostnames finding matching lease

    $leases | Where-Object { #check leases
        $_.HostName -like "${asset}*" #find hostname
    } | ForEach-Object {
        $hashtable[$asset] = $_.ScopeName #store matches
    }
}


    $Output = foreach ($hostname in (Import-Csv C:\script\Asset_List.csv | Select-Object -ExpandProperty asset)) { #Calls each item in list a hostname and sends to output
        if (test-connection -count 1 -computername $hostname -quiet){  #checking if hostname is on line with 1 ping, If online run the following
            $System = $Bios = $User = $mac = $IpV  = $null #set all hostname in to null to avoid bad data
           
            try{ #try the following data pull
                $System = Get-CimInstance Win32_ComputerSystem -ComputerName $hostname -ErrorAction stop | Select-Object -Property Name,Model
                $BIOS = Get-CimInstance Win32_BIOS -ComputerName $hostname -ErrorAction stop | Select-Object -Property SerialNumber
                $User = get-childitem "\\$hostname\c$\Users"  -ErrorAction stop | Sort-Object LastWriteTime -Descending | Select-Object -first 1
                $mac = invoke-command -computername $hostname -ErrorAction stop {(Get-CimInstance -class win32_networkadapterconfiguration).MacAddress  | Select-Object -first 1}
                $pipeBDE= manage-bde -cn $hostname -status
                $encryptStat = $pipeBDE | Select-String "Percentage Encrypted:" #only one varible of encryption status
                $encryptStat = ($encryptStat -split ": ")[1]
                $IpV = (test-connection -ComputerName $hostname -count 1  -ErrorAction stop | Select-Object -expandproperty IPV4Address).IPaddresstostring
            }
       
            catch{ #if permissions aren't correctly set to be back doored into give this message
            $ErrorMessage = $hostname.Exception.Message
                if($ErrorMessage  -like '*Access*Denied*'){
                    write-host 'Error accessing asset due to asset privileges. Access Denied :(' -BackgroundColor DarkRed
                }
            }
           
            [PSCustomObject]@{ #Rename varibles in data pull for output file
            Asset =  $hostname
            Model = $System.Model
            SerialNumber = $BIOS.SerialNumber
            Location = $hashtable[$hostname]
            LastUser = $User #if no other user has logged in, you will be the last user.
            Encryption =$encryptStat
            BCA_Status = if (Test-Path "\\$hostname\c$\Epic\Bin\BCA PC\Active BCA PC\") {'True'} else{'False'}; # check if bca files are installed.
            MacAddress = $mac
            IpAddress = $IpV
            Status = "Online"
            }
        }  
 
        else{ #statement if hostname is not online
         
             write-host "$hostname is offline or does not have a DHCP Lease. If $hostname is offine, but has a lease last location was found"  -BackgroundColor DarkRed
             write-host "$hostname was added to the output file." -BackgroundColor DarkRed
            [PSCustomObject]@{
            Asset = $hostname
            Location = $hashtable[$hostname]
            Status = "Offline"
            }
        }
    }

$Output

Write-Progress -Activity Updating -Status 'All Done! Information collected has been exported to: C:\script\Asset_Result.csv'

write-host "All Done! Information collected has been exported to: C:\script\Asset_Result.csv" -ForegroundColor Green
$Output | Export-Csv -Path C:\script\Asset_Result.csv -NoTypeInformation #outputs .cvs