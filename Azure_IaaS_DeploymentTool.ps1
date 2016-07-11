﻿
<# 
.SYNOPSIS 
This script provides the following functionality for deploying IaaS environments in Azure. The script will deploy VNET in addition to numerour Market Place VMs or make use of an existing VNET.
Market Images supported: Redhat 6.7 and 7.2, PFSense 2.5, Windows 2008 R2, Windows 2012 R2, Ubuntu 14.04, CentOs 7.2, SUSE, SQL 2016 (on W2K12R2), R Server on Windows, Windows 2016 (Preview), Checkpoint Firewall,
.PARAMETERS
VMName is a required parameter at runtime. All other parameters are optional at runtime.
To deploy a VM to an existing VNET set the -NewVnet parameter to false. ** Update the -VNETResourceGroupName variable before running the script.
To deploy a new VNET with multiple subnets set the -NewVnet flag to true. ** The New VNET Will be deployed to -vNetResourceGroupName.
To deploy a Network Security Group to the VNET use the -NSGEnabled (True) and -NSGName (name of the NSG group) to create an NSG for the provisioned VNET.
To deploy a specific market image, enter one of the following names for -vmmMarketImage: Red67 Red72 Check PFSecure W2k12r2 w2k8r2 centos ubuntu chef SUSE SQL2K16 RSERVER
.SYNTAX
Required Parameters defined at Runtime
Azure_IaaS_Deploy.ps1 -vmname
Required Parameters defined in script
Azure_IaaS_Deploy.ps1 -vmname -VMMarketImage -ResourceGroupName -VNETName -VNETResourceGroupName -Location -SubscriberID -StorageType -StorageName -TenantID -InterfaceName1 -IntrerfaceName2 -NSGEnabled -VMSize -locadmin -locpassword 
Optional Parameters
Azure_IaaS_Deploy.ps1 -vmname -VMMarketImage -ResourceGroupName -VNETName -VNETResourceGroupName -NewVNet -NSGEnabled -NSGName
Azure_IaaS_Deploy.ps1 -vmname -VMMarketImage -ResourceGroupName -VNETName -VNETResourceGroupName -ExtMSAV
Azure_IaaS_Deploy.ps1 -vmname -VMMarketImage -ResourceGroupName -VNETName -VNETResourceGroupName -ExtVMAccess
.EXAMPLES
Deployment runtime positional parameters examples:

\.Azure_IaaS_Deploy.ps1 red01 red67 -ResourceGroupName RedRG -vNetResourceGroupName RedRG -VNetName vNet -depsub1 3 -AvailabilitySet "True" -AvailSetName "10" -NoPublicIP "True"
\.Azure_IaaS_Deploy.ps1 win01 w2k16 -ResourceGroupName WinRG -vNetResourceGroupName WinRG -VNetName vNet -depsub1 4 -NoPublicIP "True"
\.Azure_IaaS_Deploy.ps1 pfs01 Pfsense -ResourceGroupName PFRG -vNetResourceGroupName PFRG -VNetName vNet -depsub1 1 -depsub2 2 -NewVnet True -NSGEnabled True
#> 
##Setting Global Paramaters##

