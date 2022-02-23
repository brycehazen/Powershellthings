$list = Get-Content C:\script\HostNames.txt #Defines content it pulls as list

$Output = foreach ($hostname in $list) #Calls each item in list a hostname and sends to output
{
    if (test-connection -count 1 -computername $hostname -quiet)  #checking if hostname is on line with 1 ping, If online run the following
    {
        $System = Get-WmiObject Win32_ComputerSystem -ComputerName $hostname | Select-Object -Property Name,Model 
        $BIOS = Get-WmiObject Win32_BIOS -ComputerName $hostname | Select-Object -Property SerialNumber
        $User = get-childitem "C:\Users" | Sort-Object LastWriteTime -Descending | Select-Object -first 1
        $mac = invoke-command -computername $hostname {(gwmi -class win32_networkadapterconfiguration).MacAddress | select -first 1}
        $IpV = (test-connection -ComputerName $hostname -count 1 | select -expandproperty IPV4Address).IPaddresstostring
        $parts = $IpV.Split(".")  #converts the last octet into a zero
        $parts[3] = "0"
        $ip2 = [String]::Join(".", $parts)
    }
    
    
    else #statement if hostname is not online
    { 
        write-host $hostname not online
    }

[PSCustomObject]@{ #Rename varibles in data pull for output file
        ComputerName = $hostname
        Model = $System.Model
        SerialNumber = $BIOS.SerialNumber
        LastUser = $User
        MacAddress = $mac
        IpAddress = $IpV
        IpScope = $ip2}
    

}
$Output

$Output | Export-Csv -Path C:\script\Result.csv -NoTypeInformation