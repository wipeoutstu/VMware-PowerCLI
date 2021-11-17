

<######################################
List vCenter Rights/Roles 
#######################################>
Get-VIPermission | Select Principal, Role, Entity, Propagate, UID | Export-Excel New-CL-Info.xlsx -WorkSheetName CL-Perms
Get-VIRole | Select Name, Description | Export-Excel New-CL-Info.xlsx -WorkSheetName CL-Roles


<######################################
 Get DRS, EVC & Group / Rule Info
#######################################>
Get-Cluster | Select Name, HAEnabled, HAAdmissionControlEnabled, HAFailoverLevel, HARestartPriority, HAIsolationResponse, VMSwapfilePolicy, DrsEnabled, DrsMode, DrsAutomationLevel, EVCMode | Export-Excel New-CL-Info.xlsx -WorkSheetName Cl-inf
Get-DrsClusterGroup -Cluster "UCS Cluster" | Export-Excel New-CL-Info.xlsx -WorkSheetName DrsClusterGroup
Get-DrsVMHostRule -Cluster "UCS Cluster" | Export-Excel New-CL-Info.xlsx -WorkSheetName DrsVMHostRule
Get-Cluster "UCS Cluster" | Get-DrsRule | select Name, KeepTogether, Enabled, Type, @{N="VMnames";E={ $_.Vmids|%{(get-view -id $_).name} } } | Export-Excel New-CL-Info.xlsx -WorkSheetName Get-Cl-DRS



<######################################
 Get Resource Pool Info and membership 
#######################################>
Get-ResourcePool
get-vm -Location "CECPCT" | Select Name | Export-Excel New-CL-Info.xlsx -WorkSheetName resCECPCT #| Out-file C:\Downloads\VmsByPool.txt
get-vm -Location "CICT" | Select Name  | Export-Excel New-CL-Info.xlsx -WorkSheetName resCICT #| Out-file C:\Downloads\VmsByPool.txt
get-vm -Location "ECNT" | Select Name  | Export-Excel New-CL-Info.xlsx -WorkSheetName resECNT #| Out-file C:\Downloads\VmsByPool.txt
get-vm -Location "ECPCTWG" | Select Name  | Export-Excel New-CL-Info.xlsx -WorkSheetName resECPCTWG #| Out-file C:\Downloads\VmsByPool.txt
get-vm -Location "WCCG BI" | Select Name  | Export-Excel New-CL-Info.xlsx -WorkSheetName resWCCGBI #| Out-file C:\Downloads\VmsByPool.txt
get-vm -Location "WCPCT" | Select Name  | Export-Excel New-CL-Info.xlsx -WorkSheetName resWCPCT #| Out-file C:\Downloads\VmsByPool.txt




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
    $report | Export-Excel New-CL-Info.xlsx -WorkSheetName Vms



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

Get-Folder | Get-FolderPath | Export-Excel New-CL-Info.xlsx -WorkSheetName Folders
Get-VM | Select-Object Name, FolderId, Folder, ResourcePoolId, ResourcePool | Export-Excel New-CL-Info.xlsx -WorkSheetName vm-folders