[CmdletBinding()]
Param( 
 [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true,Position=1)]
 [string]
 $vmMarketImage = "PfSense",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $NewVnet = "False",

 [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true,Position=0)]
 [string]
 $VMName = "pfsens01",

 [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true,Position=2)]
 [string]
 $ResourceGroupName = "ResGrp",

 [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $vNetResourceGroupName = $ResourceGroupName,

 [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true,Position=3)]
 [string]
 $VNetName = "vnet",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $VMSize = "Standard_A3",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $locadmin = 'localadmin',

 [Parameter(Mandatory=$False)]
 [string]
 $locpassword = 'PassW0rd!@1',

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $NSGEnabled = "False",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $Location = "WestUs",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $SubscriptionID = '',

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $TenantID = '',

  [Parameter(Mandatory=$False)]
 [string]
 $GenerateName = -join ((65..90) + (97..122) | Get-Random -Count 6 | % {[char]$_}) + "aip",
 
 [Parameter(Mandatory=$False)]
 [string]
 $StorageName = $GenerateName + "str",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $StorageType = "Standard_GRS",

 [Parameter(Mandatory=$False)]
 [string]
 $InterfaceName1 = $GenerateName + "nic1",

 [Parameter(Mandatory=$False)]
 [string]
 $InterfaceName2 = $GenerateName + "nic2",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $NSGName = "NSG",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $ExtMSAV = "False",
 
 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $ExtVMAccess = "False",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $ExtAzureDiag = "False",
 
 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $ExtCustScript = "False",

 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [Int]
 $DepSub1 = 1,
 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [Int]
 $DepSub2 = 2,
 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $NoPublicIP = "False",
 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $AvailabilitySet = "False",
 [Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
 [string]
 $AvailSetName = "AVSET4",
 [Parameter(Mandatory = $false)]
 [PSObject] 
 $provisionvm,
 [Parameter(Mandatory = $false)]
 [PSObject[]]
 $ProvisionVMs
)
# Global
$ErrorActionPreference = "Stop"
$date = Get-Date -UFormat "%Y-%m-%d-%H-%M"
$workfolder = "c:\Temp\"
$logFile = $workfolder+'\'+$vmname+'-'+$date+'.log'
$SecureLocPassword=Convertto-SecureString $locpassword –asplaintext -force
$Credential1 = New-Object System.Management.Automation.PSCredential ($locadmin,$SecureLocPassword)


