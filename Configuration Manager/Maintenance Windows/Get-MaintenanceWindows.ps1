<#
    Description:
        Used to get maintenance windows for the collections you have specified in the .ini file
        The .ini file should just be a list of collection ID's (one per line)

#>

#region Initialising
    # Site configuration
    $defaultSiteCode = <Site Code> # example'ABC'
    $SiteCode = Read-Host "Type [Site Code] or press enter to accept the default [$($defaultSiteCode)]"
    $SiteCode = ($defaultSiteCode,$SiteCode)[[bool]$SiteCode]
    $defaultSiteServer = <Site Server FQDN> #example 'PS1.contoso.com'
    $SiteServer = Read-Host "Type [Site Server FQDN] or press enter to accept the default [$($defaultSiteServer)]"
    $SiteServer = ($defaultSiteServer,$SiteServer)[[bool]$SiteServer]

    # Customizations
    $initParams = @{}

    # Do not change anything below this line

    # Import the ConfigurationManager.psd1 module
    if((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
    }

    # Connect to the site's drive if it is not already present
    if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
    }

    # Set the current location to be the site code.
    Set-Location "$($SiteCode):\" @initParams
#endregion

Function Get-FileName($initialDirectory){
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) |
    Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “All files (*.*)| *.*”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
} #end function Get-FileName

$allCollections = Get-Content (Get-Filename -initialDirectory "C:fso") # "LVH00014", "LVH00015", "SMS00001"

Function Space {
    param ([int]$i, [int]$ii)
    $NoSpace = ($ii - $i)
	While ($NoSpace -gt 0){
		$gap = $gap + " "
		$NoSpace--
	}
	Write-Host $gap -NoNewline
}

Foreach ($collection in $allCollections){

    $divider = "---------------------------------------------------------------------------"
    Write-Host $divider
    $objCollection = Get-CMCollection -Id $collection
    Write-Host ("Getting Maintenance Windows for collection ") -NoNewline
    Write-Host -ForegroundColor Yellow $objCollection.Name -NoNewline
    Write-Host (" ["+$objCollection.CollectionID+"]")
    Write-Host $divider

    $runtime = Get-CMMaintenanceWindow -CollectionId $collection
    if ($runtime.servicewindowschedules -eq $null){
        Write-Host -ForegroundColor Red "No Maintenance Windows Found"
    }
    else{
        $convertedRuntime = Convert-CMSchedule -ScheduleString $runtime.servicewindowschedules -ErrorAction SilentlyContinue
    }

    $arrMaintenanceWindows = Get-CMMaintenanceWindow -CollectionId $objCollection.CollectionID
    foreach ($MW in $arrMaintenanceWindows){
        Write-Host ("MW Name: ") -NoNewline
        Write-Host -ForegroundColor Cyan $MW.Name -NoNewline
        space $MW.Name.Length 20
        Write-Host "Start time: " -NoNewline
        #Write-Host ($MW.StartTime.DayOfWeek+" "+$MW.StartTime) -NoNewline
        Write-Host -ForegroundColor Cyan (Get-Date -Date $mw.StartTime).ToLongDateString() -NoNewline
        space ((Get-Date -Date $mw.StartTime).ToLongDateString()).Length 30
        Write-Host -ForegroundColor Cyan (Get-Date -Date $mw.StartTime).ToLongTimeString() -NoNewline

        Switch ($MW.IsGMT){
            "True" {Write-Host " GMT" -NoNewline}
            "False" {Write-Host " Local time" -NoNewline}
        }

        space 10 11
        Write-Host ("[") -NoNewline
        Write-Host -ForegroundColor Cyan $MW.Duration -NoNewline
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
