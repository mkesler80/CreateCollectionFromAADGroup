<#
Create a ConfigMgr Collection for AutoPilot devices in a specifc AzureAD Group

#>

[CmdletBinding()]
Param(
    [Parameter(
        Position=1,
        Mandatory=$True,
        HelpMessage="Site code where WIM will be imported"
        )]
        [String]$CMSiteCode,
    
    [Parameter(
        Position=2,
        Mandatory=$True,
        HelpMessage="Configuration Manager site server for specified site code"
        )]
        [String]$CMSiteServer,

    [Parameter(
        Position=3,
        Mandatory=$True,
        HelpMessage="Name of Collection for AP Devices"
        )]
        [String]$CMCollectionName,

    [Parameter(
        Position=4,
        Mandatory=$True,
        HelpMessage="Name of Azure AD group that contains AutoPilot devices"
        )]
        [String]$aadGroupName

)




Try{
        Write-Output "Looking for existing PSDrive for Configuration Manager site $CMSiteCode"
        Get-PSDrive -Name $CMSiteCode -ErrorAction Stop | Out-Null
    }catch [System.Management.Automation.DriveNotFoundException]{
        Write-Output "PSDrive for site code $CMSiteCode does not exist.`nMapping $CMSiteCode PSDrive."
        Import-Module $env:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1 -Force
        New-PSDrive -name $($CMSiteCode) -PSProvider "CMSite" -Root $($CMSiteServer) -Description "ConfigMgr Site" | Out-Null
    }    

Import-Module AzureAD -Force

Write-Host "Connecting to your Azure Active Directory Tenant"

Connect-AzureAD | Out-Null

Write-Host "Getting AutoPilot devices from $($aadGroupName)"

$APDevices = Get-AzureADGroup | WHERE {$_.DisplayName -eq $aadGroupName} | Get-AzureADGroupMember -All $True

Disconnect-AzureAD | Out-Null

Write-Host "Connecting to $($CMSiteCode) PS Drive"

Set-Location "$($CMSiteCode):\"

$colExists = Get-CMCollection -Name $CMCollectionName


If($colExists){
    
    Write-Host "Adding AutoPilot Group Members to $CMCollectionName"

    ForEach($device in $ApDevices){

        If(Get-CMCollectionDirectMembershipRule -CollectionName $CMCollectionName -ResourceName $device.DisplayName){
        
            Write-Host "$($device.DisplayName) Already Exists in Collection.  Skipping"
        
        }Else{
        
            Write-Host "Adding $($device.DisplayName) to $($CMCollectionName)"
            $cmdevice = Get-CMDevice -Name $device.DisplayName
            Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CMCollectionName -Resource $cmdevice
        
        }
    
    
    }


}Else{

    Write-Host "Creating Collection $($CMCollectionName)"
    New-CMCollection -CollectionType Device -LimitingCollectionName "All Desktop and Server Clients" -Name $CMCollectionName

    ForEach($device in $ApDevices){

            Write-Host "Adding $($device.DisplayName) to $($CMCollectionName)"
            $cmdevice = Get-CMDevice -Name $device.DisplayName
            Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CMCollectionName -Resource $cmdevice
    }
}


#CleanUp Collection Membership

$collMembers = Get-CMCollection -name $CMCollectionName | Get-CMCollectionMember | Select Name
$exists = $false

ForEach($member in $collMembers){
    ForEach($device in $APDevices){
        If($member -eq $device.DisplayName){
        
            $exists = $true
        }   
        
    }
    If(!$exists){
    
        Write-Host "Collection Member $($member) is no longer an AutoPilot device."
        Write-Host "Removing $($member) from $($CMCollectionName)."
        Remove-CMCollectionDirectMembershipRule -CollectionName $CMCollectionName -ResourceName $device.DisplayName
        $exists = $false
    }

}

Write-Host "Updating Collection Membership to sync changes"

Invoke-CMCollectionUpdate -Name $CMCollectionName

Set-Location "C:\"

Remove-PSDrive -Name $CMSiteCode