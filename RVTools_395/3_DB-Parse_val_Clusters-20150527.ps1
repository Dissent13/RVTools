#
# Last Edited by Craig Straka
# Last Edited Date: 4/27/2015
#
# Objective: parse the hosts column in RVTools tabvDatastore export
#
# procedure: Must save tabvDatastore sheet to its own CSV file to import.
#
param ([string]$inDB,[string]$inXLS,[string]$environment,[string]$date)

function Import-Xls 
{ 
 
<# 
.SYNOPSIS 
Import an Excel file. 
 
.DESCRIPTION 
Import an excel file. Since Excel files can have multiple worksheets, you can specify the worksheet you want to import. You can specify it by number (1, 2, 3) or by name (Sheet1, Sheet2, Sheet3). Imports Worksheet 1 by default. 
 
.PARAMETER Path 
Specifies the path to the Excel file to import. You can also pipe a path to Import-Xls. 
 
.PARAMETER Worksheet 
Specifies the worksheet to import in the Excel file. You can specify it by name or by number. The default is 1. 
Note: Charts don't count as worksheets, so they don't affect the Worksheet numbers. 
 
.INPUTS 
System.String 
 
.OUTPUTS 
Object 
 
.EXAMPLE 
".\employees.xlsx" | Import-Xls -Worksheet 1 
Import Worksheet 1 from employees.xlsx 
 
.EXAMPLE 
".\employees.xlsx" | Import-Xls -Worksheet "Sheet2" 
Import Worksheet "Sheet2" from employees.xlsx 
 
.EXAMPLE 
".\deptA.xslx", ".\deptB.xlsx" | Import-Xls -Worksheet 3 
Import Worksheet 3 from deptA.xlsx and deptB.xlsx. 
Make sure that the worksheets have the same headers, or have some headers in common, or that it works the way you expect. 
 
.EXAMPLE 
Get-ChildItem *.xlsx | Import-Xls -Worksheet "Employees" 
Import Worksheet "Employees" from all .xlsx files in the current directory. 
Make sure that the worksheets have the same headers, or have some headers in common, or that it works the way you expect. 
 
.LINK 
Import-Xls 
http://gallery.technet.microsoft.com/scriptcenter/17bcabe7-322a-43d3-9a27-f3f96618c74b 
Export-Xls 
http://gallery.technet.microsoft.com/scriptcenter/d41565f1-37ef-43cb-9462-a08cd5a610e2 
Import-Csv 
Export-Csv 
 
.NOTES 
Author: Francis de la Cerna 
Created: 2011-03-27 
Modified: 2011-04-09 
#Requires –Version 2.0 
#> 
 
    [CmdletBinding(SupportsShouldProcess=$true)] 
     
    Param( 
        [parameter( 
            mandatory=$true,  
            position=1,  
            ValueFromPipeline=$true,  
            ValueFromPipelineByPropertyName=$true)] 
        [String[]] 
        $Path, 
     
        [parameter(mandatory=$false)] 
        $Worksheet = 1, 
         
        [parameter(mandatory=$false)] 
        [switch] 
        $Force 
    ) 
 
    Begin 
    { 
        function GetTempFileName($extension) 
        { 
            $temp = [io.path]::GetTempFileName(); 
            $params = @{ 
                Path = $temp; 
                Destination = $temp + $extension; 
                Confirm = $false; 
                Verbose = $VerbosePreference; 
            } 
            Move-Item @params; 
            $temp += $extension; 
            return $temp; 
        } 
             
        # since an extension like .xls can have multiple formats, this 
        # will need to be changed 
        # 
        $xlFileFormats = @{ 
            # single worksheet formats 
            '.csv'  = 6;        # 6, 22, 23, 24 
            '.dbf'  = 11;       # 7, 8, 11 
            '.dif'  = 9;        #  
            '.prn'  = 36;       #  
            '.slk'  = 2;        # 2, 10 
            '.wk1'  = 31;       # 5, 30, 31 
            '.wk3'  = 32;       # 15, 32 
            '.wk4'  = 38;       #  
            '.wks'  = 4;        #  
            '.xlw'  = 35;       #  
             
            # multiple worksheet formats 
            '.xls'  = -4143;    # -4143, 1, 16, 18, 29, 33, 39, 43 
            '.xlsb' = 50;       # 
            '.xlsm' = 52;       # 
            '.xlsx' = 51;       # 
            '.xml'  = 46;       # 
            '.ods'  = 60;       # 
        } 
         
        $xl = New-Object -ComObject Excel.Application; 
        $xl.DisplayAlerts = $false; 
        $xl.Visible = $false; 
    } 
 
    Process 
    { 
        $Path | ForEach-Object { 
             
            if ($Force -or $psCmdlet.ShouldProcess($_)) { 
             
                $fileExist = Test-Path $_ 
 
                if (-not $fileExist) { 
                    Write-Error "Error: $_ does not exist" -Category ResourceUnavailable;             
                } else { 
                    # create temporary .csv file from excel file and import .csv 
                    # 
                    $_ = (Resolve-Path $_).toString(); 
                    $wb = $xl.Workbooks.Add($_); 
                    if ($?) { 
                        $csvTemp = GetTempFileName(".csv"); 
                        $ws = $wb.Worksheets.Item($Worksheet); 
                        $ws.SaveAs($csvTemp, $xlFileFormats[".csv"]); 
                        $wb.Close($false); 
                        Remove-Variable -Name ('ws', 'wb') -Confirm:$false; 
                        Import-Csv $csvTemp; 
                        Remove-Item $csvTemp -Confirm:$false -Verbose:$VerbosePreference; 
                    } 
                } 
            } 
        } 
    } 
    
    End 
    { 
        $xl.Quit(); 
        Remove-Variable -name xl -Confirm:$false; 
        [gc]::Collect(); 
    } 
}

