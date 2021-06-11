# CreateCollectionFromAADGroup
This script is intended to allow ConfigMgr Device Collections to be created from AAD Groups.
The use case is targeted at creating a Device Collection where all the devices are Autopilot devices.
Since a dynamic AAD group can quickly be created to target these devices it is easier to pull all the devices from
that group and then add them to a collection.


# Prerequisites
ConfigMgr Console must be installed on the device where this script is run.
User must have rights to read from the AAD Group.
User must have rights to create a Device Collection and/or modify collection membership rules.

# How to use (general)
Execute the script from PowerShell
- Set-ExecutionPolicy Bypass -Scope Process
- .\Create-AutoPilotCollection.ps1 -CMSiteCode <SITE> -CMSiteServer <ServerFQDN> -CMCollectionName "Name of new or existing collection" -AADGroupName "AAD Group Name" 


# Full parameter documentation
-CMSiteCode              Site code for the ConfigMgr site where the collection resides
-CMSiteServer            Site Server for the site code specified
-CMCollectionName        Name of a new or existing Device Collection to include devices in membership
-AADGroupName            Name of AAD group that contains devices to be added to the collection

