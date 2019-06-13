
CLS

$Computer = "." #"<Name of computer>"

# RaaS+ issue >> A Process Working Set Size Is Large (>1073741824)
# ----------------------------------------------------------------
IF ((Get-Process -ComputerName $Computer).WorkingSet -gt 1073741824){
    Write-Host -ForegroundColor Red "A Process Working Set Size Is Large (>1.073.741.824 bytes)"
    Get-Process -ComputerName $Computer | Where-Object {$_.WorkingSet -gt 1073741824} | Select Name, id, HandleCount, WorkingSet, PagedMemorySize | ft -AutoSize
}
Else {
    Write-Host -ForegroundColor Green "All Working Set Sizes are at an acceptable level"
}

# RaaS+ issue >> Process Handle Count Is Large (>10000)
# ----------------------------------------------------------------
IF ((Get-Process -ComputerName $Computer).HandleCount -gt 10000){
    Write-Host -ForegroundColor Red "Process Handle Count Is Large (>10.000)"
    (Get-Process -ComputerName $Computer | Where-Object {$_.HandleCount -gt 10000} | Select Name, id, HandleCount, WorkingSet, PagedMemorySize | ft -AutoSize)
}
Else {
    Write-Host -ForegroundColor Green "All Process Handle Counts are at an acceptable level"
}