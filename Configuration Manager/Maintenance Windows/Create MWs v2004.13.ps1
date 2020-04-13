<#
    Description:
        Used to set maintenance windows.
        Calculating second tuesday of any month and setting Maintenance window offset by any number of days/weeks.
        Using values specified in the .JSON file for each phase.

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
Function Space {
    param ([int]$i, [int]$ii)
    $NoSpace = ($ii - $i)
	While ($NoSpace -gt 0){
		$gap = $gap + " "
		$NoSpace--
	}
	Write-Host $gap -NoNewline
}

Function Get-FileName($initialDirectory){
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) |
    Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “All files (*.*)| *.*”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
} #end function Get-FileName

Function Get-PatchTuesday ([int] $Month){
    $FindNthDay=2 #Aka Second occurence
    $WeekDay='Tuesday'
    $Today=get-date -Month $Month
    $todayM=$Today.Month.ToString()
    $todayY=$Today.Year.ToString()
    [datetime]$StrtMonth=$todayM+'/1/'+$todayY
    while ($StrtMonth.DayofWeek -ine $WeekDay ) { $StrtMonth=$StrtMonth.AddDays(1) }
    $PatchDay=$StrtMonth.AddDays(7*($FindNthDay-1))
    return $PatchDay
}

Function Set-PatchMW ([int]$PatchMonth, [int]$OffSetDays, [int] $OffSetWeeks, [string] $CollectionID, [string] $MWType, [Boolean] $UTCorLocal, [Boolean] $EnabledOrNot){
    #Set Patch Tuesday for each Month
    $PatchDay=Get-PatchTuesday($PatchMonth)
    #Set Maintenance Window Naming Convention (Months array starting from 0 hence the -1)
    $MWName =  $MWPrefix+$MonthNames[$PatchMonth-1] #+".Week"+$OffSetWeeks
    #Set Device Collection Maintenace interval
    $StartTime=$PatchDay.AddDays($OffSetDays).AddHours($addStartHours).AddMinutes($addStartMinutes)
    $EndTime=$StartTime.Addhours($addDurationHours).AddMinutes($addDurationMinutes)
    #Create The Schedule Token
    $Schedule = New-CMSchedule -Nonrecurring -Start $StartTime.AddDays($OffSetWeeks*7) -End $EndTime.AddDays($OffSetWeeks*7)
    #Set Maintenance Windows
    New-CMMaintenanceWindow -CollectionID $CollectionID -Schedule $Schedule -Name $MWName -ApplyTo $MWType -IsEnabled $EnabledOrNot -IsUtc $UTCorLocal
}

Function Remove-MaintnanceWindows ([string]$CollectionID){
    Get-CMMaintenanceWindow -CollectionId $CollectionID | ForEach-Object {
        Remove-CMMaintenanceWindow -CollectionID $CollectionID -Name $_.Name -Force
        $Coll=Get-CMDeviceCollection -CollectionId $CollectionID
        Write-Host -ForegroundColor Cyan "[INFORMATION] " -NoNewline
        Write-Host "Removing Maintenance Window: " -NoNewline
        Write-Host -ForegroundColor Cyan $_.Name -NoNewline
        Space ($_.Name).length 12
        Write-Host " from Collection: " -NoNewline
        Write-Host -ForegroundColor Cyan $Coll.Name
    }
}

$MWSettings = Get-Content (Get-Filename -initialDirectory "C:fso") | ConvertFrom-Json
$today = Get-Date
$MWPrefix = "MW-"
$MonthArray = New-Object System.Globalization.DateTimeFormatInfo
$MonthNames = $MonthArray.MonthNames

foreach ($phase in $MWSettings){
    Write-Host -ForegroundColor Yellow ("Starting phase: "+$phase.phase)
    $arrCollectionIDs = ($phase.CollectionIDs).Split(',')
    $OffSetDays= $phase.OffsetDay #Defer number of days after PT | E.G. 3=Friday (Tue+3days)
    $OffSetWeeks= $phase.OffsetWeek #Defer number of weeks after PT week
    $addStartMinutes = $phase.StartTime.Split(':')[1]
    $addStartHours = $phase.StartTime.Split(':')[0]
    $addDurationMinutes = $phase.Duration.Split(':')[1]
    $addDurationHours = $phase.Duration.Split(':')[0]
    $MWType = $phase.MWType

    switch ($phase.isEnalbed){
        "True" { $EnabledOrNot = $true}
        "False" { $EnabledOrNot = $false}
    }
    switch ($phase.isUTC){
        "True" { $UTCorLocal = $true}
        "False" { $UTCorLocal = $false}
    }

    foreach ($collection in $arrCollectionIDs){
        Write-Host -ForegroundColor Yellow ("Working on collection "+$collection)
        if ((Get-PatchTuesday $today.Month) -le $today){
            $Month = $today.Month+1
        }
        else {
            $Month = $today.Month
        }

        # Remove Previous Maintenance Windows
        Remove-MaintnanceWindows $Collection

        # Create new Maintenance Windows
        For ($Month; $Month -le 12; $Month++){
            Set-PatchMW $Month $OffSetDays $OffSetWeeks $Collection $MWType $UTCorLocal $EnabledOrNot
        }
    }
}
