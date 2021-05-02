
#region -[ Variables ]-
<#
    Valid $intuneParameter values:
    ================================================================================================
    id, userId, deviceName, managedDeviceOwnerType, enrolledDateTime, lastSyncDateTime, 
    operatingSystem, complianceState, jailBroken, managementAgent, osVersion, easActivated, 
    easDeviceId, easActivationDateTime, azureADRegistered, deviceEnrollmentType, 
    activationLockBypassCode, emailAddress, azureADDeviceId, deviceRegistrationState, 
    deviceCategoryDisplayName, isSupervised, exchangeLastSuccessfulSyncDateTime, exchangeAccessState, 
    exchangeAccessStateReason, remoteAssistanceSessionUrl, remoteAssistanceSessionErrorDetails, 
    isEncrypted, userPrincipalName, model, manufacturer, imei, complianceGracePeriodExpirationDateTime, 
    serialNumber, phoneNumber, androidSecurityPatchLevel, userDisplayName, 
    configurationManagerClientEnabledFeatures, wiFiMacAddress, deviceHealthAttestationState, 
    subscriberCarrier, meid, totalStorageSpaceInBytes, freeStorageSpaceInBytes, managedDeviceName, 
    partnerReportedThreatState, deviceActionResults
    *** Could be more values as well - Check which values are available by quering the Graph API
    *** https://graph.microsoft.com/v1.0/deviceManagement/managedDevices

    Define 'parameter filter' and 'parameter value'
    =================================================================================================
    Specify your 'parameter filter' (-eq/-ne/-gt/...etc.) and 
    'parameter value' (''/'desktop-agre2dg'/'1234567'/...etc.) 
    on line 223
#>
    $intuneParameter = 'androidSecurityPatchLevel'
    $AADGroupID = '<Your Azure AD Group ID>'
    # Specify parameter filter 

    $subscriptionID = Get-AutomationVariable 'subscriptionID' # Azure Subscription ID Variable
    $tenantID = Get-AutomationVariable 'tenantID' # Azure Tenant ID Variable
#endregion variables

#region -[ Graph App Registration Creds ]-
    # Uses a Secret Credential named 'GraphApi' in your Automation Account
    $clientInfo = Get-AutomationPSCredential 'GraphApi'
    # Username of Automation Credential is the Graph App Registration client ID 
    $clientID = $clientInfo.UserName
    # Password  of Automation Credential is the Graph App Registration secret key (create one if needed)
    $secretPass = $clientInfo.GetNetworkCredential().Password

    #Required credentials - Get the client_id and client_secret from the app when creating it in Azure AD
    $client_id = $clientID #App ID
    $client_secret = $secretPass #API Access Key Password
#endregion graph app registration creds

function Get-AuthToken {
    <#
        .SYNOPSIS
        This function is used to authenticate with the Graph API REST interface
        .DESCRIPTION
        The function authenticate with the Graph API Interface with the tenant name
        .EXAMPLE
        Get-AuthToken
        Authenticates you with the Graph API interface
        .NOTES
        NAME: Get-AuthToken
    #>

    param (
        [Parameter(Mandatory=$true)]
        $TenantID,
        [Parameter(Mandatory=$true)]
        $ClientID,
        [Parameter(Mandatory=$true)]
        $ClientSecret
    )
           
    try {
        # Define parameters for Microsoft Graph access token retrieval
        $resource = "https://graph.microsoft.com"
        $authority = "https://login.microsoftonline.com/$TenantID"
        $tokenEndpointUri = "$authority/oauth2/token"
            
        # Get the access token using grant type client_credentials for Application Permissions
        $content = "grant_type=client_credentials&client_id=$ClientID&client_secret=$ClientSecret&resource=$resource"
        $response = Invoke-RestMethod -Uri $tokenEndpointUri -Body $content -Method Post -UseBasicParsing -Verbose:$false

        Write-Host "Got new Access Token!" -ForegroundColor Green
        Write-Host

        # If the accesstoken is valid then create the authentication header
        if ($response.access_token){ 
            # Creating header for Authorization token
            $authHeader = @{
                'Content-Type'='application/json'
                'Authorization'="Bearer " + $response.access_token
                'ExpiresOn'=$response.expires_on
            }
            return $authHeader    
        }
        else {    
            Write-Error "Authorization Access Token is null, check that the client_id and client_secret is correct..."
            break    
        }
    }
    catch {    
        FatalWebError -Exeption $_.Exception -Function "Get-AuthToken"   
    }
} #end of function Get-AuthToken

