<#
    adapted from https://thedavecarroll.com/powershell/how-i-implement-module-variables/
    and https://mikefrobbins.com/2017/06/08/what-is-this-module-scope-in-powershell-that-you-speak-of/
#>

# initialize module scope variables
$Session = [ordered]@{
    iom_dll_loc     = $null # relative path iom.dll
    libs_dll_loc    = $null # relative path libs.dll
    conn            = $null # Aras Object, used for creating Innovator Object
    innov           = $null # Innovator Object, an authenticted connection to server
    cih             = $null # Console Item Helper Object, for exporting single PackageElement
    innov_base_url  = $null # url to Innovator, as used in browser
    innov_srv_url   = $null # fully qualified url, used by IOM  
    innov_db        = $null # name of database
    sql_service     = $null # name of Windows Service, used to restore database
    sql_instance    = $null # name of SQL instance, used to connect to SQL database
    sql_bak         = $null # location of baseline backup     
    sql_user        = $null # sql user, eg sa or innovator
    sql_pw          = $null # password for SQL login
    cr_templ_loc    = '\InnovConfig\InnovConfig\ConfigReport-Template.sql' # relative location of Config Report Template
    crr_templ_loc   = '\InnovConfig\InnovConfig\ConfigReport-Rel-Template.sql' # relative location of Config Report Template
    export_folder   = $null # folder for exported changes, for merge to AML-Packages by user
    auto_test       = $false

}
# Note: Session variables will be resolvee relative to the path of the Project repo,
# not the InnovConfigCE repo

$InnovConfigSession = $null
New-Variable -Name InnovConfigSession -Value $Session -Scope Script -Force
$InnovConfigSession['iom_dll_loc']  = Resolve-Path './tools/ConsoleUpgrade/IOM.dll'
$InnovConfigSession['libs_dll_loc'] = Resolve-Path './tools/ConsoleUpgrade/Libs.dll'
$InnovConfigSession['export_folder'] = Resolve-Path './Temp/Export/'
Add-Type -AssemblyName System.Windows.Forms

function  New-Project{ 
    param (
        [string] $project_name
    )
    Write-Host "$project_name repo will be updated."

    # Get Repos folder
    $repo_folder = Resolve-Path '../'
    $new_folder = "$repo_folder/$project_name"
    $res
        # Create new folder
    if (-not (Test-Path -Path $new_folder)) {
        # New-Item -ItemType Directory -Path $new_folder | Out-Null
        # $res =  $project_name
        $res = "$project_name repo not found"
        Write-Host "New-Project aborted"
    }
    else {
        $res =  $project_name
    }
    # Copy Files
    # set params for Copy-Item
    if ($res -eq  $project_name){
        $src_files = Resolve-Path './*'
        $src_folders = Resolve-Path './'
        $dest = $new_folder
        $excl = "InnovConfig"
        $exclr = @('*.xlsx','*.git')
        # copy root files
        Copy-Item -Force $src_files -Destination $dest -Exclude $exclr
        # copy folders excl InnovConfig
        Get-ChildItem $src_folders -Directory `
        | Where-Object { $_.Name -notin $excl } `
        | Copy-Item -Force -Recurse   -Destination $dest
        # delete InnovConfig in dest
        Remove-Item  -Path ($dest + "/InnovConfig")
    }
   return $res
}

function Set-AutoTestOn{
    $InnovConfigSession['auto_test'] = $true
}
function Set-AutoTestOff{
    $InnovConfigSession['auto_test'] = $false
}

function New-Guid {
    return ([guid]::NewGuid()).ToString().replace("-","").ToUpper()
}
function ConvertFrom-SecureToPlain {   
    param( [Parameter(Mandatory=$true)][System.Security.SecureString] $SecurePassword)   
    # Create a "password pointer".
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)    
    # Get the plain text version of the password.
    $PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)    
    # Free the pointer.
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)    
    # Return the plain text password.
    $PlainTextPassword    
}

