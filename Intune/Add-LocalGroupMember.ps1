function Add-LocalGroupMember {
    <#
        .SYNOPSIS
        Adds a user to a local group

        .DESCRIPTION
        The script accepts two parameters. A username and a local group.
        UserName must be in the format of either:
            1) AzureAD\UserName@domain.com
            2) Domain\UserName
        Then select which group the user should be added to.

        .PARAMETER UserName
        .PARAMETER LocalGroup

        .EXAMPLE
        PS C:\Add-LocalGroupMember -UserName Domain\UserName -LocalGroup RemoteDesktopUsers
        .EXAMPLE
        PS C:\Add-LocalGroupMember -UserName AzureAD\UserName@domain.com -LocalGroup LocalAdmin
        .EXAMPLE
        PS C:\Add-LocalGroupMember -LocalGroup RemoteDesktopUsers
        Adds the currently logged on user to the local group 'Remote Desktop Users'
    #>


    #region -----------------------[ FUNCTION INITIALIZATIONS ]---------------------------------------------------------------------

    [CmdletBinding()]
    param (
        [Parameter()]
        [String]$UserName,

        [Parameter(Mandatory=$true)]
        [ValidateSet('LocalAdmin','RemoteDesktopUsers')]
        [String]$LocalGroup
    )

    $ErrorActionPreference = 'Stop'

    #endregion ------------------[ End Function Initializations ]-------------------------------------------------------------------


    #region -----------------------[ FUNCTION FUNCTIONS ]---------------------------------------------------------------------------

    function Add-GroupMember {
        Write-Log -Type Information -Message "Verifying if $UserName already belong to the group"
        if ($LocalGroupMembers -contains $UserName -eq $false) {
            Write-Log -Type Information -Message "Adding the user $UserName to the group $LocalGroupName"
            Try {
                net localgroup $LocalGroupName /add $UserName
            }
            Catch {
                Write-Log -Type Error -Message "Access Denied. Requires elevated privileges."
            }
        }
    }

    function Write-Log {
        param (
            [Parameter(Mandatory=$true)]
            [String]$Message,
            [Parameter(Mandatory=$true)]
            [ValidateSet('Information','Warning','Error')]
            [String]$Type
        )
        Switch ($Type){
            'Information' {
                Write-EventLog -LogName Application -Source "Add-LocalGroupMember" -EntryType Information -EventId 7 -Message $Message
            }
            'Warning' {
                Write-EventLog -LogName Application -Source "Add-LocalGroupMember" -EntryType Warning -EventId 14 -Message $Message
            }
            'Error' {
                Write-EventLog -LogName Application -Source "Add-LocalGroupMember" -EntryType Error -EventId 31 -Message $Message
            }
            Default {}
        }

    }

    #endregion ------------------[ End Function Functions ]------------------------------------------------------------------------


    #region -----------------------[ FUNCTION EXECUTION ]---------------------------------------------------------------------------

    if ($UserName -eq "") {
        $domain = (Get-WmiObject win32_loggedonuser | Select-Object -ExpandProperty Antecedent).split('=')[1]
        $user = (Get-WmiObject win32_loggedonuser | Select-Object -ExpandProperty Antecedent).split('=')[2]
        $UserName = "$($domain.split('"')[1])\$($user.Split('"')[1])"
    }

    Try {
        New-EventLog -LogName Application -Source "Add-LocalGroupMember"
    }
    Catch [System.InvalidOperationException] {
        Write-Log -Type Warning -Message "Event Log Source Already Exist"
    }

    switch ($LocalGroup) {
        'LocalAdmin' {
            $LocalGroupName = 'Administrators'
            Write-Log -Type Information -Message "Collecting members of the group $LocalGroupName"
            $LocalGroupMembers = (net localgroup (Get-WmiObject win32_Group | Where-Object SID -eq 'S-1-5-32-544').Name)
            Add-GroupMember
        }
        'RemoteDesktopUsers' {
            $LocalGroupName = 'Remote Desktop Users'
            Write-Log -Type Information -Message "Collecting members of the group $LocalGroupName"
            $LocalGroupMembers = (net localgroup (Get-WmiObject win32_Group | Where-Object SID -eq 'S-1-5-32-555').Name)
            Add-GroupMember
        }
        Default {}
    }

    #endregion ------------------[ End Function Execution ]--------------------------------------------------------------------------
}

Add-LocalGroupMember -LocalGroup LocalAdmin