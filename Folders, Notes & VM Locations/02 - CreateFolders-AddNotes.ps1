
# Define the path to your Excel spreadsheet
$excelFilePath = "C:\Users\ucs-admin\Desktop\vc-Folders.xlsx"

<######################################
 Add Folders to vCenter (from Excel Sheet)
#######################################>

# Import the folder information from the Excel file
$folderInfo = Import-Excel -Path $excelFilePath -WorksheetName "Folder-List"

# Create folders in vCenter based on the imported information
foreach ($item in $folderInfo) {
    $folderName = $item."Folder Name"
    $parentFolderName = $item."Parent Folder"

    $parentFolder = if ($parentFolderName -eq "Root") { $null } else { Get-Folder -Name $parentFolderName }

    New-Folder -Name $folderName -Location $parentFolder
    Write-Host "Folder '$folderName' created in '$parentFolderName'." -ForegroundColor Green -BackgroundColor Black
}


<######################################
 Add Notes to VMs (from Excel Sheet)
#######################################>

# Import data from the Excel spreadsheet
$data = Import-Excel -Path $excelFilePath -WorksheetName "VM-Notes"

# Loop through the data and add notes to virtual machines
foreach ($row in $data) {
    $vmName = $row.'VM Name'
    $note = $row.'Notes'

    $VM = Get-VM -Name $vmName

    if ($VM) {
        # Set the note for the VM
        Set-VM -VM $VM -Notes $note -Confirm:$false
        Write-Host "Added note to $vmName" -ForegroundColor Green -BackgroundColor Black
    } else {
        Write-Host "VM not found: $vmName" -ForegroundColor DarkMagenta -BackgroundColor Black
    }
}
