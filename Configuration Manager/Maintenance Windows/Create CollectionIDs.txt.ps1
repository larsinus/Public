<#
    .SYNOPSIS
    Used to create a .txt file with CollectionID's from Microsoft Endpoint Manager

    .DESCRIPTION
    The script can be run using only the name or with a parameter labeled 'filter'
    The filter can be part of or the entire name of the collection.
    It will find all CollectionID's for collections containing the filter supplied.

    Make sure to open PowerShell from Microsoft Endpoint Manager and run the default (pop up) script.
    You will now have a drive labeled the same as your site code. Now you can run the script.

    .EXAMPLE
    PS LVH:\<Script Path>\&'.\Create CollectionID Input file.ps1'
    Finds all the CollectionID's in your environment and will prompt you with what to label the file and where to save it.

    .EXAMPLE
    PS LVH:\<Script Path>\&'.\Create CollectionID Input file.ps1' -filter SUM
    Finds all CollectionID's that have a Collection Name containing the phrase 'SUM' and will prompt you with what to
    label the file and where to save it.
#>

param (
    $Filter
)

function Save-File {
    param (
        [parameter()]
        $path = 'C:fso'
    )
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”)
    Out-Null
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.initialDirectory = $path
    $SaveFileDialog.filter = “All files (*.txt)| *.txt”
    $result = $SaveFileDialog.ShowDialog()
    if ($result -eq 'OK'){
        Out-File -FilePath $SaveFileDialog.filename -InputObject $arrCollections
    }
}

$arrCollections = (Get-CMCollection | Where-Object name -Match $Filter).CollectionID
Save-File
