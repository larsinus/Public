 
#    .SYNOPSIS 
#       Used to set maintenance windows 
#    .DESCRIPTION 
#       Calculating second tuesday of any month and setting Maintenance window offset by any number of days/weeks 
#> 
 
#Run on Site server 
 
#region Initialising 
    # Site configuration
    $SiteCode = "LVH" # Site code 
    $ProviderMachineName = "MEM.larsinus.com" # SMS Provider machine name

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

#Parameters 
    $MonthArray = New-Object System.Globalization.DateTimeFormatInfo 
    $MonthNames = $MonthArray.MonthNames 
    #$CollectionID="LVH00014" 
    $arrCollectionIDs = "LVH00014","LVH00015"
    $PatchMonth=5 #Month 1..12 1=January..12=December 
    $OffSetDays=1 #Defer number of days after PT | E.G. 3=Friday (Tue+3days)
    $OffSetWeeks=0 #Defer number of weeks after PT week
  
#Set Patch Tuesday for a Month 
Function Get-PatchTuesday ([int] $Month)  
 { 
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
 
Function Set-PatchMW ([int]$PatchMonth, [int]$OffSetDays, [int] $OffSetWeeks, [string] $CollectionID) 
 { 
 
    #Set Patch Tuesday for each Month 
    $PatchDay=Get-PatchTuesday($PatchMonth) 
         
    #Set Maintenance Window Naming Convention (Months array starting from 0 hence the -1) 
    $MWName =  "MW."+$MonthNames[$PatchMonth-1]+".Week"+$OffSetWeeks 
 
    #Set Device Collection Maintenace interval  
    $StartTime=$PatchDay.AddDays($OffSetDays).AddMinutes(30) 
    $EndTime=$StartTime.Addhours(5).AddMinutes(30) 
 
    #Create The Schedule Token  
    $Schedule = New-CMSchedule -Nonrecurring -Start $StartTime.AddDays($OffSetWeeks*7) -End $EndTime.AddDays($OffSetWeeks*7) 
 
    #Set Maintenance Windows 
    New-CMMaintenanceWindow -CollectionID $CollectionID -Schedule $Schedule -Name $MWName -ApplyTo SoftwareUpdatesOnly 
} 
 
#Remove all existing Maintenance Windows for a Collection 
Function Remove-MaintnanceWindows ([string]$CollectionID)  
{ 
    Get-CMMaintenanceWindow -CollectionId $CollectionID | ForEach-Object { 
        Remove-CMMaintenanceWindow -CollectionID $CollectionID -Name $_.Name -Force 
        $Coll=Get-CMDeviceCollection -CollectionId $CollectionID 
        Write-Host "Removing MW:"$_.Name"- From Collection:"$Coll.Name 
    } 
} 


foreach ($collection in $arrCollectionIDs){
    $CollectionID = $collection
    #Remove Previous Maintenance Windows 
    Remove-MaintnanceWindows $CollectionID 
 
    #Set a single MW for a single collection
    #Set-PatchMW $PatchMonth $OffSetDays $OffSetWeeks $CollectionID 
 
    #Or use it like this for the whole Year 
    For ($Month = 1; $Month -le 12; $Month++){ 
        Set-PatchMW $Month $OffSetDays $OffSetWeeks $CollectionID 
    }
}
