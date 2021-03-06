# Master control for RVTools .xls import to .ACCDB format
# Must use .xls import generated from RVTools version 3.9.5
# Written by Craig Straka

# Must run from the location of all the scripts (so ./ works)
if($csv) {$csv = $null}
if($DB) {$DB = $null}
if($environment) {$environment = $null}

function get-infile($initialDirectory)
{
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = "c:\"
 $OpenFileDialog.filter = "All files (*.xls*)| *.xls*"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
}

Function get-InDatabase($initialDirectory)
{   
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = "c:\"
 $OpenFileDialog.filter = "All files (*.accdb)| *.accdb"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
}

$inXLS = get-infile $inputDirectory.SelectedPath
$inDB = get-InDatabase $outputDirectory.SelectedPath
$date = (Get-Date).tostring('yyyyMMdd')

$vCenter = Read-Host -prompt "Enter the vCenter Name:"
Write-Host $inXLS
Write-Host $inDB
Write-Host $vCenter
Write-Host $date

echo "*** Environment ***"
[string]$environment = ./1_DB-vCenter-20150427.ps1 $inDB $inXLS $date $vCenter
Write-Host $environment
echo "*** DataCenters ***"
./2_DB-Parse_val_DataCenters-20150527.ps1 $inDB $inXLS $environment $date
echo "*** Clusters ***"
./3_DB-Parse_val_Clusters-20150527.ps1 $inDB $inXLS $environment $date
echo "*** vHost ***"
./4_DB-Parse_tabvHost-20150427.ps1 $inDB $inXLS $environment $date
echo "*** Standalone vHost ***"
./45_StandAloneHosts_to_Clusters-20150527.ps1 $inDB $inXLS $environment $date
echo "*** dVSwitch ***"
./5_DB-Parse-tabdvSwitch-20150427.ps1 $inDB $inXLS $environment $date
echo "*** dVport ***"
./6_DB-Parse-tabdvPort-20150427.ps1 $inDB $inXLS $environment $date
echo "*** vInfo ***"
./7_DB-Parse_tabvInfo-20150427.ps1 $inDB $inXLS $environment $date
echo "*** DataStores ***"
./8_DB-Parse-tabvDatastores-20150427.ps1 $inDB $inXLS $environment $date
echo "*** vHBA ***"
./9_DB-Parse-tabvHBA-20150427.ps1 $inDB $inXLS $environment $date
echo "*** vNIC ***"
./10_DB-Parse-tabvNIC-20150427.ps1 $inDB $inXLS $environment $date
echo "*** sVSwitch ***"
./11_DB-Parse-tabvSwitch-20150427.ps1 $inDB $inXLS $environment $date
echo "*** vDisk ***"
./12_DB-Parse-tabvDisk-20150427.ps1 $inDB $inXLS $environment $date
echo "*** vTools ***"
./13_DB-Parse-tabvTools-20150427.ps1 $inDB $inXLS $environment $date
echo "*** sVs Port ***"
./14_DB-Parse-tabvPort-20150427.ps1 $inDB $inXLS $environment $date
echo "*** SC_VMK ***"
./15_DB-Parse-tabvSC_VMK-20150427.ps1 $inDB $inXLS $environment $date
echo "*** Partition ***"
./16_DB-Parse-tabvPartition-20150427.ps1 $inDB $inXLS $environment $date