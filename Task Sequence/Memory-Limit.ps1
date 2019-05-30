switch (((gwmi Win32_ComputerSystem).TotalPhysicalMemory))
{
    {$_ -ge '8400031744'} {Return 0} #{"SUCCESS - 8GB or more of RAM"}
    {$_ -lt '8400031744'} {Return 1} #{"ERROR - Less than 8GB of RAM"}
}
