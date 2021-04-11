#
# Findet doppelte Einträge in Archivmigrationslogs
# 
# (c) 2021 H&H Datenverarbeitungs- und Beratungsgesellschaft mbH
# 
# Autor: Michael Slommma
#

###########################################################################################

param(
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String[]]
    $parameter
)

###########################################################################################

function find_double()
{
<#
Jetzt müssen wir jeden einzelnen Log-Eintrag erstmal um die ersten 53 Zeichen
kürzen. Das ist der Timestamp der jeweiligen Aktion. Der ändert sich ja permantent
und würde damit eine Duplikatserkennung unmöglich machen.
#>
Write-Host "Bereite Dateien vor..."
foreach ($file in $logfiles)
{
    $content = get-content $file
    foreach ($row in $content)
        {
            $dummy = $analyse.Add( ($row.Remove(0,53)).trim() )
        }
}

<#
Über ein HashTable suchen wir nun die Duplikate, indem wir für jeden gefundenen Hash den Wert in der Tabelle um 1 erhöhen.
Werte >1 verweisen auf Duplikate
Zeilen die mit "Start Migration" beginnen lassen wir dabei unberücksichtigt, da sie das Ergebnis verfälschen würden.
#>
Write-Host "Suche Duplikate..."
$ht = @{}
$analyse | foreach {$ht["$_"] += 1}
$ht.keys | where {$ht["$_"] -gt 1 -and $_ -ne "Start Migration:"} | foreach { $dummy = $output.Add( $_ ) ; $duplicates++ }

#
# Das Ergebnis der Analyse schreiben wir dann in eine Log-Datei.
#
$output | Out-File -FilePath $duplicateslog
"`n`rInsgesamt $duplicates Duplikate gefunden" >> $duplicateslog
Write-Host "`n`rInsgesamt $duplicates Duplikate gefunden"
}

function find_errors()
{
    $filtertext = @('Import:', 'Export:', 'Start')
    Write-Host "Werte Dateien aus..."
    foreach ($file in $logfiles)
    {
        $content = get-content $file
        foreach ($row in $content)
            {
                if ( $null -eq ($filtertext | ? { $row -match $_ })) { $dummy = $output.Add( $row ) }
            }
    }
    $output | Out-File -FilePath $errorlog
}

###########################################################################################

[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "Logfiles|archivmigration*.log"
$OpenFileDialog.Title = "Datei(en) auswählen"
$OpenFileDialog.Multiselect = $true
$OpenFileDialog.ShowDialog() | Out-Null
$LogFiles = $OpenFileDialog.FileNames

[ARRAY]$dummyarray=""
[System.Collections.ArrayList]$analyse = $dummyarray
[System.Collections.ArrayList]$output = $dummyarray

$timestamp = Get-Date -format "yyyyMMdd_HHmmss"
$duplicateslog = ".\Duplikate_"+$timestamp+".log"
$errorlog = ".\Fehler_"+$timestamp+".log"
$starttime = Get-Date

switch ($parameter)
{
    "double" {find_double("")}
    "error" {find_errors("")}
}

#
# Auswertung und Abschluss
#
$endtime = Get-Date
$timedifference = $endtime - $starttime
$runningtime = [math]::Round($timedifference.TotalSeconds,3)

Write-Host "`n`rVerarbeitungszeit: $runningtime Sekunden"
Read-Host “`n`r`n`rZum Beenden <Enter> drücken”