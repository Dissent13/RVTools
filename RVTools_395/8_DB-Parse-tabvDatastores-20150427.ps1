#
# Last Edited by Craig Straka
# Last Edited Date: 4/27/2015
#
# Objective: parse the hosts column in RVTools tabvDatastore export
#
# procedure: Must save tabvDatastore sheet to its own CSV file to import.
#
param ([string]$inDB,[string]$inXLS,[string]$environment,[string]$date)
#$inDB = 'C:\Users\cstraka\Google Drive\Scripts\RVTools\output\RVTools-Dignity 20161116.accdb'
#$inXLS = 'C:\Users\cstraka\Google Drive\Scripts\RVTools\input\phx-vc-505.xls'
#$environment = 'F5E10D08-A36A-4105-AFD3-7F7B4FB0C893'
#$date = (Get-Date).tostring('yyyyMMdd')
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
	$rs.open("Select [tabvDatastore].* from [tabvDatastore]",$Cn,$adOpenStatic,$adLockOptimistic)
}

$lines = Import-xls -Path $inXLS -Worksheet "vDatastore"

$cn=New-Object -ComObject ADODB.connection
$rs=new-object -comobject ADODB.recordset
Select-DB $cn $rs

foreach($line in $lines)
{	
	$esxHosts = $line.Hosts.tostring() -split(",")
	foreach($esxHost in $esxHosts)
	{
		$outMessage = $line.Name + "	" + $line.Address + "	" + $line.Accessible + "	" + $line.Type + "	" + $line.'# VMs' + "	" + $line.'Capacity MB' + "	" + $line.'Provisioned MB' + "	" + $line.'In Use MB' + "	" + $line.'Free MB' + "	" + $line.'Free %' + "	" + $line.'SIOC enabled' + "	" + $line.'SIOC Threshold' + "	" + $line.'# Hosts' + "	" + $esxHost + "	" + $line.'Block size' + "	" + $line.'Max Blocks' + "	" + $line.'# Extents' + "	" + $line.'Major Version' + "	" + $line.'Version' + "	" + $line.'VMFS Upgradeable' + "	" + $line.MHA + "	" + $line.URL
		echo $outMessage
		
		$rs.AddNew()
		$rs.Fields.Item("Name") = $line.Name
		$rs.Fields.Item("Address") = $line.Address
		$rs.Fields.Item("Accessible") = $line.Accessible
		$rs.Fields.Item("Type") = $line.Type
		$rs.Fields.Item("# VMs") = $line.'# VMs'
		$rs.Fields.Item("Capacity MB") = $line.'Capacity MB'
		$rs.Fields.Item("Provisioned MB") = $line.'Provisioned MB'
		$rs.Fields.Item("In Use MB") = $line.'In Use MB'
		$rs.Fields.Item("Free MB") = $line.'Free MB'
		$rs.Fields.Item("Free %") = $line.'Free %'
		if($line.'SIOC enabled') {$rs.Fields.Item("SIOC enabled") = $line.'SIOC enabled'}
		if($line.'SIOC Threshold') {$rs.Fields.Item("SIOC Threshold") = $line.'SIOC Threshold'}
		$rs.Fields.Item("# Hosts") = $line.'# Hosts'
		$rs.Fields.Item("Hosts") = $esxHost
		$rs.Fields.Item("Block size") = $line.'Block size'
		$rs.Fields.Item("Max Blocks") = $line.'Max Blocks'
		$rs.Fields.Item("# Extents") = $line.'# Extents'
		$rs.Fields.Item("Major Version") = $line.'Major Version'
		if($line.'Version') {$rs.Fields.Item("Version") = $line.'Version'}
		$rs.Fields.Item("VMFS Upgradeable") = $line.'VMFS Upgradeable'
		$rs.Fields.Item("MHA") = $line.MHA
		$rs.Fields.Item("URL") = $line.URL
 		$rs.Update()	
	}		
}

$rs.close()
$cn.close()