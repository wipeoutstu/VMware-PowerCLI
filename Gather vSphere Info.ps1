<######################################
 Get vSwitch Config 
#######################################>
&{foreach($esx in Get-VMHost){
    $vNicTab = @{}
    $esx.ExtensionData.Config.Network.Vnic | %{
        $vNicTab.Add($_.Portgroup,$_)
    }
    foreach($vsw in (Get-VirtualSwitch -VMHost $esx)){
        foreach($pg in (Get-VirtualPortGroup -VirtualSwitch $vsw)){
            Select -InputObject $pg -Property @{N="ESX";E={$esx.name}},
                @{N="vSwitch";E={$vsw.Name}},
                @{N="Active NIC";E={[string]::Join(',',$vsw.ExtensionData.Spec.Policy.NicTeaming.NicOrder.ActiveNic)}},
                @{N="Standby NIC";E={[string]::Join(',',$vsw.ExtensionData.Spec.Policy.NicTeaming.NicOrder.StandbyNic)}},
                @{N="Portgroup";E={$pg.Name}},
                @{N="VLAN";E={$pg.VLanId}},
                @{N="Device";E={if($vNicTab.ContainsKey($pg.Name)){$vNicTab[$pg.Name].Device}}},
                @{N="IP";E={if($vNicTab.ContainsKey($pg.Name)){$vNicTab[$pg.Name].Spec.Ip.IpAddress}}}
        }
    }
}} | Export-Csv vSwitchConfig.csv -NoTypeInformation -UseCulture

Get-VMHostNetworkAdapter | select VMhost, Name, DhcpEnabled, IP, SubnetMask, Mac, PortGroupName, ManagementTrafficEnabled, vMotionEnabled, Mtu, FullDuplex, BitRatePerSec | Export-Csv C:\Downloads\VMHostNetworkDetails.csv



<######################################
 Get Resource Pool Info and membership 
#######################################>
Get-ResourcePool
get-vm -Location "Host Management" | Select Name #| Out-file C:\Downloads\VmsByPool.txt
get-vm -Location "Non-Production" | Select Name #| Out-file C:\Downloads\VmsByPool.txt
get-vm -Location "Production - High" | Select Name #| Out-file C:\Downloads\VmsByPool.txt
get-vm -Location "Production - Normal" | Select Name #| Out-file C:\Downloads\VmsByPool.txt
get-vm -Location "Production - Low" | Select Name #| Out-file C:\Downloads\VmsByPool.txt


<######################################
 List Folder Paths & VM's
#######################################>
Get-folder -type VM | Foreach {($_ | Get-FolderPath).Path | Out-file C:\Downloads\VC-Folders.txt -Append}
Get-VM| Select Name | Out-file C:\Downloads\VMs.txt


<######################################
 List VM's & Folder Info (vLookup to merge)
#######################################>
Function Get-FolderPath{
	param(
	[parameter(valuefrompipeline = $true,
	position = 0,
	HelpMessage = "Enter a folder")]
	[VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl[]]$Folder,
	[switch]$ShowHidden = $false
	)
 	begin{
		$excludedNames = "Datacenters","vm","host"
	}
 	process{
		$Folder | %{
			$fld = $_.Extensiondata
			$fldType = "yellow"
			if($fld.ChildType -contains "VirtualMachine"){
				$fldType = "blue"
			}
			$path = $fld.Name
			while($fld.Parent){
				$fld = Get-View $fld.Parent
				if((!$ShowHidden -and $excludedNames -notcontains $fld.Name) -or $ShowHidden){
					$path = $fld.Name + "\" + $path
				}
			}
			$row = "" | Select Name,Id,Path,Type
			$row.Name = $_.Name
			$row.ID = $_.Id
			$row.Path = $path
			$row.Type = $fldType
			$row
		}
	}
}

Get-Folder | Get-FolderPath | Export-Excel New-Folders.xlsx
Get-VM | Select-Object Name, FolderId, Folder, ResourcePoolId, ResourcePool | Export-Excel New-VMs.xlsx


<######################################
List vCenter Rights/Roles 
#######################################>
Get-VIPermission | Select Principal, Role, Entity, Propagate, UID | Export-CSV “C:\Downloads\Rights.csv”
Get-VIRole | Select Name, Description


<######################################
 List NTP config on hosts
#######################################>
Get-VMHost | Get-VMHostService | Where-Object {$_.key -eq "ntpd"} | select vmhost, label, Key, Policy, Running, Required | format-table -autosize
Get-VMHost | Sort Name | Select Name, @{N="NTPServer";E={$_ |Get-VMHostNtpServer}}, @{N="ServiceRunning";E={(Get-VmHostService -VMHost $_ | Where-Object {$_.key-eq "ntpd"}).Running}}


<######################################
 Get DRS, EVC & Group / Rule Info
#######################################>
Get-Cluster | Select Name, HAEnabled, HAAdmissionControlEnabled, HAFailoverLevel, HARestartPriority, HAIsolationResponse, VMSwapfilePolicy, DrsEnabled, DrsMode, DrsAutomationLevel, EVCMode | ft
Get-DrsClusterGroup -Cluster "Tenet Production Cluster" | ft -autosize
Get-DrsVMHostRule -Cluster "Tenet Production Cluster" | ft -autosize
Get-Cluster "Tenet Production Cluster" | Get-DrsRule | select Name, KeepTogether, Enabled, Type, @{N="VMnames";E={ $_.Vmids|%{(get-view -id $_).name} } } | ft -autosize


<######################################
 Get VM Info
#######################################>
$report = @()
 
foreach($vm in Get-View -ViewType Virtualmachine){
    $vms = "" | Select-Object VMName, Hostname, IPAddress, OS, VMState, TotalCPU, TotalMemory,
         MemoryUsage, TotalNics, ToolsStatus, ToolsVersion, HardwareVersion, TimeSync, Portgroup,
         VMHost, UsedSpaceGB, Datastore, Notes, SnapshotName, SnapshotDate, SnapshotSizeGB
           
    $vms.VMName = $vm.Name
    $vms.Hostname = $vm.guest.hostname
    $vms.IPAddress = $vm.guest.ipAddress
    $vms.OS = $vm.Config.GuestFullName
    $vms.VMState = $vm.summary.runtime.powerState
    $vms.TotalCPU = $vm.summary.config.numcpu
    $vms.TotalMemory = $vm.summary.config.memorysizemb
    $vms.TotalNics = $vm.summary.config.numEthernetCards
    $vms.MemoryUsage = $vm.summary.quickStats.guestMemoryUsage
    $vms.ToolsStatus = $vm.guest.toolsstatus
    $vms.ToolsVersion = $vm.config.tools.toolsversion
    $vms.TimeSync = $vm.Config.Tools.SyncTimeWithHost
    $vms.HardwareVersion = $vm.config.Version
    $vms.Portgroup = Get-View -Id $vm.Network -Property Name | select -ExpandProperty Name
    $vms.VMHost = Get-View -Id $vm.Runtime.Host -property Name | select -ExpandProperty Name
    $vms.UsedSpaceGB = [math]::Round($vm.Summary.Storage.Committed/1GB,2)
    $vms.Datastore = $vm.Config.DatastoreUrl[0].Name
    $vms.Notes = $vm.Config.Annotation
    $vms.SnapshotName = &{$script:snaps = Get-Snapshot -VM $vm.Name; $script:snaps.Name -join ','}
    $vms.SnapshotDate = $script:snaps.Created -join ','
    $vms.SnapshotSizeGB = $script:snaps.SizeGB -join ','
    $Report += $vms
}
    $report | Export-CSV “C:\Downloads\Deets.csv”

