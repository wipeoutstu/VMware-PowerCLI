

Connect-ViServer 10.20.20.20

$sPGs = Import-Excel -Path "C:\Users\ucs-admin\Downloads\vSphere Config Workbook.xlsx" -WorkSheetName "SPort Groups"
ForEach ($sPG in $sPGs) {
    $HostName = $sPG.Hostname
    $sVSName = $sPG.sVSName
    $sPGName = $sPG.sPGName
    $sPGVlan = $sPG.sPGVlan

Get-VirtualSwitch -VMHost $HostName -Name $sVSName | New-VirtualPortgroup -Name $sPGName -VlanID $sPGVlan
}

DisConnect-ViServer -Confirm:$false