# Fuctions
Function WriteLog-Command([string]$Description, [ScriptBlock]$Command, [string]$LogFile, [string]$VMName ){
Try{
$Output = $Description+'  ... '
Write-Host $Output -ForegroundColor Blue
((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
$Result = Invoke-Command -ScriptBlock $Command 
}
Catch {
$ErrorMessage = $_.Exception.Message
$Output = 'Error '+$ErrorMessage
((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
$Result = ""
}
Finally
{
if ($ErrorMessage -eq $null) {$Output = "[Completed]  $Description  ... "} else {$Output = "[Failed]  $Description  ... "}
((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force

}
Return $Result


}
Function RegisterRP {
	Param(
		[string]$ResourceProviderNamespace
	)

	Write-Host "Registering resource provider '$ResourceProviderNamespace'";
	Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace -Force;
}
Function LogintoAzure(){
		$Error_WrongCredentials = $True
		$AzureAccount = $null

		while ($Error_WrongCredentials) {

	Try {
		Write-Host "Info : Please, Enter the credentials of an Admin account of Azure" -ForegroundColor Cyan
		#$AzureCredentials = Get-Credential -Message "Please, Enter the credentials of an Admin account of your subscription"      
		$AzureAccount = Add-AzureRmAccount

		if ($AzureAccount -eq $null) 
				  {
				   $Error_WrongCredentials = $True
				   $Output = " Warning : The Credentials for [" + $AzureAccount +"] are not valid or the user does not have Azure subscriptions "
				   Write-Host $Output -BackgroundColor Black -ForegroundColor Yellow
				   } 
				 else
				  {$Error_WrongCredentials = $false ; return $AzureAccount}
		}

	Catch {
		$Output = " Warning : The Credentials for [" + $AzureAccount.Context.Account.id +"] are not valid or the user does not have Azure subscriptions "
		Write-Host $Output -BackgroundColor Black -ForegroundColor Yellow
		Generate-LogVerbose -Output $logFile -Message  $Output 
		}

	Finally {
				
			}

}
		return $AzureAccount

		}
Function ProvisionRGs {
	Param(
		[string]$ResourceGroupName
	)
	$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
	Write-Host "Resource group '$ResourceGroupName' does not exist. To create a new resource group, please enter a location.";
	if(!$Location) {
		$Location = Read-Host "resourceGroupLocation";
	}
	$Description = "Creating resource group $resourceGroupName in location $Location";
	$Command = {New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location}
	WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
}
else{
	$Description = "Using existing resource group $ResourceGroupName";
	$Command = {Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue}
	WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
}

}
Function ProvisionNet {
## Create Virtual Network
$Description = {"Network Preparation in Process"}
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix 10.51.0.0/24 -Name perimeter
$subnet2 = New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix 10.51.1.0/24 -Name web
$subnet3 = New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix 10.51.2.0/24 -Name intake
$subnet4 = New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix 10.51.3.0/24 -Name data
$subnet5 = New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix 10.51.4.0/24 -Name monitoring
$subnet6 = New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix 10.51.5.0/24 -Name analytics
$subnet7 = New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix 10.51.6.0/24 -Name backup
$subnet8 = New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix 10.51.7.0/24 -Name management
New-AzureRmVirtualNetwork -Location WestUS -Name $VNetName -ResourceGroupName $vNetResourceGroupName -AddressPrefix '10.51.0.0/21' -Subnet $subnet1,$subnet2,$subnet3,$subnet4,$subnet5,$subnet6,$subnet7,$subnet8 -Force;
$Command = {Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Get-AzureRmVirtualNetworkSubnetConfig | ft "Name" }
$Description = "Completed deployment of new VNET $VNetName"
WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
}


Function CreateNSG {
$httprule = New-AzureRmNetworkSecurityRuleConfig -Name "FrontEnd_HTTP" -Description "HTTP Exception for Web frontends" -Protocol Tcp -SourcePortRange "80" -DestinationPortRange "80" -SourceAddressPrefix "*" -DestinationAddressPrefix "10.51.0.0/21" -Access Allow -Direction Inbound -Priority 200
$httpsrule = New-AzureRmNetworkSecurityRuleConfig -Name "FrontEnd_HTTPS" -Description "HTTPS Exception for Web frontends" -Protocol Tcp -SourcePortRange "443" -DestinationPortRange "443" -SourceAddressPrefix "*" -DestinationAddressPrefix "10.51.0.0/21" -Access Allow -Direction Inbound -Priority 201
$sshrule = New-AzureRmNetworkSecurityRuleConfig -Name "FrontEnd_SSH" -Description "SSH Exception for Web frontends" -Protocol Tcp -SourcePortRange "22" -DestinationPortRange "22" -SourceAddressPrefix "*" -DestinationAddressPrefix "10.51.0.0/21" -Access Allow -Direction Inbound ` -Priority 203
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $vNetResourceGroupName -Location "West US" -Name $NSGName -SecurityRules $httprule,$httpsrule, $sshrule -force
$Description = "Completed deployment of NSG Configuration $NSGName"
$Command = {Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $vNetResourceGroupName}
WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
}
Function SubnetMatch {
	Param(
		[INT]$Subnet
	)
switch ($Subnet)
{
1 {Write-Host "Deployed to Perimeter Subnet 10.51.0.0/24"}
2 {Write-Host "Deployed to Web Subnet 10.51.1.0/24"}
3 {Write-Host "Deployed to Intake Subnet 10.51.2.0/24"}
4 {Write-Host "Deployed to data Subnet 10.51.3.0/24"}
5 {Write-Host "Deployed to Monitoring Subnet 10.51.4.0/24"}
6 {Write-Host "Deployed to analytics Subnet 10.51.5.0/24"}
7 {Write-Host "Deployed to backup Subnet 10.51.6.0/24"}
8 {Write-Host "Deployed to management Subnet 10.51.7.0/24"}
default {No Subnet Found}
}
}
Function Select-Subscription ($SubscriptionID, $TenantID)
		{
		Set-AzureRmContext -tenantid $TenantID -subscriptionid $SubscriptionID
		}


##Login to Azure##
$Description = "Connecting to Azure"
$Command = {LogintoAzure}
$AzureAccount = WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
# Select-Subscription
# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.network","microsoft.storage");
if($resourceProviders.length) {
	Write-Host "Registering resource providers"
	foreach($resourceProvider in $resourceProviders) {
		RegisterRP($resourceProvider);
	}
}
Write-Output "Steps will be tracked on the log file : [ $logFile ]"

# Create Resource Groups
$resourcegroups = @($ResourceGroupName,$vNetResourceGroupName);
# $resourcegroups = @($ResourceGroupName);
if($resourcegroups.length) {
	foreach($resourcegroup in $resourcegroups) {
		ProvisionRGs($resourcegroup);
	}
	}

# Create Network
If($NewVnet -eq "True")
{
ProvisionNet
}
else
 {$Description = "Create new VNET not selected...Using Existing $VNetName"
 $Command = {Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Get-AzureRmVirtualNetworkSubnetConfig | ft "Name" }
 WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
 }

 # Create NSG
If($NSGEnabled -eq "True")
{
CreateNSG}
 else
{$Description = "Create new NSG not selected...Using existing $NSGName"
$Command = {Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $vNetResourceGroupName}
WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
}


#CreateStorage
try {
Write-Host "Starting Storage Creation"
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName.ToLower() -Type $StorageType -Location $Location -ErrorAction Continue
$Command = {Get-AzureRmStorageAccount -Name $StorageName.ToLower() -ResourceGroupName $ResourceGroupName | ft "StorageAccountName"}
$Description = {'Storage Creation'}
WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
}
catch {
	Write-Host -foregroundcolor Yellow `
	"$($_.Exception.Message)"; `
	WriteLog-Command $Command -Description $_ -LogFile $LogFile
	continue
Finally {
}
}

#Match and prepare image
switch -Wildcard ($vmMarketImage)
	{
		"*pf*" {
$Command = {"PfSense VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{

$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
try{ 
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork }
catch { 	Write-Host -foregroundcolor Yellow `
	"$($_.Exception.Message)"; `
	WriteLog -Command $Command -Description $_ -LogFile $LogFile
	continue
	ProvisionNet
	}
finally{}

$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
$Interface2 = New-AzureRmNetworkInterface -Name $InterfaceName2 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub2].Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
$Interface2 = New-AzureRmNetworkInterface -Name $InterfaceName2 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub2].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMPlan -VM $VirtualMachine -Name pfsense-router-fw-vpn-225 -Publisher netgate -Product netgate-pfsense-appliance
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -linux -ComputerName $VMName -Credential $Credential1
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName netgate -Offer netgate-pfsense-appliance -Skus pfsense-router-fw-vpn-225 -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface2.Id
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching 
}
		"*red72*" {
$Command = {"Redhat VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -linux -ComputerName $VMName -Credential $Credential1
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName "Redhat" -Offer "rhel" -Skus "7.2" -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*red67*" {
$Command = {"Redhat VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host 
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -linux -ComputerName $VMName -Credential $Credential1
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName "Redhat" -Offer "rhel" -Skus "6.7" -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*MySql*" {
$Command = {"MySql VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -linux -ComputerName $VMName -Credential $Credential1
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName "Bitnami" -Offer "mysql" -Skus "5-6" -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*w2k12*" {
$Command = {"Windows VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential1 -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*sql*" {
$Command = {"SQL VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential1 -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName "MicrosoftSQLServer" -Offer "SQL2016-WS2012R2" -Skus "Enterprise" -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*rserver*" {
$Command = {"R Server VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMPlan -VM $VirtualMachine -Name msr80-win2012r2 -Publisher microsoft-r-products -Product microsoft-r-server
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential1 -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName microsoft-r-products -Offer microsoft-r-server -Skus msr80-win2012r2 -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*w2k8*" {
$Command = {"Windows 2k8 VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential1 -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2008-R2-SP1" -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*w2k16*" {
$Command = {"Windows 2k16 VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential1 -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "Windows-Server-Technical-Preview" -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*chef*" {
$Command = {"Chef VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMPlan -VM $VirtualMachine -Name azure_marketplace_100 -Publisher chef-software -Product chef-server
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName chef-software -Offer chef-server -Skus azure_marketplace_100 -Version "latest"
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -linux -ComputerName $VMName -Credential $Credential1
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*cent*" {
$Command = {"CentOS VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName OpenLogic -Offer Centos -Skus "7.2" -Version "latest"
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -linux -ComputerName $VMName -Credential $Credential1
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*ub*" {
$Command = {"Ubuntu VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
Write-Host "Finishing Public IP creation..."
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName Canonical -Offer UbuntuServer -Skus "14.04.4-LTS" -Version "latest"
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -linux -ComputerName $VMName -Credential $Credential1
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*SU*" {
$Command = {"SuSe VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName SUSE -Offer openSUSE -Skus "13.2" -Version "latest"
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -linux -ComputerName $VMName -Credential $Credential1
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		"*check*" {
$Command = {"Checkpoint VM Image Preparation in Process"}
$Description = "Starting Azure VM Creation"
	WriteLog-Command -Description $Description -Command $Command  -LogFile $LogFile
If ($NoPublicIP -eq "False")
{
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Dynamic"
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id -PublicIpAddressId $PIp.Id
$Interface2 = New-AzureRmNetworkInterface -Name $InterfaceName2 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub2].Id
} else
{
Write-Host "Skipping Public IP creation..."
$VNet = Get-AzureRMVirtualNetwork -Name $VNetName -ResourceGroupName $vNetResourceGroupName | Set-AzureRmVirtualNetwork
$Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub1].Id
$Interface2 = New-AzureRmNetworkInterface -Name $InterfaceName2 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[$DepSub2].Id
}
If ($AvailabilitySet -eq "True")
 {
New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName -Location $Location
Write-Host "Created Availability Set"
$AvailabilitySet =(Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailSetName).Id
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet.Id
}
else
{
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}
$VirtualMachine = Set-AzureRmVMPlan -VM $VirtualMachine -Name sg-ngtp -Publisher checkpoint -Product check-point-r77-10
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName checkpoint -Offer check-point-r77-10 -Skus sg-ngtp -Version "latest"
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -linux -ComputerName $VMName -Credential $Credential1
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -Primary
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface2.Id
$osDiskCaching = "ReadWrite"
$OSDiskName = $VMName + "OSDisk"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage" -Caching $osDiskCaching
}
		default{"An unsupported image was referenced"}
	}


try {
$ProvisionVMs = @($VirtualMachine);
if($ProvisionVMs.length) {
   foreach($provisionvm in $ProvisionVMs) {
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -ErrorAction Stop | ft "StatusCode"
 Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
 $Command = {"$VMName deployed to RG $ResourceGroupName using MarketImage $vmMarketImage on VNET $VNetName in VNET RG $vNetResourceGroupName"}
 $Description = "Completing VM Creation"
	 WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
}
}
}
catch {
	Write-Host -foregroundcolor Yellow `
	"$($_.Exception.Message)"; `
	continue 
}   
Finally {

}
#Add VM Extensions

If($ExtVMAccess -eq "True")
{
Write-Host "VM Access Agent VM Image Preparation in Process"
Set-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "VMAccess" -ExtensionType "VMAccessAgent" -Publisher "Microsoft.Compute" -typeHandlerVersion "2.0" -Location Westus -Verbose
Set-AzureRmVMAccessExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "VMAccess" -Location Westus -Verbose
Get-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "VMAccess"
}
If($ExtMSAV -eq "True")
{
Write-Host "MSAV Agent VM Image Preparation in Process"
Set-AzureRmVMExtension  -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "MSAVExtension" -ExtensionType "IaaSAntimalware" -Publisher "Microsoft.Azure.Security" -typeHandlerVersion 1.4 -Location $Location
Set-AzureRmVMAccessExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "MSAVExtension" -Location Westus
Get-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "MSAVExtension" -Status
}
If($ExtCustScript -eq "True")
{
Write-Host "Updating server with custom script"
Set-AzureRmVMCustomScriptExtension -Name "CustScript" -ResourceGroupName $ResourceGroupName -Run "CustScript.ps1" -VMName $VMName -FileUri $StorageName -Location $Location -TypeHandlerVersion "1.1"
Get-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -Name "CustScript"
}
If($ExtAzureDiag -eq "True")
{
Write-Host "Adding Azure Enhanced Diagnostics"
Set-AzureRmVMAEMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -WADStorageAccountName $StorageName
Get-AzureRmVMAEMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName
}

If ($NoPublicIP -eq "True"){
Write-Host "No Public IP created"
}
else
{
$Command = {Get-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName | ft "IpAddress"}
$Description = "Remote Access IP Address"
WriteLog-Command -Description $Description -Command $Command -LogFile $LogFile
}
Write-Host "$VMName deployed to RG $ResourceGroupName using MarketImage $vmMarketImage on VNET $VNetName in VNET RG $vNetResourceGroupName"