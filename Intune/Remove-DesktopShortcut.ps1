<#
    .SYNOPSIS
    Removes unwanted shortcuts from the desktop

    .DESCRIPTION
    It can be used to remove shortcuts on the desktop by specifying a -Filter which can be anything.
    The script will remove all shortcuts that match the filter.
    It will do this eiter for the current user only or all user profiles found based on the -Scope parameter.

    .PARAMETER Scope
    .PARAMETER Filter

    .EXAMPLE
    PS C:\Remove-DesktopShortcut -Scope AllUsers -Filter Microsoft
    This will remove all shortcuts matching 'Microsoft' like 'Microsoft Edge' and 'Microsoft Teams' for all user profiles.

    .EXAMPLE
    PS C:\Remove-DesktopShortcut -Scope CurrentUser -Filter ""
    This will remove all shortcuts only for the currently logged on user.

    .EXAMPLE
    PS C:\Remove-DesktopShortcut -Scope CurrentUser -Filter oo
    This will remove all shortcuts with double 'o' in it like 'Facebook' and 'Books' but not 'OneNote'.
#>
function Remove-DesktopShortcut {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateSet('CurrentProfile','AllProfiles')]
        $Scope,
        [Parameter(Mandatory=$true)]
        $Filter
    )

    #region -----------------------[ DECLARATIONS ]---------------------------------------------------------------------------
    $SourceName = 'Remove-DesktopShortcut'
    $InfoID = 7
    $WarnID = 14
    $ErrID = 31
    $FSO = New-Object -ComObject Scripting.FileSystemObject
    $UsersRoot = 'C:\Users\'
    $deleteCounter = 0
    $ErrorActionPreference = 'Stop'

    #endregion ------------------[ End Declarations ]----------------------------------------------------------------------


    #region -----------------------[ FUNCTIONS ]---------------------------------------------------------------------------
    function Write-Log {
        param (
            [Parameter(Mandatory=$true)]
            [String]$Message,
            [Parameter(Mandatory=$true)]
            [ValidateSet('Information','Warning','Error')]
            [String]$Type
        )
        Switch ($Type) {
            'Information' {
                Write-EventLog -LogName Application -Source $SourceName -EntryType Information -EventId $InfoID -Message $Message
            }
            'Warning' {
                Write-EventLog -LogName Application -Source $SourceName -EntryType Warning -EventId $WarnID -Message $Message
            }
            'Error' {
                Write-EventLog -LogName Application -Source $SourceName -EntryType Error -EventId $ErrID -Message $Message
            }
            Default {}
        }
    }

    function Remove-Shortcut {
        param (
            [Parameter(Mandatory = $true)]
            [String]$Path
        )
        Write-Log -Type Information -Message "[GET] Fetching desktop shortcuts from the profile $ProfilePath."
        Try {
            $arrShortcuts = Get-ChildItem $ProfilePath | Where-Object Name -Match '.lnk'
        }
        Catch {
            Write-Log -Type Error -Message "Couldn't find the path $ProfilePath"
        }
        Write-Log -Type Information -Message "[FOUND] Total of $($arrShortcuts.Count) shortcuts found on the desktop (all shortcuts included) for the profile $ProfilePath."
        if ($arrShortcuts.Count -ne 0) {
            Foreach ($file in $arrShortcuts) {
                If ($FSO.GetExtensionName($file) -eq 'lnk' -and $FSO.GetFileName($file) -match $Filter) {
                    Write-Log -Type Information -Message "[DEL] Deleting $file"
                    $FSO.DeleteFile("$ProfilePath\$file") # delete shortcuts
                    $deleteCounter++
                }
            }
        }
        Write-Log -Type Information -Message "[TOTAL] Deleted a total of $($deleteCounter) shortcut(s) for $ProfilePath."
        $deleteCounter = 0
    }
    #endregion ------------------[ End Functions ]-------------------------------------------------------------------------


    #region -----------------------[ EXECUTION ]---------------------------------------------------------------------------

    Try {
        New-EventLog -LogName Application -Source $SourceName
    }
    Catch [System.InvalidOperationException] {
        Write-Log -Type Warning -Message "Event Log Source Already Exist"
    }

    Write-Log -Type Information -Message "Filter specified for removal of shortcuts from the desktop: $($Filter.ToUpper())"
    if ($Scope -eq 'AllProfiles') {
        $Profiles = Get-ChildItem -Path c:\users
        foreach ($User in $Profiles) {
            if ($User.Name -ieq 'Public') {
                $ProfilePath = Get-ChildItem -Path "c:\users\$($User.Name)" -Name 'Public Desktop' -Directory -Recurse -Depth 1
                $ProfileCount = $ProfilePath.Count
                while ($ProfileCount -gt 0) {
                    $ProfilePath = Get-ChildItem -Path "c:\users\$($User.Name)" -Name 'Public Desktop' -Directory -Recurse -Depth 1
                    $TempPath = $ProfilePath[$($ProfileCount-1)]
                    $ProfilePath = "$UsersRoot$($User.Name)\$ProfilePath"
                    Remove-Shortcut -Path $ProfilePath
                    $ProfileCount--
                }
            }
            else {
                $ProfilePath = Get-ChildItem -Path "c:\users\$($User.Name)" -Name Desktop -Directory -Recurse -Depth 1
                $ProfileCount = $ProfilePath.Count
                while ($ProfileCount -gt 0) {
                    $ProfilePath = Get-ChildItem -Path "c:\users\$($User.Name)" -Name Desktop -Directory -Recurse -Depth 1
                    $TempPath = $ProfilePath[$($ProfileCount-1)]
                    $ProfilePath = "$UsersRoot$($User.Name)\$TempPath"
                    Remove-Shortcut -Path $ProfilePath
                    $ProfileCount--
                }
            }
        }
    }
    elseif ($Scope -eq 'CurrentProfile') {
        $user = (Get-WmiObject win32_loggedonuser | Select-Object -ExpandProperty Antecedent).split('=')[2]
        $UserName = "$($user.Split('"')[1])"
        $ProfilePath = Get-ChildItem -Path "c:\users\$UserName" -Name Desktop -Directory -Recurse -Depth 1
        $ProfileCount = $ProfilePath.Count
        while ($ProfileCount -gt 0) {
            $ProfilePath = Get-ChildItem -Path "c:\users\$UserName" -Name Desktop -Directory -Recurse -Depth 1
            $TempPath = $ProfilePath[$($ProfileCount-1)]
            $ProfilePath = "$UsersRoot$UserName\$TempPath"
            $ProfileCount--
            Remove-Shortcut -Path $ProfilePath
        }
    }
    #endregion ------------------[ End Execution ]-------------------------------------------------------------------------
}

