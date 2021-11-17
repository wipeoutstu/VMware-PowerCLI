#Import & Configure VMs

Start-Transcript -Path "C:\Downloads\PS-Transcripts\Transcript-RegisterVMs.txt"

$VMs = Import-Excel -Path C:\Downloads\ImportVMs.xlsx -WorkSheetName Import
ForEach ($VM in $VMs) {
    $HostName = $VM.vmname
    $vmxPath = $VM.vmpath
    $Folder = $VM.vmfolder
    $pG = $VM.pg

New-VM -VMFilePath $vmxPath -ResourcePool "UCS Cluster" -Location (Get-Folder $Folder)
#Get-VM -name $HostName | Get-NetworkAdapter | Set-NetworkAdapter -Type Vmxnet3  -NetworkName $pG -Confirm:$false -RunAsync
Get-VM -name $HostName | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $pG -Confirm:$false -RunAsync
}    
Stop-Transcript
