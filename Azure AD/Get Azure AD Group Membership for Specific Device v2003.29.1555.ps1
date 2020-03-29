<#
    Created by:  Lars Halvorsen and Hans Zeitler, Microsoft
    Description:
        The script will list all Azure AD groups a specific device is a member of.
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
#region Verifying module existence and getting credentials
#-----------------------------------------------------------------------------------------
    $scriptPath = <path to your script location> # example 'C:\Scripts\'
    Set-Location $scriptPath

    $ModuleStatus = Get-Module -Name Microsoft.Graph.Intune
    if ($null -eq $ModuleStatus) {
        Install-Module -Name Microsoft.Graph.Intune
    }
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
#endregion module and creds
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

function Get-Computer ($computername) {
    $device_uri = ("https://graph.microsoft.com/v1.0/devices?$"+"filter=displayName eq '"+$computername+"'")
    $Header = @{
        'Content-Type'  = 'application\json'
        'Authorization' = $graphAuth
    }
    try {
        $global:Device = Invoke-RestMethod -Headers $Header -Uri $device_uri -UseBasicParsing -Method 'Get' -ErrorAction SilentlyContinue
    }
    catch {
        $_
    }
}

function output () {
    Write-Host "`nThe device [" -NoNewline
    Write-Host -ForegroundColor Yellow $computername -NoNewline
    Write-Host "] is a member of these Azure AD groups:"
    Write-Host "-------------------------------------------------------------------------------"
}

#-----------------------------------------------------------------------------------------
#endregion functions
#-----------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------
#region main script
#-----------------------------------------------------------------------------------------
Clear-Host
$global:Device = $null
$computername = Read-Host "Type the computername you want to check"
Get-Computer $computername

if (($global:Device.value).Count -eq 0) {
    do {
        Write-Host "`n[" -NoNewline
        Write-Host -ForegroundColor Red "ERROR" -NoNewline
        Write-Host "] No device with that name found."
        $computername = Read-Host "Try typing another name or 'Quit' to exit the script"
        if ($computername -ieq "quit") {
            Write-Host "`n"
            Exit
        }
        Get-Computer $computername
    } while ($global:Device.value.Count -eq 0)
}

If (($global:Device.value).count -gt 1) {
    Write-Host "`n[" -NoNewline
    Write-Host -ForegroundColor Cyan "INFORMATION" -NoNewline
    Write-Host "] We found more than one device!"

    $arrMultipleDevices = $global:Device.value | Select-Object displayname, id, approximateLastSignInDateTime
    foreach ($line in $arrMultipleDevices) {
        Write-Host $line.displayname -noNewLine
        Write-Host -ForegroundColor Yellow (" "+$line.id) -NoNewline
        Write-Host (" Last seen: "+$line.approximateLastSignInDateTime)
    }

    do {
        $answer = Read-Host "`n-> Copy/paste the ID of the device you want to check or type 'QUIT' to exit the script"
        if ($answer -ieq "quit") {exit}
    } while ($answer -notin $arrMultipleDevices.id)

    output
    Get-MembersOf $answer
    Write-Host ""
}
else {
    output
    Get-MembersOf $global:Device.value.id
    Write-Host ""
}

#-----------------------------------------------------------------------------------------
#endregion main script
#-----------------------------------------------------------------------------------------
