
switch ((gwmi Win32_ComputerSystemProduct).Version)
{
    {$_ -match 'X2'} {return 0}
    {$_ -match '7.0'} {return 0}
    {$_ -match 'T61'} {return 0}

    #{$_ -in 'X1','7.0','T61'} {return 0} # 
    
    Default {return 1}
}