function Read-MasterConfig {
    param (
        [string] $master_config_loc
    )
    # Read configuration xml
    $machine =  $env:computername
    [xml] $master_config = get-content  $master_config_loc
    $base_url = $master_config.selectSingleNode("config/machine[@name='$machine']/innovator_url").'#text'
    $InnovConfigSession['innov_db']  =  $master_config.selectSingleNode("config/machine[@name='$machine']/database_name").'#text'
    $InnovConfigSession['innov_base_url'] = $base_url
    $InnovConfigSession['innov_srv_url'] = $base_url + 'Server/InnovatorServer.aspx'
    $InnovConfigSession['sql_service'] = $master_config.selectSingleNode("config/machine[@name='$machine']/sql_service").'#text'
    $InnovConfigSession['sql_instance'] = $master_config.selectSingleNode("config/machine[@name='$machine']/sql_instance").'#text'
    $InnovConfigSession['sql_bak'] = $master_config.selectSingleNode("config/machine[@name='$machine']/sql_bak").'#text'
}

function Restore-Database {
    $sql_service = $InnovConfigSession['sql_service']
    $instance = $InnovConfigSession['sql_instance']
    $db = $InnovConfigSession['innov_db'] 

    Restart-Service -Force 'W3SVC' 
    Restart-Service -Force  $sql_service

    Restore-SqlDatabase `
        -ServerInstance $InnovConfigSession['sql_instance'] `
        -Database $InnovConfigSession['innov_db'] `
        -BackupFile $InnovConfigSession['sql_bak'] `
        -ReplaceDatabase
    Write-Host "Restore Completed"
    Write-Host -ForegroundColor Yellow "Ignore 'Restoring % Completed' msg. Not suppressed yet."
 
    Invoke-Sqlcmd -ServerInstance $instance  -Database $db -TrustServerCertificate -Query "sp_change_users_login 'auto_fix','innovator'"
    Invoke-Sqlcmd -ServerInstance $instance  -Database $db -TrustServerCertificate -Query "sp_change_users_login 'auto_fix','innovator_regular'"
    Invoke-Sqlcmd -ServerInstance $instance  -Database $db -TrustServerCertificate -Query "sp_changedbowner 'sa'"
    Write-Host "Database Ready"  
    return 0
}

function Connect-Innov {
    # Creates an authenticated connection to an Innovator Instance
    param (
        [string] $login_name
    )
    # prompt to get password, with default, and confirm login
    $pw_plain = "innovator" # default value if none provided
    if (-not $InnovConfigSession['auto_test']) { # suppress user interaaction in test
        [System.Windows.Forms.SendKeys]::SendWait('^`') # Ctrl backtick twice, forces focus to terminal
        [System.Windows.Forms.SendKeys]::SendWait('^`') # Doing it twice shows terminal
        $pw_secure = Read-Host -AsSecureString -Prompt "Enter $login_name password, usual default"
        if ($pw_secure.Length -ne 0){$pw_plain=(ConvertFrom-SecureToPlain $pw_secure)}
    }
    # Add-Type -Path $InnovConfigSession['iom_dll_loc']
    Add-Type -Path $InnovConfigSession['iom_dll_loc']
    Add-Type -Path $InnovConfigSession['libs_dll_loc']
    $conn =[Aras.IOM.IomFactory]::CreateHttpServerConnection( `
       $InnovConfigSession['innov_srv_url'], `
       $InnovConfigSession['innov_db'], `
       $login_name, `
       $pw_plain)  
    Test-InnovLogin $conn
    # populate connection objects as session variables
    $InnovConfigSession['conn'] = $conn
    $InnovConfigSession['innov'] = [Aras.IOM.IomFactory]::CreateInnovator($conn)
    $InnovConfigSession['cih'] = New-Object Aras.Tools.SolutionUpgrade.CItemHelper($InnovConfigSession['conn']); # ConsoleItemHelper
    return $InnovConfigSession['innov'].ToString() # for auto_test
}

function Test-InnovLogin {
    param( [Parameter(Mandatory=$true)][Aras.IOM.HttpServerConnection] $conn)
    $res = $conn.Login()
    if ($res.isError()) 
    {
    "Login failed, please check password: " + $res.dom.DocumentElement.OuterXml
    "Script cannot continue and will exit."
    exit 
    }
}

