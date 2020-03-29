<#
    Created by:  Lars Halvorsen and Hans Zeitler
    Owned by:    Microsoft
    Description:
        The script will list all Azure AD groups a specific device is a member of.    
#>

#-----------------------------------------------------------------------------------------
#region Verifying module existence and getting credentials
#----------------------------------------------------------------------------------------- 
$ModuleStatus = Get-Module -Name Microsoft.Graph.Intune
if ($null -eq $ModuleStatus) {
    Install-Module -Name Microsoft.Graph.Intune
}

If ($null -eq $creds) {
    $creds = Get-Credential 
    $graphAuth = Connect-MSGraph -PassThru -Credential $creds
}
#-----------------------------------------------------------------------------------------
#endregion module and creds
#----------------------------------------------------------------------------------------- 

#-----------------------------------------------------------------------------------------
#region Functions
#----------------------------------------------------------------------------------------- 
function Get-MembersOf ($id) {
    $memberof_uri = ("https://graph.microsoft.com/v1.0/devices/"+$id+"/memberOf")
    $Header =
    @{
        'Content-Type'  = 'application\json'
        'Authorization' = $graphAuth
    }
    try {
        $arrMemberOf = Invoke-RestMethod -Headers $Header -Uri $memberof_uri -UseBasicParsing -Method 'Get' -ErrorAction Stop
        return $arrMemberOf.value.displayname
    }
    catch {
        $_
    }
}

function Get-Computer ($computername) {
    $device_uri = ("https://graph.microsoft.com/v1.0/devices?$"+"filter=displayname eq '"+$computername+"'")
    $Header =
    @{
        'Content-Type'  = 'application\json'
        'Authorization' = $graphAuth
    }
    try {
        $global:Device = Invoke-RestMethod -Headers $Header -Uri $device_uri -UseBasicParsing -Method 'Get' -ErrorAction Stop
    }
    catch {
        $_
    }
}
#----------------------------------------------------------------------------------------- 
#endregion functions
#----------------------------------------------------------------------------------------- 

$computername = Read-Host "Type the computername you want to check"
Write-Host "`nThe computer [" -NoNewline
Write-Host -ForegroundColor Yellow $computername -NoNewline
Write-Host "] is a member of these Azure AD groups:"
Write-Host "-------------------------------------------------------------------------------"
Get-Computer $computername
Get-MembersOf $global:Device.value.id

