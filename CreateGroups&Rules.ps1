<#
##########################################
 Create DRS Groups & VM Rules / Host Rules
##########################################
#>
$ClusterName = "EU Production Cluster"

#
#
New-DrsClusterGroup -Name EUEXMB01 -Cluster $ClusterName -VM EUEXMB01-Exchange_BE
New-DrsClusterGroup -Name EUEXMB02 -Cluster $ClusterName -VM EUEXMB02-Exchange_BE
New-DrsClusterGroup -Name EUEXCH01 -Cluster $ClusterName -VM EUEXCH01-Exchange_FE
New-DrsClusterGroup -Name EUEXCH02 -Cluster $ClusterName -VM EUEXCH02-Exchange_FE

New-DrsClusterGroup -Name VMAESX1 -Cluster $ClusterName -VMHost VMAESX1
New-DrsClusterGroup -Name VMAESX2 -Cluster $ClusterName -VMHost VMAESX2
New-DrsClusterGroup -Name VMAESX3 -Cluster $ClusterName -VMHost VMAESX3
New-DrsClusterGroup -Name VMAESX4 -Cluster $ClusterName -VMHost VMAESX4

New-DrsClusterGroup -Name SOC_POC_VMs -Cluster $ClusterName -VM PROLIFICS-PC01, TENABLE, UTILITYSOC, NETWITNESS

#
#
New-DrsVMHostRule -Name "VMAESX1 must run on ESX1" -Cluster $ClusterName -VMGroup VMAESX1 -VMHostGroup ESX1 -Type ShouldRunOn
New-DrsVMHostRule -Name "VMAESX2 must run on ESX2" -Cluster $ClusterName -VMGroup VMAESX2 -VMHostGroup ESX2 -Type ShouldRunOn
New-DrsVMHostRule -Name "VMAESX3 must run on ESX3" -Cluster $ClusterName -VMGroup VMAESX3 -VMHostGroup ESX3 -Type ShouldRunOn
New-DrsVMHostRule -Name "VMAESX4 must run on ESX4" -Cluster $ClusterName -VMGroup VMAESX4 -VMHostGroup ESX4 -Type ShouldRunOn
New-DrsVMHostRule -Name "EUEXMB01 should run on ESX1" -Cluster $ClusterName -VMGroup EUEXMB01 -VMHostGroup ESX1 -Type ShouldRunOn
New-DrsVMHostRule -Name "EUEXMB02 should run on ESX2" -Cluster $ClusterName -VMGroup EUEXMB02 -VMHostGroup ESX2 -Type ShouldRunOn
New-DrsVMHostRule -Name "EUEXCH01 should run on ESX3" -Cluster $ClusterName -VMGroup EUEXCH01 -VMHostGroup ESX3 -Type ShouldRunOn
New-DrsVMHostRule -Name "EUEXCH02 should run on ESX4" -Cluster $ClusterName -VMGroup EUEXCH02 -VMHostGroup ESX4 -Type ShouldRunOn

New-DrsVMHostRule -Name "SOC POC VMS must run on EUESX01" -Cluster $ClusterName -VMGroup SOC_POC_VMs -VMHostGroup ESX1 -Type MustRunOn

#
#
New-DrsRule -Name "Separate EULB01 and EULB02" -Cluster $ClusterName -KeepTogether $false -VM EULB01-Kemp_LB, EULB02-Kemp_LB
New-DrsRule -Name "Separate EUCTX1 2 & 3" -Cluster $ClusterName -KeepTogether $false -VM EUCTX1-OfficeNet_Citrix, EUCTX2-OfficeNet_Citrix, EUCTX3-OfficeNet_Citrix
New-DrsRule -Name "Separate EUWI01 and EUWI02" -Cluster $ClusterName -KeepTogether $false -VM EUWI01-Internal_Citrix_Web, EUWI02-Internal_Citrix_Web
New-DrsRule -Name "Separate DC1 and DC2" -Cluster $ClusterName -KeepTogether $false -VM DC1, DC2
New-DrsRule -Name "Separate EUEXCH01 and EUEXCH02" -Cluster $ClusterName -KeepTogether $false -VM EUEXCH01-Exchange_FE, EUEXCH02-Exchange_FE
New-DrsRule -Name "Separate CITRIX1. CITRIX2 and CITRIX3" -Cluster $ClusterName -KeepTogether $false -VM CITRIX1-ARRM, CITRIX2-ARRM, CITRIX3-ARRM, CITRIX4-ARRM
New-DrsRule -Name "Separate EUEXMB01 and EUEXMB02" -Cluster $ClusterName -KeepTogether $false -VM EUEXMB01-Exchange_BE, EUEXMB02-Exchange_BE
New-DrsRule -Name "Separate CITRIXSF1 and CITRIXSF2" -Cluster $ClusterName -KeepTogether $false -VM CITRIXSF1-StoreFront, CITRIXSF2-StoreFront
New-DrsRule -Name "Separate EXTRANETWEB1 and EXTRANETWEB2" -Cluster $ClusterName -KeepTogether $false -VM EXTRANETWEB1-Extranet, EXTRANETWEB2-Extranet
New-DrsRule -Name "Separate ADFSPROXY01 and ADFSPROXY02" -Cluster $ClusterName -KeepTogether $false -VM ADFSPROXY01-ADFS, ADFSPROXY02-ADFS
New-DrsRule -Name "Separate ADFS01 and ADFS02" -Cluster $ClusterName -KeepTogether $false -VM ADFS01-ADFS, ADFS02-ADFS