<#
    Description:
        Used to get maintenance windows for the collections you have specified in the .TXT file
        The .TXT file should just be a list of collection ID's (one per line)

        Run the script on the Site Server.
        Start PowerShell from inside the ConfigMgr console (upper left corner).
#>

#region Initialising
    # Site configuration
    $defaultSiteCode = <Site Code> # example'ABC'
    $SiteCode = Read-Host "Type [Site Code] or press enter to accept the default [$($defaultSiteCode)]"
    $SiteCode = ($defaultSiteCode,$SiteCode)[[bool]$SiteCode]
    $defaultSiteServer = <Site Server FQDN> #example 'PS1.contoso.com'
    $SiteServer = Read-Host "Type [Site Server FQDN] or press enter to accept the default [$($defaultSiteServer)]"
    $SiteServer = ($defaultSiteServer,$SiteServer)[[bool]$SiteServer]

#endregion

# ----------------------------------------------------------------------------------------------------------------------------------------------------------
# Do not change anything below this line
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
Function Get-FileName ($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”)
    Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “All files (*.*)| *.*”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

$allCollections = Get-Content (Get-Filename -initialDirectory "C:fso")[1]

Function Space () {
    param ([int]$i, [int]$ii)
    $NoSpace = ($ii - $i)
	While ($NoSpace -gt 0){
		$gap = $gap + " "
		$NoSpace--
	}
	Write-Host $gap -NoNewline
}

Foreach ($collection in $allCollections){
    $divider = "-"*120
    Write-Host $divider
    $objCollection = Get-CMCollection -Id $collection
    Write-Host ("Getting Maintenance Windows for collection ") -NoNewline
    Write-Host -ForegroundColor Yellow $objCollection.Name -NoNewline
    Write-Host (" ["+$objCollection.CollectionID+"]")
    Write-Host $divider

    $runtime = Get-CMMaintenanceWindow -CollectionId $collection
    if ($null -eq $runtime.servicewindowschedules){
        Write-Host -ForegroundColor Red "No Maintenance Windows Found"
    }

    $arrMaintenanceWindows = Get-CMMaintenanceWindow -CollectionId $objCollection.CollectionID | Sort-Object starttime
    foreach ($MW in $arrMaintenanceWindows){
        Write-Host ("MW Name: ") -NoNewline
        Write-Host -ForegroundColor Cyan $MW.Name -NoNewline
        space $MW.Name.Length 20
        Write-Host "Start time: " -NoNewline
        Write-Host -ForegroundColor Cyan (Get-Date -Date $mw.StartTime).ToLongDateString() -NoNewline
        space ((Get-Date -Date $mw.StartTime).ToLongDateString()).Length 30

        Write-Host -ForegroundColor Cyan (Get-Date -Date $mw.StartTime).ToLongTimeString() -NoNewline
        space ((Get-Date -Date $mw.StartTime).ToLongTimeString()).Length 11
        Switch ($MW.IsGMT){
            "True" {
                Write-Host " GMT" -NoNewline
                space 4 12
            }
            "False" {
                Write-Host " Local time" -NoNewline
                space 11 12}
        }

        Write-Host ("[") -NoNewline
        Write-Host -ForegroundColor Cyan $MW.Duration -NoNewline
        space (($mw.Duration).ToString()).length 4
        Write-Host (" minutes]") -NoNewline

        Write-Host " [" -NoNewline
        Switch ($MW.IsEnabled){
            "True" {Write-Host -ForegroundColor Green "ENABLED" -NoNewline}
            "False" {Write-Host -ForegroundColor Red "DISABLED" -NoNewline}
        }
        Write-Host "]"
    }
    Write-Host " "
}
