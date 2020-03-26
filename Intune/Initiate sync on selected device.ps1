$ModuleStatus = Get-Module -Name Microsoft.Graph.Intune
if ($null -eq $ModuleStatus) {
    Install-Module -Name Microsoft.Graph.Intune #-RequiredVersion 6.1902.1.
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
$selected = Read-Host "which device do you want to sync? (type the name)"
if ($selected -in $colDevices.devicename) {
    Invoke-DeviceManagement_ManagedDevices_SyncDevice -managedDeviceId (($colDevices | Where-Object {$_.devicename -eq $selected}).id)
    Write-Host -ForegroundColor Green ("INFO - Initiated sync on " + $selected)
}
else {
    Write-Host -ForegroundColor Red ("ERROR! Couldn't find device with name " + $selected)
}

