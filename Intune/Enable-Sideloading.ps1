
#region -----------------------[ FUNCTIONS ]---------------------------------------------------------------------------
function Enable-Sideloading {
<#
    .SYNOPSIS
    Enables Sidelaoding of apps
    .DESCRIPTION
    ---[ MUST BE RUN WITH ELEVATED PRIVILEGES ]---
    Enables sideloading of applications in Windows 10.
    Being used to allow installations of custom/LOB .msix packaged apps.
    Since they are not published to the Microsoft Store, we need to enable sideloading.
    They are secured by using certificates.
    .EXAMPLE
    PS C:\Enable-Sideloading.ps1
    #>

    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    $Name1 = "AllowAllTrustedApps"
    $value1 = "1"
    New-ItemProperty -Path $registryPath -Name $name1 -Value $value1 -PropertyType DWORD -Force

    $Name2 = "AllowDevelopmentWithoutDevLicense"
    $value2 = "0"

    New-ItemProperty -Path $registryPath -Name $name2 -Value $value2 -PropertyType DWORD -Force
}

#endregion ------------------[ End Functions ]--------------------------------------------------------------------------


#region -----------------------[ EXECUTION ]---------------------------------------------------------------------------
Enable-Sideloading

#endregion ------------------[ End Execution ]--------------------------------------------------------------------------