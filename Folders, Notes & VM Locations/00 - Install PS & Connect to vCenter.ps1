
#Install PowerShell 7
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"

#Install VMware PowerCLI
Install-Module -Name VMware.PowerCLI -Scope CurrentUser

#Install Import-Excel
Install-Module -Name ImportExcel -Scope CurrentUser
Import-Module -Name ImportExcel

#---------------------------------------------------------------------------------------------------------------------

# Connect to your vCenter server
Connect-VIServer -Server "vcsa-01.ucslab.local"

# Disconnect from vCenter
Disconnect-VIServer
