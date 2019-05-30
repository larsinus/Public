Install-Module AzureAD
Install-Module WindowsAutopilotIntune 
Import-Module WindowsAutopilotIntune

Connect-AutopilotIntune

$AutopilotProfile = Get-AutopilotProfile

$AutopilotProfile | ForEach-Object { $_ | ConvertTo-AutoPilotConfigurationJSON | Set-Content -Encoding Ascii "~\Desktop\$($_.displayName).json" }

# copy the .json file to this location:
# C:\Windows\Provisioning\Autopilot