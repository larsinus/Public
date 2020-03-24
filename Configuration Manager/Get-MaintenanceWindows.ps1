#Get-CMCollection | select name, collectionid
$allCollections = "LVH00014", "LVH00015"


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
    $runtime = Get-CMMaintenanceWindow -CollectionId $collection
    $convertedRuntime = Convert-CMSchedule -ScheduleString $runtime.servicewindowschedules -ErrorAction SilentlyContinue
    
    $divider = "---------------------------------------------------------------------------"
    Write-Host $divider
    $objCollection = Get-CMCollection -Id $collection
    Write-Host ("Getting Maintenance Windows for collection ") -NoNewline
    Write-Host -ForegroundColor Yellow $objCollection.Name -NoNewline
    Write-Host (" ["+$objCollection.CollectionID+"]")
    Write-Host $divider
    
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
}

# ServiceWindowsType: 4=SU only, 1=All Deployments


# example output
#------------------------------------------------------------------------------------------------------
# SmsProviderObjectPath  : SMS_ServiceWindow.ServiceWindowID="{F699B947-59C0-4BFB-8277-C0CC979465DB}"
# Description            : Occurs on 8/12/2020 12:30 AM
# Duration               : 330
# IsEnabled              : True
# IsGMT                  : False
# Name                   : MW.August.Week0
# RecurrenceType         : 1
# ServiceWindowID        : {F699B947-59C0-4BFB-8277-C0CC979465DB}
# ServiceWindowSchedules : 780C8C9E28080000
# ServiceWindowType      : 4
# StartTime              : 8/12/2020 12:30:00 AM

