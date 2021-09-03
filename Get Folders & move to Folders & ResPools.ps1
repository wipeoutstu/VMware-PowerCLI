<#####################################################################
Move Vm's to a Vm folder based on the FolderId value of the folder
    csv headers
    vmname,folderid
<####################################################################>
$vmlist = import-csv vm_placement.csv

$vmlist | % {
$folder = Get-Folder -id $vmlist.folderid
}

Move-VM -VM $vmlist.vmname -destination $folder

<#####################################################################
 Move Vm's to a Resource Pool based on the ResourcePool Name
    Excel headers
        VM,ResPool
<####################################################################>
$Pools = Import-Excel -Path C:\Downloads\Tenet.xlsx -WorkSheetName ResPools
ForEach ($Pools in $Pools) {
    $VM = $Pools.VM
    $ResPool = $Pools.ResPool

    Move-VM -VM $VM -Destination $ResPool
}

Get-folder -type VM | Foreach {($_ | .\Get-FolderPath.ps1).Path | Out-file C:\Downloads\Folders.txt -Append}

<#####################################################################
Get Folder and ResourcePool Names and ID's
<####################################################################>
function Get-VMFolderPath
{
param(
[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
[string]$folderid,
[switch]$moref
)
 
    $folderparent=get-view $folderid
    if ($folderparent.name -ne 'vm'){
        if($moref){$path=$folderparent.moref.toString()+'\'+$path}
            else{
                $path=$folderparent.name+'\'+$path
            }
        if ($folderparent.parent){
            if($moref){get-vmfolderpath $folderparent.parent.tostring() -moref}
              else{
                get-vmfolderpath($folderparent.parent.tostring())
              }
        }
    }else {
    if ($moref){
    return (get-view $folderparent.parent).moref.tostring()+"\"+$folderparent.moref.tostring()+"\"+$path
    }else {
            return (get-view $folderparent.parent).name.toString()+'\'+$folderparent.name.toString()+'\'+$path
            }
    }
}
cls


$swfol = Import-Excel -Path C:\Downloads\VMs.xlsx -WorkSheetName Sheet1
ForEach ($swfol in $swfol) {
    $VM = $swfol.Name
    
    get-vm $VM | get-vmfolderpath | Out-file C:\Downloads\Folders.txt -Append

}

<#####################################################################
List all Folders in a Datacenter
<####################################################################>
function Get-FolderPath{
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
			$row = "" | Select Name,Path,Type
			$row.Name = $_.Name
			$row.Path = $path
			$row.Type = $fldType
			$row
		}
	}
}

Get-folder -type VM | Foreach {($_ | Get-FolderPath).Path | Out-file C:\Downloads\OldVC-Folders.txt -Append}



<#####################################################################
Get Folder and ResourcePool Names and ID's
<####################################################################>


#Get-VM | Select-Object Name | Export-Excel VMs.xlsx
#Get-VM | Select-Object Name, FolderId, Folder, ResourcePoolId, ResourcePool | Export-Excel VM.xlsx


#Get-folder -type VM | Foreach {($_ | .\Get-FolderPath.ps1).Path | Out-file C:\Downloads\Folders.txt -Append}

#get-vm ‘vm123’ | get-vmfolderpath

#Get-VMfolderPath (get-vm vm1).folderid

#Get-VMfolderPath (get-vm vm1).folderid -moref

#get-vm ‘vm123’ |Get-VMfolderPath -moref





