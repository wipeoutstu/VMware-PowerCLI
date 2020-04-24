# CREATE VSWITCH
<#  -Name vSwitch2
    -NumPorts 256
    -Nic vmnic4,vmnic5
    -Mtu 1500
#>

# SET SECURITY POLICY
<#  Switch/PG  -AllowPromiscuous $true
               -ForgedTransmits $true
               -MacChanges $true

    PG         -AllowPromiscuousInherited $true
               -ForgedTransmitsInherited $true
               -MacChangesInherited $true
#>

# SET NIC TEAMING POLICY
<#  Switch/PG  -MakeNicActive $true
               -MakeNicStandby $true
               -MakeNicUnused $true
               -NotifySwitches $true
               -FailbackEnabled $true
                    $true [the adapter is returned to active duty immediately on recovery]
                    $false [a failed adapter is left inactive even after recovery until another active adapter fails]
               -LoadBalancingPolicy LoadBalanceIP
                    LoadBalanceIP  [Route based on IP hash]
                    LoadBalanceSrcMac  [Route based on source MAC hash]
                    LoadBalanceSrcId  [Route based on the originating port ID]
                    ExplicitFailover  [Always use the highest order uplink from the list of Active adapters that passes failover detection criteria]
               -NetworkFailoverDetectionPolicy LinkStatus
                    LinkStatus
                    BeaconProbing -BeaconInterval
#>

# CREATE VMKERNEL PORT
<#  -Mac {mac address}
    -FaultToleranceLoggingEnabled:$true
    -ManagementTrafficEnabled:$true
    -VMotionEnabled:$true
#>

# CONNECT TO VCENTER
<#     Connect-VIServer {IP or FQDN} -Protocol https -User {username} -Password {password}
       Disconnect-VIServer
#>

Start-Transcript -Path "C:\PS\Transcripts\CreateVswitch.txt"

    $HostName = "192.168.33.33"
    $vMotionIP = "10.10.1.2"
    $iSCSIIP = "192.168.33.222"

    # Create vSwitch
    New-VirtualSwitch -VMHost $HostName -Name vSwitch1 -NumPorts 256 -Nic vmnic1,vmnic2 -Mtu 1500
    New-VirtualSwitch -VMHost $HostName -Name vSwitch2 -NumPorts 256 -Nic vmnic3 -Mtu 1500

    # Add vmnic to existing vSwitch
    Get-VMHost $HostName | Get-VirtualSwitch -Name vSwitch0 | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic (Get-VMhost $HostName | Get-VMHostNetworkAdapter -Physical -Name vmnic4) -Confirm:$false

    # Set vSwitch Security Policy
    Get-VirtualSwitch -VMHost $HostName -Name  vSwitch1 | Get-SecurityPolicy | Set-SecurityPolicy -ForgedTransmits $false
    Get-VirtualSwitch -VMHost $HostName -Name  vSwitch2 | Get-SecurityPolicy | Set-SecurityPolicy -ForgedTransmits $true

    # Set vSwitch NIC Teaming Policy
    Get-VirtualSwitch -VMHost $HostName -name vSwitch0 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -LoadBalancingPolicy LoadBalanceIP
    Get-VirtualSwitch -VMHost $HostName -name vSwitch1 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic1 -MakeNicStandby vmnic2 -LoadBalancingPolicy LoadBalanceIP
    Get-VirtualSwitch -VMHost $HostName -name vSwitch2 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -LoadBalancingPolicy LoadBalanceIP

    # Create Port Groups
    Get-VirtualSwitch -VMHost $HostName -Name  vSwitch1 | New-VirtualPortgroup -Name "SW-LAN" -VlanID 10
    Get-VirtualSwitch -VMHost $HostName -Name  vSwitch1 | New-VirtualPortgroup -Name "vMotion"
    Get-VirtualSwitch -VMHost $HostName -Name  vSwitch2 | New-VirtualPortgroup -Name "iSCSI"

    #Set Port Group Security Policy
    Get-VirtualPortgroup -VMHost $HostName -Name "SW-LAN" | Get-SecurityPolicy | Set-SecurityPolicy -ForgedTransmitsInherited $true
    Get-VirtualPortgroup -VMHost $HostName -Name "vMotion" | Get-SecurityPolicy | Set-SecurityPolicy -ForgedTransmitsInherited $true

    # Set Port Group Nic Teaming Policy
    Get-VirtualPortgroup -VMHost $HostName  -Name "Management Network" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic4
    Get-VirtualPortgroup -VMHost $HostName -Name "vMotion" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic1 -MakeNicUnused vmnic2 -LoadBalancingPolicy LoadBalanceIP
    Get-VirtualPortgroup -VMHost $HostName -Name "SW-LAN" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic2 -MakeNicUnused vmnic1 -LoadBalancingPolicy LoadBalanceIP

    # Create VMKernel Ports
    New-VMHostNetworkAdapter -VMHost $HostName -PortGroup "vMotion" -VirtualSwitch vSwitch1 -IP $vMotionIP -SubnetMask 255.255.255.0 -VMotionEnabled:$true
    New-VMHostNetworkAdapter -VMHost $HostName -PortGroup "iSCSI" -VirtualSwitch vSwitch2 -IP $iSCSIIP -SubnetMask 255.255.255.0 -Mtu 1500

Stop-Transcript

