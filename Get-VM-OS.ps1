#Connect-VIServer -Server 10.10.10.20
#DisConnect-VIServer

$debug = $false
$OS_hashtable = $null
$OS_hashtable = @{}
$NullOS = Get-Content C:\PS\Guestfullname.txt
$VMs = Get-VM
Foreach ($VM in $VMs){
    $OSName = $VM.ExtensionData.Guest.GuestFullName
    IF ($OSName -eq $NULL){$OSName = $VM.ExtensionData.Config.GuestFullName}
    IF ($OSName -eq $NullOS){$OSName = "Unknown"}
    IF ($debug){write-host "$VM - $OSName"}
    If(!($OS_hashtable.ContainsKey($OSName))){
        $OS_hashtable.add($OSName,0)
    }
    $Value = $OS_hashtable.$OSName
    $NewValue = $Value + 1
    $OS_hashtable[$osName] = $NewValue
}
#$OS_hashtable | FT -AutoSize | Out-File -FilePath "C:\Users\ucs-admin\Desktop\vm_os_info.txt"
#$OS_hashtable | ForEach-Object{ [pscustomobject]$_ } | Export-CSV -Path "C:\Users\ucs-admin\Desktop\vm_os_info.csv"
$OS_hashtable | ForEach-Object{ [pscustomobject]$_ } | Export-Excel "C:\Users\ucs-admin\Desktop\vm_os_info.xlsx" -WorkSheetName VM_Tally

Get-VM | Select @{Label = "VM Name" ; Expression = {$_.Name} },@{Label = "Guest OS" ; Expression = {$_.ExtensionData.Config.GuestFullName} } | Export-Excel "C:\Users\ucs-admin\Desktop\vm_os_info.xlsx" -WorkSheetName VM_List

Get-Cluster | Get-VMHost | Select @{Label = "Host"; Expression = {$_.Name}} , @{Label = "ESX Version"; Expression = {$_.version}}, @{Label = "ESX Build" ; Expression = {$_.build}} | Export-Excel "C:\Users\ucs-admin\Desktop\vm_os_info.xlsx" -WorkSheetName Host_Ver

$Global:DefaultVIServers | select Name, Version, Build | Export-Excel "C:\Users\ucs-admin\Desktop\vm_os_info.xlsx" -WorkSheetName vCenter_Ver

Get-vSphereLicenseInfo.ps1 | Export-Excel "C:\Users\ucs-admin\Desktop\vm_os_info.xlsx" -WorkSheetName vSphere_Licenses
