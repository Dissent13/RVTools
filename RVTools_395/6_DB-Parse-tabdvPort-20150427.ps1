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
	$rs.open("Select [tabdvPort].* from [tabdvPort]",$Cn,$adOpenStatic,$adLockOptimistic)
}

$lines = Import-xls -Path $inXLS -Worksheet "dvPort"

$cn=New-Object -ComObject ADODB.connection
$rs=new-object -ComObject ADODB.recordset
Select-DB $cn $rs

foreach($line in $lines)
{	
	if($line.'Switch')
	{
		$outMessage = $line.'Port' + "	" + $line.'Switch'
		echo $outMessage
		
		$rs.AddNew()

		$rs.Fields.Item("Port") = $line.'Port'
		$rs.Fields.Item("Switch") = $line.'Switch'
		$rs.Fields.Item("Type") = $line.'Type'
		$rs.Fields.Item("# Ports") = $line.'# Ports'
		$rs.Fields.Item("VLAN") = $line.'VLAN'
		$rs.Fields.Item("Speed") = $line.'Speed'
		$rs.Fields.Item("Full Duplex") = $line.'Full Duplex'
		$rs.Fields.Item("Blocked") = $line.'Blocked'
		$rs.Fields.Item("Allow Promiscuous") = $line.'Allow Promiscuous'
		$rs.Fields.Item("Mac Changes") = $line.'Mac Changes'
		$rs.Fields.Item("Active Uplink") = $line.'Active Uplink'
		$rs.Fields.Item("Standby Uplink") = $line.'Standby Uplink'
		$rs.Fields.Item("Policy") = $line.'Policy'
		$rs.Fields.Item("Forged Transmits") = $line.'Forged Transmits'
		$rs.Fields.Item("In Traffic Shapping") = $line.'In Traffic Shapping'
		$rs.Fields.Item("In Avg") = $line.'In Avg'
		$rs.Fields.Item("In Peak") = $line.'In Peak'
		$rs.Fields.Item("In Burst") = $line.'In Burst'
		$rs.Fields.Item("Out Trafic Shaping") = $line.'Out Trafic Shaping'
		$rs.Fields.Item("Out Avg") = $line.'Out Avg'
		$rs.Fields.Item("Out Peak") = $line.'Out Peak'
		$rs.Fields.Item("Out Burst") = $line.'Out Burst'
		$rs.Fields.Item("Reverse Policy") = $line.'Reverse Policy'
		$rs.Fields.Item("Notify Switch") = $line.'Notify Switch'
		$rs.Fields.Item("Rolling Order") = $line.'Rolling Order'
		$rs.Fields.Item("Check Beacon") = $line.'Check Beacon'
		$rs.Fields.Item("Live Port Moving") = $line.'Live Port Moving'
		$rs.Fields.Item("Check Duplex") = $line.'Check Duplex'
		$rs.Fields.Item("Check Error %") = $line.'Check Error %'
		$rs.Fields.Item("Check Speed") = $line.'Check Speed'
		$rs.Fields.Item("Percentage") = $line.'Percentage'
		$rs.Fields.Item("Block Override") = $line.'Block Override'
		$rs.Fields.Item("Config Reset") = $line.'Config Reset'
		$rs.Fields.Item("Shaping Override") = $line.'Shaping Override'
		$rs.Fields.Item("Vendor Config Override") = $line.'Vendor Config Override'
		$rs.Fields.Item("Sec Policy Override") = $line.'Sec Policy Override'
		$rs.Fields.Item("Teaming Override") = $line.'Teaming Override'
		$rs.Fields.Item("Vlan Override") = $line.'Vlan Override'
		$rs.Fields.Item("vCenter UUID") = $line.'VI SDK UUID'

		$rs.Update()
	}
}		

$rs.close()
$cn.close()