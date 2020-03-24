
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# Tell Powershell to ignore any errors that may fill up the screen.
$ErrorActionPreference = 'silentlycontinue'

##########################################################################
#VARIABLES
##########################################################################
$TextFile = <Path To TextFile>
$CollectionID = <ID of Collection>
##########################################################################

$ComputerList = Get-Content $TextFile #text file contains only server names

Foreach($Computer in $ComputerList)
{
	Write-Host $Computer -Foreground green -Background Black
	Add-CMDeviceCollectionDirectMembershipRule -CollectionID $CollectionID -ResourceId (Get-CMDevice -Name $Computer).ResourceID
}

Write-Host "Complete" -Foreground magenta -Background black
Write-Host ""