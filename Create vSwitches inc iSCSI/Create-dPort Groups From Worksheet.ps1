
Connect-ViServer 10.20.20.20

$dPGs = Import-Excel -Path "C:\Users\ucs-admin\Downloads\vSphere Config Workbook.xlsx" -WorkSheetName "DPort Groups"
ForEach ($dPG in $dPGs) {
    $DvSName = $dPG.dVSName
    $dPGName = $dPG.dPGName
    $dPGPorts = $dPG.dPGPorts
    $dPGVlan = $dPG.dPGVlan

Get-VDSwitch -Name $DvSName | New-VDPortgroup -Name $dPGName -NumPorts $dPGPorts -VLanId $dPGVlan -Confirm:$false
}

DisConnect-ViServer -Confirm:$false
