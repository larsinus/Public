<#
    Created by:  Lars Halvorsen, Microsoft
    Description:
        The script will write all devices and their Azure AD group memberships to a file
    Instructions:
        You need to change two variables for it to be able to run:
        1. $scriptPath
        2. $useraccount
        *** feel free to change anything else you see fit at your own risk
    Disclaimer:
        The sample scripts are not supported under any Microsoft standard support program or service.
        The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all
        implied warranties including, without limitation, any implied warranties of merchantability or of
        fitness for a particular purpose. The entire risk arising out of the use or performance of the sample
        scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else
        involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever
        (including, without limitation, damages for loss of business profits, business interruption, loss of
        business information, or other pecuniary loss) arising out of the use of or inability to use the
        sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
#>
#-----------------------------------------------------------------------------------------
#region Path and Credentials
#-----------------------------------------------------------------------------------------
$ScriptPath = <path to your script location> # example 'C:\Scripts\'
Set-Location $ScriptPath

If (Test-Path .\creds.xml) {
    $creds = Import-Clixml -Path .\Creds.xml
}
if(!($creds)) {
    # Create Credential Object
    $useraccount = <your AzureAD credentials> #example 'admin@contoso.com'
    $creds = Get-Credential -Credential $useraccount
    # Save the PSCredential as a serialized object to file
    Export-Clixml -Path .\Creds.xml  -InputObject $Creds
}

$graphAuth = Connect-MSGraph -PassThru -Credential $creds

#-----------------------------------------------------------------------------------------
#endregion path and credentials
#-----------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------
#region Functions
#-----------------------------------------------------------------------------------------
function Get-MembersOf ($id) {
    $memberof_uri = ("https://graph.microsoft.com/v1.0/devices/"+$id+"/memberOf")
    $Header = @{
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

function Get-Computer () {
    $device_uri = ("https://graph.microsoft.com/v1.0/devices")
    $Header = @{
        'Content-Type'  = 'application\json'
        'Authorization' = $graphAuth
    }
    try {
        $device = Invoke-RestMethod -Headers $Header -Uri $device_uri -UseBasicParsing -Method 'Get' -ErrorAction SilentlyContinue
        Return $device
        }
    catch {
        $_
    }
}
#-----------------------------------------------------------------------------------------
#endregion functions
#-----------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------
#region main script
#-----------------------------------------------------------------------------------------
Clear-Host
$fileName = ("Azure AD Group Membership for all devices v"+(Get-Date -Format yyMM.dd.HHmm))+".txt"
$arrMultipleDevices = Get-Computer
("Script was run on "+ (Get-Date -Format "dddd MM/dd/yyyy HH:mm K")) | Out-File -FilePath .\$fileName -Append
("Number of devices: "+($arrMultipleDevices.value).Count) | Out-File -FilePath .\$fileName -Append

foreach ($line in $arrMultipleDevices.value) {
    ("`nThe device ["+$line.displayName+"] {last seen:"+$line.approximateLastSignInDateTime+"} is a member of these Azure AD groups:") | Out-File -FilePath .\$fileName -Append
    "----------------------------------------------------------------------------------------------------" | Out-File -FilePath .\$fileName -Append
    Get-MembersOf $line.id | Out-File -FilePath .\$fileName -Append
}
Write-Host -ForegroundColor Green "Done!"
#-----------------------------------------------------------------------------------------
#endregion main script
#-----------------------------------------------------------------------------------------
