Start-Transcript -Path "C:\PS\Transcripts\AddHostsToVC.txt"

<# PowerCLI script to add ESXi hosts to vCenter Server

Specify vCenter Server, vCenter Server username, vCenter Server user password, vCenter Server location which can be the Datacenter, a Folder or a Cluster (which I used).
#>
$vCenter="vcenter.lab.local"
$vCenterUser="administrator@vsphere.local"
$vCenterUserPassword="Password123!"
$vcenterlocation="lab-cluster"

# Specify the ESXi host you want to add to vCenter Server and the user name and password to be used #
$esxihosts=("esxi-01.lab.local","esxi-02.lab.local")
$esxihostuser="root"
$esxihostpasswd="password123"

Clear-Host
write-host
write-host
write-host
write-host
write-host
write-host
write-host
write-host
#Connect to vCenter Server
write-host Connecting to $vcenter -foreground Green
Connect-viserver $vCenter -user $vCenterUser -password $vCenterUserPassword -WarningAction 0 | out-null

write-host
write-host ------------------------------------------------ -foreground Red
write-host
write-host Adding ESXi hosts to $vCenter -foreground Yellow
write-host
write-host ------------------------------------------------ -foreground Red
write-host

# Add ESXi hosts
foreach ($esxihost in $esxihosts) {
Add-VMHost -name $esxihost -Location $vcenterlocation -User $esxihostuser -Password $esxihostpasswd -force
#Add-VMHost -name $esxihost -User $esxihostuser -Password $esxihostpasswd
}

# Disconnect from vCenter Server
write-host
write-host "Disconnecting from $vcenter" -foreground Green
write-host

disconnect-viserver -confirm:$false | out-null
write-host
Stop-Transcript