Function Get-ValidToken {
<#
    .SYNOPSIS
    This function is used to identify a possible existing Auth Token, and renew it using Get-AuthToken, if it's expired
    .DESCRIPTION
    Retreives any existing Auth Token in the session, and checks for expiration. If Expired, it will run the Get-AuthToken Fucntion to retreive a new valid Auth Token.
    .EXAMPLE
    Get-ValidToken
    Authenticates you with the Graph API interface by reusing a valid token if available - else a new one is requested using Get-AuthToken
    .NOTES
    NAME: Get-ValidToken
#>

#Fixing client_secret illegal char (+), which do't go well with web requests
$client_secret = $($client_secret).Replace("+","%2B")
           
# Checking if authToken exists before running authentication
if($global:authToken){
           
    # Get current time in (UTC) UNIX format (and ditch the milliseconds)
    $CurrentTimeUnix = $((get-date ([DateTime]::UtcNow) -UFormat +%s)).split((Get-Culture).NumberFormat.NumberDecimalSeparator)[0]
                          
    # If the authToken exists checking when it expires (converted to minutes for readability in output)
    $TokenExpires = [MATH]::floor(([int]$authToken.ExpiresOn - [int]$CurrentTimeUnix) / 60)
           
    if($TokenExpires -le 0){    
        Write-Host "Authentication Token expired" $TokenExpires "minutes ago! - Requesting new one..." -ForegroundColor Green
        $global:authToken = Get-AuthToken -TenantID $tenantID -ClientID $client_id -ClientSecret $client_secret    
    }
    else{
        Write-Host "Using valid Authentication Token that expires in" $TokenExpires "minutes..." -ForegroundColor Green
        #Write-Host
    }
}    
# Authentication doesn't exist, calling Get-AuthToken function    
else {       
    # Getting the authorization token
    $global:authToken = Get-AuthToken -TenantID $tenantID -ClientID $client_id -ClientSecret $client_secret    
}    
} # end of function Get-ValidToken

function GraphCall {
    <#
        .SYNOPSIS
        This function is used to identify a possible existing Auth Token, and renew it using Get-AuthToken, if it's expired
        .DESCRIPTION
        Retreives any existing Auth Token in the session, and checks for expiration. If Expired, it will run the Get-AuthToken Fucntion to retreive a new valid Auth Token.
        .EXAMPLE
        Get-ValidToken
        Authenticates you with the Graph API interface by reusing a valid token if available - else a new one is requested using Get-AuthToken
        .NOTES
        NAME: Get-ValidToken
    #>
    [cmdletbinding()]
    param (
        $UriRoot = 'https://graph.microsoft.com/',
        [validateset('v1.0','beta')]
        $Version = 'v1.0', 
        $UriEndpoint,
        [validateset('GET','POST','PUT','PATCH','DELETE')]
        $Method = 'GET', 
        $Header = @{
            'Content-Type'  = 'application/json'
            'Authorization' = $global:authToken.Authorization
        },
        $Body = 'empty'
    )

    Switch ($Body){
        'empty'     { Invoke-RestMethod -Uri "$UriRoot$Version/$UriEndpoint" -Method $Method -Headers $Header}
        default     {Invoke-WebRequest -Uri "$UriRoot$Version/$UriEndpoint" -Method $Method -Headers $Header -Body $Body }
    }
} # end of function GraphCall

#-----------------------------------------------------------------------------------------------------------------------------------------
#region ----------[ SCRIPT BODY ]------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------
# Checking if authToken exists before running authentication
if ($global:authToken) {
    $DateTime = (Get-Date).ToUniversalTime() # Setting DateTime to Universal time to work in all timezones
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes # If the authToken exists checking when it expires
    if ($TokenExpires -le 0) {
        Write-Output ("Authentication Token expired" + $TokenExpires + "minutes ago")
        #Calling Microsoft to see if they will give us access with the parameters defined in the config section of this script.
        Get-ValidToken
        $global:authToken = Get-AuthToken -TenantID $tenantID -ClientID $client_id -ClientSecret $client_secret
    }
}
else { # Authentication doesn't exist, calling Get-AuthToken function
    Get-ValidToken #Calling Microsoft to see if they will give us access with the parameters defined in the config section of this script.
    $global:authToken = Get-AuthToken -TenantID $tenantID -ClientID $client_id -ClientSecret $client_secret  # Getting the authorization token
}

