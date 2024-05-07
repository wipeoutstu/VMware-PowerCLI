
# Define the path to your Excel spreadsheet
$excelFilePath = "C:\Users\ucs-admin\Desktop\vc-Folders.xlsx"

<######################################
 Move VMs to Folders (listed in Excel Sheet)
#######################################>

# Import the VM and folder information from the Excel spreadsheet
$data = Import-Excel -Path $excelFilePath -WorksheetName "VM-Folders"

# Loop through the data and move VMs to the specified folders
foreach ($row in $data) {
    $VMName = $row."VMName"
    $FolderId = $row."FolderID"

    $VM = Get-VM -Name $VMName

    if ($VM) {
        $TargetFolder = Get-Folder -Id $FolderId

        if ($TargetFolder) {
            Move-VM -VM $VM -InventoryLocation $TargetFolder
            Write-Host "VM '$VMName' has been moved to folder '$($TargetFolder.Name)'." -ForegroundColor Green -BackgroundColor Black
        } else {
            Write-Host "Target Folder with ID '$FolderId' not found." -ForegroundColor DarkMagenta -BackgroundColor Black
        }
    } else {
        Write-Host "VM with name '$VMName' not found." -ForegroundColor DarkMagenta -BackgroundColor Black
    }
}
