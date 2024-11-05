#Connect-ViServer 10.20.20.25
#DisConnect-ViServer

Start-Transcript -Path "C:\PS\Transcripts\CreateVswitch-290722.txt"

    $HostName = "10.20.20.26"
   
    $vMotionIP = "10.10.20.26"
    $vMotionvlan = "20"
    $vcHAvlan = "40"
    $Lanvlan = "50"

    $iSCSIIPA = "10.10.99.19"
    $iSCSIIPB = "10.10.99.22"
    $MTU = "1500"
    $SubnetMask = "255.255.255.0"

    $iSCSITarget = "10.10.99.2:3260"
    $HostIQN = "iqn.1998-01.com.vmware:esxi-05"
    $iSCSIvlanA = "99"
    $iSCSIvlanB = "99"
    $iSCSIAvmnic = "vmnic4"
    $iSCSIBvmnic = "vmnic5"

    $vMotionvmnics = "vmnic2,vmnic3"
    $iSCSIvmnics = "vmnic4,vmnic5"
    $vcHAvmnics = "vmnic6,vmnic7"
    $Lanvmnics = "vmnic8,vmnic9"

# Create vSwitches
New-VirtualSwitch -VMHost $HostName -Name vMotion -Nic vmnic2,vmnic3 -Mtu $MTU
New-VirtualSwitch -VMHost $HostName -Name iSCSI -Nic vmnic4,vmnic5 -Mtu $MTU
New-VirtualSwitch -VMHost $HostName -Name vcHA -Nic vmnic6,vmnic7 -Mtu $MTU
New-VirtualSwitch -VMHost $HostName -Name Lan -Nic vmnic8,vmnic9 -Mtu $MTU

# Create Port Groups
Get-VirtualSwitch -VMHost $HostName -Name  vMotion | New-VirtualPortgroup -Name "vMotion" -VlanID $vMotionvlan
Get-VirtualSwitch -VMHost $HostName -Name  vcHA | New-VirtualPortgroup -Name "vcHA" -VlanID $vcHAvlan
Get-VirtualSwitch -VMHost $HostName -Name  Lan | New-VirtualPortgroup -Name "Lan" -VlanID $Lanvlan

    # Create iSCSI Port Groups
    Get-VirtualSwitch -VMHost $HostName -Name  iSCSI | New-VirtualPortgroup -Name "iSCSI-A" -VlanID $iSCSIvlanA
    Get-VirtualSwitch -VMHost $HostName -Name  iSCSI | New-VirtualPortgroup -Name "iSCSI-B" -VlanID $iSCSIvlanB

    # Set iSCSI Port Group Nic Teaming Policy
    Get-VirtualPortgroup -VMHost $HostName -Name "iSCSI-A" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $iSCSIAvmnic -MakeNicUnused $iSCSIBvmnic -LoadBalancingPolicy LoadBalanceIP
    Get-VirtualPortgroup -VMHost $HostName -Name "iSCSI-B" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $iSCSIBvmnic -MakeNicUnused $iSCSIAvmnic -LoadBalancingPolicy LoadBalanceIP

    # Create iSCSI VMKernel Ports
    New-VMHostNetworkAdapter -VMHost $HostName -PortGroup "iSCSI-A" -VirtualSwitch iSCSI -IP $iSCSIIPA -SubnetMask $SubnetMask -Mtu $MTU
    New-VMHostNetworkAdapter -VMHost $HostName -PortGroup "iSCSI-B" -VirtualSwitch iSCSI -IP $iSCSIIPB -SubnetMask $SubnetMask -Mtu $MTU

    #Enable software iSCSI Adapter & set host IQN
    Get-VMHostStorage -VMHost $HostName | Set-VMHostStorage -SoftwareIScsiEnabled $True
    Get-VMHostHba -Type iSCSI | Set-VMHostHba -IScsiName $HostIQN

    #Rescan Hba & retrieve software iSCSI vhba info
    Get-VMHostStorage -VMHost $HostName -RescanAllHba
    $iSCSI_A = Get-VMHostNetworkAdapter | Where {$_.IP -eq $iSCSIIPA}
    $iSCSI_B = Get-VMHostNetworkAdapter | Where {$_.IP -eq $iSCSIIPB}
    $arrVMK = @("$iSCSI_A", "$iSCSI_B")
    $Adapter = Get-VMHostHba -Type iScsi | Where { $_.Model -eq "iSCSI Software Adapter" }  | foreach { $_.Device }
    
    #Bind the iSCSI VMKernel Adapters to the Software iSCSI Adapter
    For ($i=0; $i -lt $arrVMK.Length; $i++) 
    {
        $esxcli = Get-EsxCli -V2
        $bind = @{
            adapter =$Adapter
            force = $true
            nic = $arrVMK[$i]
        }
        $esxcli.iscsi.networkportal.add.Invoke($bind)
    }

    #Add Dynamic Discovery Target & Rescan Hba
    Get-VMHostHba vmhba64 | New-IScsiHbaTarget -Address $iSCSITarget
    Get-VMHostStorage -VMHost $HostName -RescanAllHba


# Create vMotion VMKernel Port
New-VMHostNetworkAdapter -VMHost $HostName -PortGroup "vMotion" -VirtualSwitch "vMotion" -IP $vMotionIP -SubnetMask $SubnetMask -VMotionEnabled:$true

Stop-Transcript
