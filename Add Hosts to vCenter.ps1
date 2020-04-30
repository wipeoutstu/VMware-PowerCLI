<# PowerCLI script to add ESXi hosts to vCenter Server

Specify vCenter Server, vCenter Server username, vCenter Server user password, vCenter Server location which can be the Datacenter, a Folder or a Cluster (which I used).
#>
$vCenter="192.168.1.100"
$vCenterUser="administrator@vsphere.local"
$vCenterUserPassword="Passw0rd123!"
$vcenterlocation="sw-cluster"

# Specify the ESXi host you want to add to vCenter Server and the user name and password to be used #
$esxihosts=(192.168.1.10,192.168.1.20)
$esxihostuser="root"
$esxihostpasswd="Passw0rd123!"

#Connect to vCenter Server
write-host Connecting to vCenter Server $vcenter -foreground green
Connect-viserver $vCenter -user $vCenterUser -password $vCenterUserPassword -WarningAction 0 | out-null

write-host --------
write-host Start adding ESXi hosts to the vCenter Server $vCenter
write-host --------

# Add ESXi hosts
foreach ($esxihost in $esxihosts) {
Add-VMHost $esxihost -Location $vcenterlocation -User $esxihostuser -Password $esxihostpasswd
Add-VMHost $esxihost -User $esxihostuser -Password $esxihostpasswd
}

# Disconnect from vCenter Server
write-host "Disconnecting vCenter Server $vcenter" -foreground green
disconnect-viserver -confirm:$false | out-null
