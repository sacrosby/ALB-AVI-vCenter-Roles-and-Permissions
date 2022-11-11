# =========================================================================================================
# Automated vSphere preconfiguration for NSX ALB/Avi Load Balancer installation. 
# This simplifies the vCenter instructions provided here: 
# https://avinetworks.com/docs/22.1/roles-and-permissions-for-vcenter-nsx-t-users/#vCenter
# Created by Seth Crosby 
# =========================================================================================================
# Prior to running this script, please create the local vCenter service account ($vcUser) 
# under vSphere.local--This script does not create the account because of limitations of PowerCLI. 
# =========================================================================================================


$vcRole1 = "AviRole-Global"
$vcRole2 = "AviRole-Folder"
$vcRolePermFile1 = "AviRole-Global-role-ids.txt"
$vcRolePermFile2 = "AviRole-Folder-role-ids.txt"
$vcUser = "avisvcacct"
$domain = "vsphere.local"
$viserver = "vcsa.lab.vcrosby.com"
$AviSEFolderName = "Avi-SE-VM's"

Connect-VIServer -server $viServer -user "administrator@vsphere.local"

# Create the vCenter Role for the Avi Service Account as pertains to the global environment
$vcRoleIds1 = @()
Get-Content $vcRolePermFile1 | Foreach-Object{
    $vcRoleIds1 += $_
}
New-VIRole -name $vcRole1 -Privilege (Get-VIPrivilege -Server $viserver -Id $vcRoleIds1) -Server $viserver
Set-VIRole -Role $vcRole1 -AddPrivilege (Get-VIPrivilege -Server $viserver -Id $vcRoleIds1) -Server $viserver

# Create the vCenter Role for the Avi Service Account as pertains to the Service Engine folder
$vcRoleIds2 = @()
Get-Content $vcRolePermFile2 | Foreach-Object{
    $vcRoleIds2 += $_
}
New-VIRole -name $vcRole2 -Privilege (Get-VIPrivilege -Server $viserver -id $vcRoleIds2) -Server $viserver
Set-VIRole -Role $vcRole2 -AddPrivilege (Get-VIPrivilege -Server $viserver -id $vcRoleIds2) -Server $viserver

#Assign the Role to the service account
$rootFolder = Get-Folder -NoRecursion
New-VIPermission -Entity $rootFolder -Principal $domain\$vcUser -Role $vcRole1 -Propagate:$true

#Create the folder & Assign Permission for user to the folder using the new role
New-Folder -Name $AviSEFolderName -Location 'vm' | New-VIPermission -Principal $domain\$vcUser -Role $vcRole2