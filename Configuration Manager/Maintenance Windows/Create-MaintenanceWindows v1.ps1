﻿ 
#    .SYNOPSIS 
#       Used to set maintenance windows 
#    .DESCRIPTION 
#       Calculating second tuesday of any month and setting Maintenance window offset by any number of days/weeks 
#> 
 
#Run on Site server 
 
#region Initialising 
    # Site configuration
    $SiteCode = Read-Host "Site Code" # "LVH" # Site code 
    $ProviderMachineName = Read-Host "Site Server FQDN" # "MEM.larsinus.com" # SMS Provider machine name

    # Customizations
    $initParams = @{}
    #$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
    #$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

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

function Get-IniFile {  
    param(  
        [parameter(Mandatory = $true)] [string] $filePath  
    )  

    $anonymous = "NoSection"

    $ini = @{}  
    switch -regex -file $filePath  
    {  
        "^\[(.+)\]$" # Section  
        {  
            $section = $matches[1]  
            $ini[$section] = @{}  
            $CommentCount = 0  
        }  

        "^(;.*)$" # Comment  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $value = $matches[1]  
            $CommentCount = $CommentCount + 1  
            $name = "Comment" + $CommentCount  
            $ini[$section][$name] = $value  
        }   

        "(.+?)\s*=\s*(.*)" # Key  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $name,$value = $matches[1..2]  
            $ini[$section][$name] = $value  
        }  
    }  

    return $ini  
}  

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

Function Set-PatchMW ([int]$PatchMonth, [int]$OffSetDays, [int] $OffSetWeeks, [string] $CollectionID){ 
    #Set Patch Tuesday for each Month 
    $PatchDay=Get-PatchTuesday($PatchMonth) 
    #Set Maintenance Window Naming Convention (Months array starting from 0 hence the -1) 
    $MWName =  $MWPrefix+$MonthNames[$PatchMonth-1] #+".Week"+$OffSetWeeks 
    #Set Device Collection Maintenace interval  
    $StartTime=$PatchDay.AddDays($OffSetDays).AddMinutes(30) 
    $EndTime=$StartTime.Addhours(5).AddMinutes(30) 
    #Create The Schedule Token  
    $Schedule = New-CMSchedule -Nonrecurring -Start $StartTime.AddDays($OffSetWeeks*7) -End $EndTime.AddDays($OffSetWeeks*7) 
    #Set Maintenance Windows 
    New-CMMaintenanceWindow -CollectionID $CollectionID -Schedule $Schedule -Name $MWName -ApplyTo SoftwareUpdatesOnly
} 

Function Remove-MaintnanceWindows ([string]$CollectionID){ 
    Get-CMMaintenanceWindow -CollectionId $CollectionID | ForEach-Object { 
        Remove-CMMaintenanceWindow -CollectionID $CollectionID -Name $_.Name -Force 
        $Coll=Get-CMDeviceCollection -CollectionId $CollectionID 
        Write-Host -ForegroundColor Cyan "[INFORMATION] " -NoNewline
        Write-Host "Removing Maintenance Window:" -NoNewline
        Write-Host -ForegroundColor Cyan $_.Name -NoNewline
        Write-Host "- From Collection:" -NoNewline
        Write-Host -ForegroundColor Cyan $Coll.Name 
    } 
}

$MWSettings = Get-IniFile (Get-Filename -initialDirectory "C:fso") # "G:\Library\Scripts\MWSettings.ini"
$today = Get-Date
$MWPrefix = "MW-"
$MonthArray = New-Object System.Globalization.DateTimeFormatInfo 
$MonthNames = $MonthArray.MonthNames

foreach ($phase in $MWSettings.Keys){
    Write-Host -ForegroundColor Yellow ("Starting phase: "+$phase)
    $arrCollectionIDs = ($MWSettings.$phase.CollectionIDs).Split(',')
    $OffSetDays= $MWSettings.$phase.OffsetDay #Defer number of days after PT | E.G. 3=Friday (Tue+3days)
    $OffSetWeeks= $MWSettings.$phase.OffsetWeek #Defer number of weeks after PT week

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
            Set-PatchMW $Month $OffSetDays $OffSetWeeks $Collection
        }
    }
}





