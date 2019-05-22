

# functions
function Get-IniContent ($filePath){
    $ini = @{}
    switch -regex -file $FilePath
    {
        “^\[(.+)\]” # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        “^(;.*)$” # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = “Comment” + $CommentCount
            $ini[$section][$name] = $value
        } 
        “(.+?)\s*=(.*)” # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

# The SMSPublicRootKey should match...
$MobileClientTcf = Get-IniContent("\\CM\E$\Microsoft Configuration Manager\bin\i386\MobileClient.tcf")
$serverSide = ($MobileClientTcf["Site"].'   SMSPublicRootKey').Trim()
#Get-Content -Path \\CM\E$\Microsoft Configuration Manager\bin\i386\MobileClient.tcf

# ...the TrustedRootKey
$clientSide = (Get-WmiObject -Namespace root\ccm\locationservices -Class TrustedRootKey).TrustedRootKey

if ($clientSide -eq $serverSide){
    Write-Host -ForegroundColor Green "SMSPublicRootKey is verified against the client's TrustedRootKey"
    Write-Host $serverSide
}