function Export-ConfigReport{
    $compare_date = Get-Content -Path ./Temp/compare_date.txt
    $sql_instance = $InnovConfigSession['sql_instance']
    $innov_db = $InnovConfigSession['innov_db']
    $repos_folder = Resolve-Path '../'
    $cr_templ_loc =  $repos_folder.Path + $InnovConfigSession['cr_templ_loc']
    $crr_templ_loc = $repos_folder.Path + $InnovConfigSession['crr_templ_loc']
    $config_report = @()

    [string] $sql_qry1 = "select instance_data
    from innovator.itemtype where name in
    ('Action', 'Chart', 'Dashboard', 'EMail Message',
    'FileType', 'Form', 'Grid', 'Identity', 'ItemType',
    'Life Cycle Map', 'List', 'Method', 'Permission',
    'RelationshipType', 'Report', 'Revision', 'Sequence',
    'Variable', 'Vault', 'Viewer', 'Workflow Map', 'SQL', 'PM_ProjectGridLayout','UserMessage',
    'rb_TreeGridViewDefinition','qry_QueryDefinition',
    'PresentationConfiguration','CommandBarMenu','CommandBarSection','CommandBarMenuButton','CommandBarButton'
    )"
    $res1 = Invoke-Sqlcmd -ServerInstance $sql_instance -Username 'sa' -Password 'innovator' -Database $innov_db -Query $sql_qry1
    # $res1 is a list of table names for ItemTypes which need to be in PackageDefinitions

    [string] $sql_qry2_template = get-content $cr_templ_loc
    $sql_qry2_template = $sql_qry2_template.Replace('@Date',$compare_date)
    $permission_excl ="and t.is_private <> '1'"
    $identity_excl ="and t.is_alias <> '1'"
    $list_excl = "and t.name not in (select name from innovator.ItemType where implementation_type = 'polymorphic')"
    foreach ($it in $res1) {
        $sql_qry2 = $sql_qry2_template.Replace('@TableName',$it.instance_data)
        if ($it.instance_data -eq 'Permission') {$sql_qry2 = $sql_qry2.Replace('@Exclusions',$permission_excl)}
        elseif ($it.instance_data -eq 'Identity') {$sql_qry2 = $sql_qry2.Replace('@Exclusions',$identity_excl)}
        elseif ($it.instance_data -eq 'List') {$sql_qry2 = $sql_qry2.Replace('@Exclusions',$list_excl)}
        else {$sql_qry2 = $sql_qry2.Replace('@Exclusions','')}
        $res2 = Invoke-Sqlcmd -ServerInstance $sql_instance -Username 'sa' -Password 'innovator' -Database $innov_db -Query $sql_qry2
        # $res2 is a list of instances for a package ItemType modified since the specified date
        # with exclusions for specified types
        $config_report += $res2 
        # package items for one type are appended to the $config_report array
    }
    [string] $sql_crr_template = get-content $crr_templ_loc
    $sql_crr = $sql_crr_template.Replace('@Date',$compare_date)
    $res3 = Invoke-Sqlcmd -ServerInstance $sql_instance -Username 'sa' -Password 'innovator' -Database $innov_db -Query $sql_crr
    $config_report += $res3

    $xlFile = 'ConfigReport.xlsx'
    Remove-Item $xlFile -ErrorAction SilentlyContinue # delete existing file
    # /// TODO automate filter and more
    <#
        Next line uses Import-Excel module to popluate and Excel Workbook
        in memory, with contents of $config_report result set from SQL,
        using the open source OpenXml standard published by Microsoft.
    #>
    $config_report | Export-Excel  $xlFile
    $xlb = Open-ExcelPackage $xlFile
    # delete cols added by conversion from sql result
    $xls = $xlb.Workbook.Worksheets["Sheet1"]
    for ($i = 1; $i -lt 7; $i++){ # zero based, delete from right
        $xls.DeleteColumn(8)  
    }
    # Add a column for user to add Actions 
    $xls.Cells["H1"].Value = "Actions"
    $xlb.Save()
    Close-ExcelPackage $xlb -Show
    # Hints for user
    Write-Host "Please add Actions to Excel and Save and Close it"
    Write-Host "Then run Export-Changes script"
    return 0
}

