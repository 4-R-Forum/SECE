$module_location = Resolve-Path './InnovConfig/InnovConfig.psm1'
if ( Get-Module InnovConfig) { Remove-Module -Name InnovConfig }  # always use latest
Import-Module $module_location  # load module from Repo
Set-AutoTestOn # suppresses user input for automated tests
Read-MasterConfig  # sets module scope variables

Invoke-Pester -Output Detailed C:\Repos\InnovConfig\AutoTest\02-NewProject.tests.ps1