New-DrsClusterGroup -Name EUEXMB01 -Cluster "EU Production Cluster" -VM EUEXMB01-Exchange_BE
New-DrsClusterGroup -Name EUEXMB02 -Cluster "EU Production Cluster" -VM EUEXMB02-Exchange_BE
New-DrsClusterGroup -Name EUEXCH01 -Cluster "EU Production Cluster" -VM EUEXCH01-Exchange_FE
New-DrsClusterGroup -Name EUEXCH02 -Cluster "EU Production Cluster" -VM EUEXCH02-Exchange_FE

New-DrsClusterGroup -Name VMAESX1 -Cluster "EU Production Cluster" -VMHost VMAESX1
New-DrsClusterGroup -Name VMAESX2 -Cluster "EU Production Cluster" -VMHost VMAESX2
New-DrsClusterGroup -Name VMAESX3 -Cluster "EU Production Cluster" -VMHost VMAESX3
New-DrsClusterGroup -Name VMAESX4 -Cluster "EU Production Cluster" -VMHost VMAESX4

New-DrsClusterGroup -Name SOC_POC_VMs -Cluster "EU Production Cluster" -VM PROLIFICS-PC01, TENABLE, UTILITYSOC, NETWITNESS
