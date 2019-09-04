# Determine where to do the logging 
$TSEnv = New-Object -ComObject.Microsoft.SMS.TSEnvironment
$LogPath = $TSEnv.Value("_SMSTSLogPath")
$logFile = "$logPath\$($myInvocation.MyCommand).log" 

# Start the logging 
Start-Transcript $logFile 

# Write all the variables and their values 
$tsenv.GetVariables() | % { Write-Host "$_ = $($tsenv.Value($_))" } 

# Stop logging 
Stop-Transcript 