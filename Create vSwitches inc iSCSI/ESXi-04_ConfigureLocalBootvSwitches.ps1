#Connect-ViServer 10.20.20.25
#DisConnect-ViServer

Start-Transcript -Path "C:\PS\Transcripts\CreateVswitch-esxi-04.txt"

    $HostName = "10.20.20.24"
   
    $swVM = "svs-vmotion"
    $swIS = "svs-iSCSI"
    $swHA = "svs-vcha"
    $swLA = "svs-lan"

    $pgVM = "pg-vmotion"
    $pgISa = "pg-iSCSI-A"
    $pgISb = "pg-iSCSI-B"
    $pgHA = "pg-vcha"
    $pgLA = "pg-lan"

    $vMotionIP = "10.10.20.24"
    $vMotionvlan = "20"
    $vcHAvlan = "40"
    $Lanvlan = "50"

    $iSCSIIPA = "10.10.99.23"
    $iSCSIIPB = "10.10.99.26"
    $MTU = "1500"
    $SubnetMask = "255.255.255.0"

    $iSCSITarget = "10.10.99.1:3260"
    $HostIQN = "iqn.1998-01.com.vmware:esxi04"
    $iSCSIvlanA = "99"
    $iSCSIvlanB = "99"
    $iSCSIAvmnic = "vmnic4"
    $iSCSIBvmnic = "vmnic5"

    $vMotionvmnics = "vmnic2,vmnic3"
    $iSCSIvmnics = "vmnic4,vmnic5"
    $vcHAvmnics = "vmnic6,vmnic7"
    $Lanvmnics = "vmnic8,vmnic9"

# Create vSwitches
New-VirtualSwitch -VMHost $HostName -Name $swVM -Nic vmnic2,vmnic3 -Mtu $MTU
New-VirtualSwitch -VMHost $HostName -Name $swIS -Nic vmnic4,vmnic5 -Mtu $MTU
New-VirtualSwitch -VMHost $HostName -Name $swHA -Nic vmnic6,vmnic7 -Mtu $MTU
New-VirtualSwitch -VMHost $HostName -Name $swLA -Nic vmnic8,vmnic9 -Mtu $MTU

# Create Port Groups
Get-VirtualSwitch -VMHost $HostName -Name  $swVM | New-VirtualPortgroup -Name $pgVM -VlanID $vMotionvlan
Get-VirtualSwitch -VMHost $HostName -Name  $swHA | New-VirtualPortgroup -Name $pgHA -VlanID $vcHAvlan
Get-VirtualSwitch -VMHost $HostName -Name  $swLA | New-VirtualPortgroup -Name $pgLA -VlanID $Lanvlan

    # Create iSCSI Port Groups
    Get-VirtualSwitch -VMHost $HostName -Name  $swIS | New-VirtualPortgroup -Name $pgISa -VlanID $iSCSIvlanA
    Get-VirtualSwitch -VMHost $HostName -Name  $swIS | New-VirtualPortgroup -Name $pgISb -VlanID $iSCSIvlanB

    # Set iSCSI Port Group Nic Teaming Policy
    Get-VirtualPortgroup -VMHost $HostName -Name $pgISa | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $iSCSIAvmnic -MakeNicUnused $iSCSIBvmnic -LoadBalancingPolicy LoadBalanceIP
    Get-VirtualPortgroup -VMHost $HostName -Name $pgISb | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $iSCSIBvmnic -MakeNicUnused $iSCSIAvmnic -LoadBalancingPolicy LoadBalanceIP

    # Create iSCSI VMKernel Ports
    New-VMHostNetworkAdapter -VMHost $HostName -PortGroup $pgISa -VirtualSwitch $swIS -IP $iSCSIIPA -SubnetMask $SubnetMask -Mtu $MTU
    New-VMHostNetworkAdapter -VMHost $HostName -PortGroup $pgISb -VirtualSwitch $swIS -IP $iSCSIIPB -SubnetMask $SubnetMask -Mtu $MTU

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
New-VMHostNetworkAdapter -VMHost $HostName -PortGroup $pgVM -VirtualSwitch $swVM -IP $vMotionIP -SubnetMask $SubnetMask -VMotionEnabled:$true

Stop-Transcript