# zeroing out all variables
$MDMobject = $null
$AADObject = $null
$arrIntuneObjects = @()
$arrAADObjects = @()
$arrDevices = @()
$arrRemoveDevices = @()
$arrAddToAADGroup = @()
$arrExistingAADGroupMembers = @()
$arrRemoveAADGroupMembers = @()

$Body = $null
$BodyValueRoot = 'https://graph.microsoft.com/v1.0/directoryObjects/'

# fetching all Intune objects
$arrIntuneObjects = GraphCall -UriEndpoint "devicemanagement/manageddevices?`$select = id,$intuneParameter,azureADDeviceId"

# fetching all Azure AD objects
$arrAADObjects = GraphCall -UriEndpoint 'devices?$select = id,deviceId'

# fetching all existing members of the Azure AD group
$arrExistingAADGroupMembers = GraphCall -UriEndpoint "groups/$AADGroupID/Members?`$select=id,deviceId"

# looping through all Intune objects to verify if they match the specified criteria
foreach ($MDMobject in $arrIntuneObjects.value){
    <# ------------------------------------------------------------------------------
     SPECIFY YOUR FILTER PARAMETER AND FILTER VALUE IN THE 'if' STATEMENT BELOW
    --------------------------------------------------------------------------------- #>
    if ($MDMobject.$($intuneParameter) -eq '2020-09-01'){ 
        
        $arrDevices += $MDMobject.azureADDeviceId
    }
    else {
        $arrRemoveDevices += $MDMobject.azureADDeviceId
    }
}

# Checking that the Azure AD object is in the Intune list and not already a member of the Azure AD group
foreach ($AADObject in $arrAADObjects.value){
    if ($($AADObject.deviceID) -in $arrDevices -and $($AADObject.deviceID) -notin $($arrExistingAADGroupMembers.value.deviceId)){
        $arrAddToAADGroup += "$BodyValueRoot$($AADObject.id)"
    }
    elseif ($($AADObject.deviceID) -in $arrRemoveDevices -and $($AADObject.deviceID) -in $($arrExistingAADGroupMembers.value.deviceId)){
        $arrRemoveAADGroupMembers += $AADObject.id
    }
    elseif ($($AADObject.deviceID) -in $($arrExistingAADGroupMembers.value.deviceId) -and $($AADObject.deviceId) -notin $arrIntuneObjects.value.azureADDeviceId){
        $arrRemoveAADGroupMembers += $AADObject.id
    }
}

# there is a limitation in the Graph API to only add 20 devices at a time
# if the array contains more than 20 objects we split it up in multiple arrays containing 20 devices each

if ($arrAddToAADGroup.Length -eq 0){
    'No new devices to add'
}
elseif ($arrAddToAADGroup.Length -gt 20){    
    # defining max array size
    $chunkSize = 20
    $outArray = @()
    $parts = [math]::Ceiling($arrAddToAADGroup.Length / $chunkSize)
    
    # splitting the array
    for($i=0; $i -le $parts; $i++){
        $start = $i*$chunkSize
        $end = (($i+1)*$chunkSize)-1
        $outArray += ,@($arrAddToAADGroup[$start..$end])
    }
    
    $outArray | ForEach-Object {
        $Body = ConvertTo-Json -InputObject (
            @{
            "members@odata.bind" = $_
            }
        )
        GraphCall -Method PATCH -UriEndpoint "groups/$AADGroupID" -Body $Body 
    }
}
else {
    $Body = ConvertTo-Json -InputObject (
        @{
        "members@odata.bind" = $arrAddToAADGroup
        }
    )
    GraphCall -Method PATCH -UriEndpoint "groups/$AADGroupID" -Body $Body
}
#endregion testing

# removing existing group members that no longer match the parameter value
if ($arrRemoveAADGroupMembers.Length -gt 0){
    # DELETE https://graph.microsoft.com/v1.0/groups/{group-id}/members/{directory-object-id}/$ref
    foreach ($RemDevice in $arrRemoveAADGroupMembers){
        GraphCall -Method DELETE -UriEndpoint "groups/$AADGroupID/members/$RemDevice/`$ref"
    }
}

#endregion -----[ script body ]----------------------------------------------------------------
