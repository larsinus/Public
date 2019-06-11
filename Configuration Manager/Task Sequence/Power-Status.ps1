Switch ((gwmi Win32_Battery).BatteryStatus)
{
    {$_ -in '2','6','7','8'} {return 0} # Success - plugged in and charging
    '3' {return 1} # Warning - Fully charged, but not on plugged in
    default {return 2} # Error
}
