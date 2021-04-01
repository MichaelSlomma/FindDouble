<#

Findet doppelte Einträge in Archivmigrationslogs

#>

function selectFile ()
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filename = $filename
    $OpenFileDialog.Filter = "Logfiles|*.log"
    $OpenFileDialog.Title = "Datei auswählen"
    $OpenFileDialog.ShowDialog() | Out-Null

    return $OpenFileDialog.FileName
}

cls

Write-Host "" > cleanup.log

$LogFile = selectfile("")

$a = get-content $LogFile
$length = $a.count
$counter = 0

foreach ($content in $a)
{
$counter++
$String = $content.Remove(0,53)
$String.Trim() >> .\cleanup.log
Write-Progress -Activity “bereinige Datensatz $counter von $length” -status $content -PercentComplete (100/$counter)
}


$a = get-content .\cleanup.log

$duplicates = 0

$ht = @{}
$a | foreach {$ht["$_"] += 1}
$ht.keys | where {$ht["$_"] -gt 1} | foreach {if ($_ -ne "Start Migration:"){write-host "Duplicate element found  $_" ; $duplicates++}}
write-host "Insgesamt $duplicates Duplikate gefunden"