function Export-Changes {
    #$libs_folder = resolve-path "..\tools\ConsoleUpgrade\" 
    $export_folder  = $InnovConfigSession['export_folder']
    $xlFile = 'ConfigReport.xlsx'
    $innov = $InnovConfigSession['innov']
    $cih = $InnovConfigSession['cih']

    function Add-ToPackage {
        # this function has parmeters, similar to arguments for a module
        param (
            [string]$el_name,
            [string]$el_id,
            [string]$el_type,
            [string]$pg,
            [string]$pd,
            [string]$atp_template
        )
        $aml = $atp_template.Replace("@el_name", $el_name)
        $aml = $aml.Replace("@el_id", $el_id)
        $aml = $aml.Replace("@el_type", $el_type)
        $aml = $aml.Replace("@pg", $pg)
        $aml = $aml.Replace("@pd", $pd)
   
        return $aml
    }
    function Export-Item {
         param (
            [string] $this_pd,     # PackageDefiniton name
            [string] $this_type,   # PackageGroup name = ItemType name, not label 
            [string] $this_pe_id,  # PackageElement id, identifies Item to be exported
            [string] $this_pe_name # PackageElement name, friendly name used in package only
        )
        # create folder for Package/Import/Group as needed
        $package_folder = $export_folder.Path + $this_pd.Replace("com.aras.innovator.solution.","")
        $package_folder +=  "\Import\" 
        if (!(Test-Path $package_folder)) { 
            New-Item -ItemType Directory -Force -Path $package_folder | Out-Null
        }
        $cih.Folder = $package_folder
        $h = @{} # cih requires, for exclude hashtable, not used
        $action = [Aras.Tools.SolutionUpgrade.ImportExport]::Export # cih requires
        $dict = [System.Collections.Generic.Dictionary[string, int]]::new() # cih requires, not used for export
        $ei = New-Object Aras.Tools.SolutionUpgrade.ExportItem($this_pe_name,$this_pe_id,$this_type); # what to export
        $cei.Export($ei,$this_pd,"1",$h,$action,$null,$dict) # execute the export
    }
    

    # powershell 'here string' (string literal) must start with @" and #@ at start of linw
    $atp_template=
@"
    <AML>
        <Item type='PackageElement' action='add'>
            <name>@el_name</name>
            <element_id>@el_id</element_id>
            <element_type>@el_type</element_type>
            <source_id>
                <Item type='PackageGroup' action='create'>
                    <name>@pg</name>
                    <source_id>
                        <Item type='PackageDefinition' action='create'>
                            <name>@pd</name>
                        </Item>
                    </source_id>
                </Item>
            </source_id>
        </Item>
    </AML>
"@

    # Delete contents of Export folder
    Write-Host -ForegroundColor Cyan "Press Y and Enter to confirm delete of folder $export_folder"
    $confirm = Read-Host
    if ($confirm.ToUpper() -eq 'Y'){
        Get-ChildItem $export_folder -Force -Directory -Recurse | Remove-Item -Force -Recurse
    }
    else {
        Write-Host -ForegroundColor Cyan "Delete not confirmed. Exiting script"
        Exit
    }
    

    Write-Host "Connecting for Export ...." 
    $cih.Login();
    $cei = New-Object Aras.Tools.SolutionUpgrade.CExportItems($cih) # ConsoleExportItem
    Write-Host -ForegroundColor Green "Export connection created"
    # Open Config Excel file
    $xlb = Open-ExcelPackage $xlFile
    $xls = $xlb.Workbook.Worksheets["Sheet1"]
    # get Excel rows and iterate, skip header row and export changes
    $dimension = $xls.Dimension # Data range in Excel Sheet
    for ($i = 2; $i -le $dimension.Rows; $i++) #  Rows 1 is header
    {
        # get values for this row
        $this_pd        = $xls.Cells["A"+$i].Value
        $this_type      = $xls.Cells["B"+$i].Value
        $this_pg        = $xls.Cells["C"+$i].Value
        $this_pe_name   = $xls.Cells["D"+$i].Value
        $this_pe_id     = $xls.Cells["E"+$i].Value
        $this_action    = $xls.Cells["H"+$i].Value
        if ($this_action -eq "Add"){   
            if ($this_pd -eq "x_NOT_in_package") {
                Write-Host "Error: No Package name for Add in row "  $i
                Exit
            }   
            $atp_aml = Add-ToPackage $this_name $this_pe_id  $this_type $this_pg $this_pd $atp_template
            $res = $innov.applyAML($atp_aml)
            if ($res.isError()){
                Write-Host -ForegroundColor Red  "Add to package failed for " $this_pg $this_name ". Item not exported"
                break
            }
            else {
                Write-Host -ForegroundColor Green  "Add to package succeeded for " $this_pg $this_pe_name
                Export-Item $this_pd $this_type $this_pe_id $this_pe_name  # void function, cannot test result
            }
        }
        elseif ($this_action -eq "Export"){
            Export-Item $this_pd $this_type $this_pe_id $this_pe_name # void function, cannot test result
        }
    }
    Write-Host -ForegroundColor Green "Export completed" 
}