function Select-DB($cn,$rs)
{  
	$adOpenStatic = 3
	$adLockOptimistic = 3
	$cn.Open("Provider = Microsoft.ace.OLEDB.12.0;Data Source = $inDB")
	$rs.open("Select [tbl_vClusters].* from [tbl_vClusters]",$cn,$adOpenStatic,$adLockOptimistic)
}

$lines = Import-xls -Path $inXLS -Worksheet "vCluster"
$compareslines = Import-xls -Path $inXLS -Worksheet "vCluster"
#Connect to DB
$cn=New-Object -ComObject ADODB.connection
$rs=new-object -comobject ADODB.recordset
Select-DB $cn $rs

foreach($line in $lines)
{	
	$outMessage = $line.name
	echo $outMessage
	
	$rs.AddNew()
	$rs.Fields.Item("Name") = $line.'Name'
	$rs.Fields.Item("Config status") = $line.'Config status'
	$rs.Fields.Item("OverallStatus") = $line.'OverallStatus'
	$rs.Fields.Item("NumHosts") = $line.'NumHosts'
	$rs.Fields.Item("numEffectiveHosts") = $line.'numEffectiveHosts'
	$rs.Fields.Item("TotalCpu") = $line.'TotalCpu'
	$rs.Fields.Item("NumCpuCores") = $line.'NumCpuCores'
	$rs.Fields.Item("NumCpuThreads") = $line.'NumCpuThreads'
	$rs.Fields.Item("Effective Cpu") = $line.'Effective Cpu'
	$rs.Fields.Item("TotalMemory") = $line.'TotalMemory'
	$rs.Fields.Item("Effective Memory") = $line.'Effective Memory'
	$rs.Fields.Item("Num VMotions") = $line.'Num VMotions'
	$rs.Fields.Item("HA enabled") = $line.'HA enabled'
	$rs.Fields.Item("Failover Level") = $line.'Failover Level'
	$rs.Fields.Item("AdmissionControlEnabled") = $line.'AdmissionControlEnabled'
	$rs.Fields.Item("Host monitoring") = $line.'Host monitoring'
	$rs.Fields.Item("HB Datastore Candidate Policy") = $line.'HB Datastore Candidate Policy'
	$rs.Fields.Item("Isolation Response") = $line.'Isolation Response'
	$rs.Fields.Item("Restart Priority") = $line.'Restart Priority'
	$rs.Fields.Item("Cluster Settings") = $line.'Cluster Settings'
	if($line.'Max Failures') {$rs.Fields.Item("Max Failures") = $line.'Max Failures'}
	if($line.'Max Failure Window') {$rs.Fields.Item("Max Failure Window") = $line.'Max Failure Window'}
	if($line.'Failure Interval') {$rs.Fields.Item("Failure Interval") = $line.'Failure Interval'}
	if($line.'Min Up Time') {$rs.Fields.Item("Min Up Time") = $line.'Min Up Time'}
	$rs.Fields.Item("VM Monitoring") = $line.'VM Monitoring'
	$rs.Fields.Item("DRS enabled") = $line.'DRS enabled'
	$rs.Fields.Item("DRS default VM behavior") = $line.'DRS default VM behavior'
	$rs.Fields.Item("DRS vmotion rate") = $line.'DRS vmotion rate'
	$rs.Fields.Item("DPM enabled") = $line.'DPM enabled'
	$rs.Fields.Item("DPM default behavior") = $line.'DPM default behavior'
	$rs.Fields.Item("DPM Host Power Action Rate") = $line.'DPM Host Power Action Rate'
	$rs.Fields.Item("vCenter UUID") = $environment
	$rs.Update()
}

$rs.close()
$cn.close()