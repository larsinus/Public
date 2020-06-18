
# Graph API source for getting a list of managed devices:
# https://docs.microsoft.com/en-us/graph/api/intune-devices-manageddevice-list?view=graph-rest-1.0

# Storing credentials in a variable
$Creds = Get-Credential

# Connect to Graph using credentials to get the required token to query Graph
$GraphAuth = Connect-MSGraph -PassThru -Credential $Creds

# Examples of how you can use variables instead of hard coding everything like we do
# below in the $Uri variable
#$ApiVersion = '1.0'
#$UriRoot = "https://graph.microsoft.com/$ApiVersion/"
#$UriPath = "/DeviceManagement/ManagedDevices"

# Required part of the query - see the source link for details (Header is the only required piece)
$Header = @{
    'Content-Type'  = 'application\json'
    'Authorization' = $GraphAuth
}

# The URI for quering Intune - see the source link for details
$Uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
# $Uri = "$UriRoot$ApiVersion$UriPath"

# Get the devices from Intune and store them in a variable
$IntuneDevices = Invoke-RestMethod -Headers $Header -Uri $Uri -UseBasicParsing -Method Get

# Show the devices and some of the info sorted by last sync date/time
$IntuneDevices.Value `
 | Select-Object DeviceName, OperatingSystem, managedDeviceOwnerType, lastSyncDateTime, id `
 | Sort-Object lastSyncDateTime -Descending





 