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
	$rs.open("Select [tabvInfo].* from [tabvInfo]",$Cn,$adOpenStatic,$adLockOptimistic)
}

$lines = Import-xls -Path $inXLS -Worksheet "vInfo"

$cn=New-Object -ComObject ADODB.connection
$rs=new-object -ComObject ADODB.recordset
Select-DB $cn $rs

foreach($line in $lines)
{	
	$rs.AddNew()
	$rs.Fields.Item("VM") = $line.'VM'
	$rs.Fields.Item("DNS Name") = $line.'DNS Name'
	$rs.Fields.Item("Powerstate") = $line.'Powerstate'
	$rs.Fields.Item("Heartbeat") = $line.'Heartbeat'
	$rs.Fields.Item("Consolidation Needed") = $line.'Consolidation Needed'
	$rs.Fields.Item("PowerOn") = $line.'PowerOn'
	$rs.Fields.Item("CPUs") = $line.'CPUs'
	$rs.Fields.Item("Memory") = $line.'Memory'
	$rs.Fields.Item("NICs") = $line.'NICs'
	$rs.Fields.Item("Disks") = $line.'Disks'
	$rs.Fields.Item("Network #1") = $line.'Network #1'
	$rs.Fields.Item("Network #2") = $line.'Network #2'
	$rs.Fields.Item("Network #3") = $line.'Network #3'
	$rs.Fields.Item("Network #4") = $line.'Network #4'
	if($line.'Resource pool')
	{
		$rs.Fields.Item("Resource pool") = $line.'Resource pool'
	}
	$rs.Fields.Item("Folder") = $line.'Folder'
	if($line.'vApp')
	{
		$rs.Fields.Item("vApp") = $line.'vApp'
	}
	if($line.'FT State')
	{
		$rs.Fields.Item("FT State") = $line.'FT State'
	}
	if($line.'FT Latency')
	{
		$rs.Fields.Item("FT Latency") = $line.'FT Latency'
	}
	if($line.'FT Bandwidth')
	{
		$rs.Fields.Item("FT Bandwidth") = $line.'FT Bandwidth'
	}
	if($line.'FT Sec Latency')
	{
		$rs.Fields.Item("FT Sec Latency") = $line.'FT Sec Latency'
	}
	$rs.Fields.Item("Boot Required") = $line.'Boot Required'
	$rs.Fields.Item("Provisioned MB") = $line.'Provisioned MB'
	$rs.Fields.Item("In Use MB") = $line.'In Use MB'
	$rs.Fields.Item("Unshared MB") = $line.'Unshared MB'
	
	$VMXDS = $line.'Path'.tostring() -Split {$_ -eq "[" -or $_ -eq "]"}
	$rs.Fields.Item("VMXDS") = $VMXDS[1]
	$rs.Fields.Item("VMXPath") = $VMXDS[2]
	
	$rs.Fields.Item("Annotation") = $line.'Annotation'
	$rs.Fields.Item("NB_LAST_BACKUP") = $line.'NB_LAST_BACKUP'
	if($line.'Datacenter')
	{
		$rs.Fields.Item("Datacenter") = $line.'Datacenter'
	}
	if($line.'Cluster')
	{
		$rs.Fields.Item("Cluster") = $line.'Cluster'
	}
	else
	{
		$rs.Fields.Item("Cluster") = $line.'Host'
	}
	$rs.Fields.Item("Host") = $line.'Host'
	$rs.Fields.Item("VMOS") = $line.'OS according to the configuration file'
	$rs.Fields.Item("OS") = $line.'OS according to the VMware Tools'
	$rs.Fields.Item("VM Version") = $line.'VM Version'
	$rs.Fields.Item("VM UUID") = $line.'UUID'
	$rs.Fields.Item("Object ID") = $line.'Object ID'
	$rs.Fields.Item("vCenter UUID") = $environment
	$rs.Update()
	
	$outMessage = $line.VM + "	" + $VMXDS[1] + "	" + $VMXDS[2]
	echo $outMessage
}		

$rs.close()
$cn.close()