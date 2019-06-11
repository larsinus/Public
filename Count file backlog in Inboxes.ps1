
# The script is written to run on the site server

# SysInternal download - https://docs.microsoft.com/en-us/sysinternals/downloads/psexec
# the first time you run PsExec64.exe you need to add the switch -accepteula to be able to run with other switches

# To run as system to be able to count the files in the protected folders
#.\PsExec64.exe -i -s powershell.exe

[string]$SMSPath = ($env:SMS_LOG_PATH).TrimEnd("logs") + "Inboxes\"

$InboxList = Get-ChildItem -Path $SMSPath -Recurse | where PSIsContainer -eq "True" | select FullName

foreach ($inbox in $InboxList){
    $fileCount = (Get-ChildItem $inbox.FullName).count
    Write-Host ($inbox.FullName).TrimEnd($SMSPath) "[" -NoNewline
    Switch ($fileCount){
        0   {Write-Host -ForegroundColor Green $fileCount -NoNewline}
        {($_ -gt 0) -and ($_ -lt 6)} {Write-Host -ForegroundColor Yellow $fileCount -NoNewline}
        {$_ -gt 5} {Write-Host -ForegroundColor Red $fileCount -NoNewline}
    }
    Write-Host "]"
}