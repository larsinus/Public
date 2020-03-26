
$ModuleStatus = Get-Module -Name Microsoft.Graph.Intune
if ($null -eq $ModuleStatus) {
    Install-Module -Name Microsoft.Graph.Intune -RequiredVersion 6.1902.1.
}

If ($null -eq $creds){
    $creds = Get-Credential
    Connect-MSGraph -Credential $creds
}

$colDevices = @{}
$colDevices = Get-IntuneManagedDevice
Write-Host "*** Device List ***"
Write-Host "-------------------"
Foreach ($device in $colDevices){
    Write-Host -ForegroundColor Cyan $device.deviceName
}
$selected = Read-Host "which device do you want to wipe? (type the name)"
if ($selected -in $colDevices.devicename) {
    Write-Host -ForegroundColor Red "WARNING! " -NoNewline
    Write-Host "Are you sure you want to " -NoNewline
    Write-Host -ForegroundColor Red "WIPE " -NoNewline
    Write-Host "the computer labeled " -NoNewline
    Write-Host -ForegroundColor Cyan ($selected + " ") -NoNewline
    $wipeVerification = Read-Host "(Y/N)"
    if ($wipeVerification -ieq "y") {
        Invoke-DeviceManagement_ManagedDevices_Wipe -managedDeviceId (($colDevices | Where-Object {$_.devicename -eq $selected}).id)
        Write-Host -ForegroundColor Green ("INFO - Initiated WIPE on " + $selected)
    }
}
else {
    Write-Host -ForegroundColor Red ("ERROR! Couldn't find device with name " + $selected)
}