
# Specify the path for the Excel file
$excelFilePath = "C:\Users\ucs-admin\Desktop\vc-Folders.xlsx"


<######################################
 List VM's & Folder Info
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

Get-Folder | Get-FolderPath | Export-Excel -Path $excelFilePath -WorksheetName "Folder-Info" -AutoSize
Write-Host "Folder Info Exported to Excel Worksheet" -ForegroundColor Green -BackgroundColor Black

Get-VM | Select-Object Name, FolderId, Folder, ResourcePoolId, ResourcePool | Export-Excel -Path $excelFilePath -WorksheetName "VM-Info" -AutoSize
Write-Host "VM Info Exported to Excel Worksheet" -ForegroundColor Green -BackgroundColor Black

Get-VM | Export-Excel -Path $excelFilePath -WorksheetName "VM-Info-All" -AutoSize
Write-Host "VM Info (All) Exported to Excel Worksheet" -ForegroundColor Green -BackgroundColor Black

<######################################
 List VM Notes
#######################################>
# Create an array to store VM notes information
$vmNotesInfo = @()

# Get all virtual machines
$VMs = Get-VM

# Iterate through VMs and gather notes information
foreach ($VM in $VMs) {
    $vmNotesInfo += [PSCustomObject]@{
        'VM Name' = $VM.Name
        'Notes' = $VM.Notes
    }
}

# Export the VM notes information to an Excel spreadsheet
$vmNotesInfo | Export-Excel -Path $excelFilePath -WorksheetName "VM-Notes" -AutoSize
Write-Host "VM Notes information exported to $excelFilePath" -ForegroundColor Green -BackgroundColor Black


<######################################
 List VMs and Folder Paths
#######################################>

# Create a function to find the folder path for a given folder ID
Function Find-FolderPath {
    param (
        [string] $folderId
    )

    # Retrieve a list of all folders
    $allFolders = Get-Folder

    # Iterate through the folders and find the one with a matching ID
    foreach ($folder in $allFolders) {
        if ($folder.ExtensionData.MoRef.Value -eq $folderId) {
            $folderPath = $folder.Name

            # Traverse the folder hierarchy to build the full folder path
            $parentFolder = $folder.Parent
            while ($parentFolder -ne $null) {
                $folderPath = "$($parentFolder.Name)\$folderPath"
                $parentFolder = $parentFolder.Parent
            }

            return $folderPath
        }
    }
    return $null
}

# Get all virtual machines
$VMs = Get-VM

# Create an array to store VM information
$vmInfo = @()
group-
# Iterate through VMs and list their names, folder IDs, and folder paths
foreach ($VM in $VMs) {
    $textToRemove = "\vm"
    $textToAdd = "Folder-"
    
    $folderId = $VM.Folder.ExtensionData.MoRef.Value
    $folderPath = Find-FolderPath -folderId $folderId
    $RealfolderPath = $folderPath.Replace($textToRemove, "")
    $RealfolderId = $textToAdd + $folderId

    if ($folderPath) {
        $vmInfo += [PSCustomObject]@{
            'VMName' = $VM.Name
            'FolderID' = $RealfolderId
            'FolderPath' = $RealfolderPath
        }
    } else {
        $vmInfo += [PSCustomObject]@{
            'VMName' = $VM.Name
            'FolderID' = $RealfolderId
            'FolderPath' = 'Folder not found'
        }
    }
}

# Export the VM information to an Excel spreadsheet
$vmInfo | Export-Excel -Path $excelFilePath -WorksheetName "VM-Folders" -AutoSize
Write-Host "VM Folder Paths Exported to Excel Worksheet" -ForegroundColor Green -BackgroundColor Black

<######################################
 List vCenter Folder Paths
#######################################>

# Get a list of all folders
$folders = Get-Folder

# Create an array to store folder information
$folderInfo = @()

# Iterate through the folders and add them to the array
foreach ($folder in $folders) {
    $folderInfo += [PSCustomObject]@{
        'Folder Name' = $folder.Name
        'Parent Folder' = if ($folder.Parent -eq $null) { "Root" } else { $folder.Parent.Name }
    }
}

# Export the folder information to a Excel file
$folderInfo | Export-Excel -Path $excelFilePath -WorksheetName "Folder-List" -AutoSize
Write-Host "vCenter Folder Paths Exported to Excel Worksheet" -ForegroundColor Green -BackgroundColor Black
