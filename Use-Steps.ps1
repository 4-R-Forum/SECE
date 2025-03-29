$repos_folder = Resolve-Path '../'
$module_location = $repos_folder.Path + '/InnovConfigCE/InnovConfig/InnovConfig.psm1'
if ( Get-Module InnovConfigCE) { Remove-Module -Name InnovConfigCE }  # always use latest
Import-Module $module_location  # load module from Repo
#Import-Module "C:\Repos\SECE\InnovConfig.psm1" -Force -Verbose

Read-MasterConfig .\Master_Config.xml # sets module scope variables and reads config from project repo

Write-Host "Enter Step"
Write-Host "0 = New-Project"
Write-Host "1 = Restore baseline DB and Import Packages"
Write-Host "2 = Config-Report"
Write-Host "3 = Export-Changes"
$step = Read-Host
switch ($step) {
    0   {
        $repo_name = Read-Host "Enter empty repo name"
        New-Project $repo_name
    }
    1   {
            Write-Host -ForegroundColor Cyan "Database will be overwritten, enter Y to continue?"
            $resp = Read-Host
            if ($resp.ToUpper() -ne 'Y') { Exit }
            Connect-Innov 'root'
            # Restore-Database
            Import-Packages
    }
    2   {
            # uses sql sa login
            Export-ConfigReport
        }
    3   {
            Connect-Innov 'root'    
            Export-Changes
        }
     
}