function Import-Packages {
    $starttime= get-date # for reporting elapased time
    # use session variables
    $conn = $InnovConfigSession['conn']
    $innov = $InnovConfigSession['innov']
    $innov_db = $InnovConfigSession['innov_db']
    $innov_base_url = $InnovConfigSession['innov_base_url']
    $innov_srv_url = $InnovConfigSession['innov_srv_url']
    # fixed file structure locations, no longer set in Param_Config
    $log_loc = Resolve-Path   ".\Temp\Logs\"
    $cu = Resolve-Path '.\tools\ConsoleUpgrade\ConsoleUpgrade.exe' # location of ConsoleUpgrade.exe
    $dir = Resolve-Path '.\AML-Packages\' # location of Packages
    # root credentials /// TODO parameterize
    $cu_login = "root"
    $cu_pw = "innovator"

    # load parameters from config xml file
    $param_config = Resolve-Path ".\Param_Config.xml"
    [xml] $config = get-content $param_config
    $params     = $config.selectNodes("//param")
    $aml_files0 = $config.selectNodes("//files0")
    $aml_files1 = $config.selectNodes("//files1")
    $aml_files2 = $config.selectNodes("//files2")
    $mf_files1  = $config.selectNodes("//mf1")
    foreach ($param in $params) # create array of arguments for ConsoleUpgrade.exe
    {
    set-variable -name $param.varname -visibility public  -value $param.'#text'
    }
    $files0 = @() # create array of Pre-Processing file locations
        foreach ($aml_file in $aml_files0)
    {
        $files0+= $aml_file.'#text'
    } 
    $files1 = @() # create array of Post-Processing file locations
    foreach ($aml_file in $aml_files1)
    {
        $files1+= $aml_file.'#text'
    } 
    $files2 = @() # create array of BatchLoader file locations, not used in this repo yet
    foreach ($aml_file in $aml_files2)
    {
        $files2+= $aml_file.'#text'
    }
    $mf1 = @() # create array of manifet files to be imported by ConsoleUpgrade, in this repo just imports.mf
    foreach ($mf_file in $mf_files1)
    {
        $mf1+= $mf_file.'#text'
    }
 

    # set log file names
    $log_cu  = $starttime.toString("yy-MM-dd-hh-mm-ss")+"-CU.log"
    $log_iom = $starttime.toString("yy-MM-dd-hh-mm-ss")+"-IOM.log"

    # run the imports
    # arguments for ConsoleUpgrade
    $srv_arg = 'server='+'"'+$innov_base_url+'"' # Console Upgrade argument
    $db_arg  = 'database="'+$innov_db+'"' # Console Upgrade argument
    $login_arg = 'login="'+$cu_login+'"'
    $pw_arg = 'password="'+$cu_pw+'"'
    $dir_arg =( 'dir="'+ $dir +'"') # Console Upgrade argument
    $log_arg = 'log="'+ $log_loc + $log_cu+'"' # Console Upgrade argument
    $rel_arg = 'release="' +$innov_db+'"' # Console Upgrade argument, CE requires, use MyProject name

    ## apply PreProcessing files
    $aml_path_0_fq = (resolve-path ./src/PreProcessing/).Path
    foreach ($file in $files0)
    {  
    $aml= [IO.File]::ReadAllText($aml_path_0_fq+$file)
    $res= $innov.applyAML($aml)
    if ($res.isError()) { $msg = ("Error applying "+$file + " : " + $res.dom.DocumentElement.OuterXml) }
    else { $msg = ($file + ": applied successfully.")}
    write-host $msg
    $log_path = $log_loc.Path + $log_iom
    Add-Content -Path $log_path -Value $msg
    }
    ## apply packages for one or more manifest files
    foreach ($mf_file in $mf1)
    {
    $mf_arg ='mfFile="'+$dir+$mf_file +'"'
    $descr_arg ='description="Imported from '+$dir+$mf_file +'"'
    $cu_cmd ="$cu $srv_arg $db_arg $login_arg $pw_arg import merge verbose $dir_arg $mf_arg $rel_arg $log_arg $descr_arg"
    invoke-expression $cu_cmd

    }
    # end of run imports

    # apply post AML files
    $aml_path_1_fq = (resolve-path ./src/PostProcessing/).Path
    foreach ($file in $files1)
    {  
    # log out and in as admin, to assume Identities updated in prior AML
    $conn.Logout()
    # /// TODO consider Send-AMLFiles function
    $conn = [Aras.IOM.IomFactory]::CreateHttpServerConnection($innov_srv_url,$innov_db,"admin","innovator")
    $innov= [Aras.IOM.IomFactory]::CreateInnovator($conn) 
    $aml= [IO.File]::ReadAllText($aml_path_1_fq+$file)
    $res= $innov.applyAML($aml)
    if ($res.isError()) { $msg = ("Error applying "+$file + " : " + $res.dom.DocumentElement.OuterXml) }
    else { $msg = ($file + ": applied successfully.")}
    write-host $msg
    $log_file = $log_loc.Path + $log_iom
    Add-Content -Path $log_file -Value $msg
    }
    # end of appy AML files
    Start-Sleep -Seconds 1 # set compare date after post process files
    $compare_date = Get-Date
    $compare_date = $compare_date.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
    $compare_date | Out-File ./Temp/compare_date.txt
    Write-Host "Config Report Compare Date set to $compare_date UTC"

    # apply batch load files
    # /// TODO add batch load files if needed
    # end of batch load files

    $runtime = $(get-date) - $starttime
    $msg = [string]::format("{0:#} minutes", $runtime.TotalMinutes)
    "`r`nSCRIPT COMPLETED in $msg"
}
function Send-AML {
    # Apply single AML string
    param (
        [string] $login_name,
        [string] $aml
    )
 
    Connect-Innov $login_name # set new  $InnovConfigSession['innov']
    $innov = $InnovConfigSession['innov']
    $res = $innov.applyAML($aml)
     $return_code = "OK"
    if ($res.isError()){
        $return_code = $res.getErrorString()
        Write-Host -ForegroundColor Red "$file apply failed"
    }
    else {
        Write-Host -ForegroundColor Green "$file successfuly applied"
    }
    return $return_code


}

function Send-AMLFiles {
    # Apply AML from config xml
    param (
        [string] $login_name,
        [array] $aml_files
    )
    Connect-Innov $login_name # set new  $InnovConfigSession['innov']
    $innov = $InnovConfigSession['innov']
    $return_code = 'OK'

    foreach ($file in $aml_files){
        $aml = Get-Content $file
        $res = $innov.applyAML($aml)
        if ($res.isError()){
            $return_code = $res.getErrorString()
            Write-Host -ForegroundColor Red "$file apply failed"
        }
        else {
            Write-Host -ForegroundColor Green "$file successfuly applied"
        }
    }
    return $return_code
}

function Invoke-InnovExport{
    # Export a complete package using ConsoleUpgrade
    # /// TODO enhancement
    param (
        [Object] $cih    
    )
  }

function Invoke-InnovImport {
    # Import Packages using .mf file using ConsoleUpgrade
        # /// TODO enhancement
    param (
        [hashtable] $innov_login,
        [string] $manifest,
        [string] $log
    )
}


