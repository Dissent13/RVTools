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
	$rs.open("Select [tabvDisk].* from [tabvDisk]",$Cn,$adOpenStatic,$adLockOptimistic)
}

$lines = Import-xls -Path $inXLS -Worksheet "vDisk"

$cn=New-Object -ComObject ADODB.connection
$rs=new-object -ComObject ADODB.recordset
Select-DB $cn $rs

foreach($line in $lines)
{	
	$rs.AddNew()
	$rs.Fields.Item("VM") = $line.'VM'
	$rs.Fields.Item("Disk") = $line.'Disk'
	$rs.Fields.Item("Capacity MB") = $line.'Capacity MB'
	$rs.Fields.Item("Raw") = $line.'Raw'
	$rs.Fields.Item("Disk Mode") = $line.'Disk Mode'
	$rs.Fields.Item("Thin") = $line.'Thin'
	$rs.Fields.Item("Eagerly Scrub") = $line.'Eagerly Scrub'
	$rs.Fields.Item("Split") = $line.'Split'
	$rs.Fields.Item("Write Through") = $line.'Write Through'
	$rs.Fields.Item("Level") = $line.'Level'
	if($line.'Shares') {$rs.Fields.Item("Shares") = $line.'Shares'}
	$rs.Fields.Item("Controller") = $line.'Controller'
	$rs.Fields.Item("Unit #") = $line.'Unit #'
	
	$datastore = $line.'Path'.tostring() -Split {$_ -eq "[" -or $_ -eq "]"}
	$rs.Fields.Item("Datastore") = $datastore[1]
	$rs.Fields.Item("Path") = $datastore[2]

	$rs.Fields.Item("Raw LUN ID") = $line.'Raw LUN ID'
	$rs.Fields.Item("Raw Comp Mode") = $line.'Raw Comp Mode'
	if ($line.'Annotation')
	{
		$annotation = $line.'Annotation'
	}
	$rs.Fields.Item("Tier") = $line.'Tier'
	$rs.Fields.Item("App Owner") = $line.'App Owner'
	$rs.Fields.Item("App Name") = $line.'App Name'
	$rs.Fields.Item("Build Date") = $line.'Build Date'
	$rs.Fields.Item("NB_LAST_BACKUP") = $line.'NB_LAST_BACKUP'
#	$rs.Fields.Item("Datacenter") = $line.'Datacenter'
#	$rs.Fields.Item("Cluster") = $line.'Cluster'
#	$rs.Fields.Item("Host") = $line.'Host'
	$rs.Fields.Item("OS") = $line.'OS'
	$rs.Fields.Item("VMUUID") =  $line.'VM UUID'
	$rs.Update()	
	
	$outMessage = $line.VM + "	" + $datastore[1] + "	" + $datastore[2]
	echo $outMessage
}		

$rs.close()
$cn.close()