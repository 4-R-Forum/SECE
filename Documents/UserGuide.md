# InnovConfig Module User Guide

The purpose of this module is to help Aras Practitioners collaborate and configure Innovator in a git repository, so that configurations can be deployed to any instance from source control.

It includes the use of Pester (Powershell Tester) for automated testing of the module itself, and establishes a pattern of using Pester for testing of configurations.

The modules cmdlets are intended to streamline the process for using AML and Import/Export utilites as follows. Script steps are numbered with user tasks in between.

See Documents\SetupGuide.md

## Summary

1. Step One - create new local database from repo commit
    - User Task - make changes in local instane

1. Step Two - list configuration changes in Excel
    - User Task - select changes for export in Excel

1. Step Three - export selected changes
    - User Task - merge changes to AML-Packages using diff tool
    - Test changes
    - Repeat Step One and test again
    - Commit and push changes

## Using InnovConfig module

The script Use-Steps.ps1 provides a means for executing automated steps with Use Tasks in between.

### Step One

1. Use this step to create a fresh database with the latest changes
1. Checkout the desired git branch in the local repo.
1. Fetch and pull from remote to get others changes
1. Run Use-Steps.ps1
    - Enter 1 to select step
    - Warning prompt to overwrite local database
    - Prompt requests root password to import from AML-Packages, enter password or click return to use the usual default, innovator.
    - SQL uses local user account to restore db
    - Packages are imported using ConsoleUpgrade
    - User needs to resolve any reported errors

### Step Two

1. Use this step to show changes made since since Step One, in Excel. A date-time is recorded in the file Temp/compare_date.txt, which can be edited if desired.
1. Run Use-Steps
    - Enter 2 to select step
    - Excel opens to show changes found. ConfigReport.xlsx is saved in the root of the repo and ignored in .gitignore
    - If there are no changes Excel will be empty
    - User needs to indicate Add in the Action column for any Item not-in-package, put name in the Package column. Rows marked Add will be exported in Step Three
    - Also put Export in the Action column for any Item to be exported.
    - Rows with no Action will be ignored
    - Excel must be saved and closed before starting Step Three

### Step Three

1. Use this step when changes have been tested, to export changed package elements selected in ConfigReport.xlsx
1. Run Use-Steps
    - Enter 3 to select step
    - Prompt requests root password to export from AML-Packages, enter password or click return to use the usual default, innovator.
    - Prompt asks user to confirm delete of Temp/Export folder. Be careful, if the folder is wrong it may be necessary to clone the repo from origin to recover.
    - Packages are exported to Temp/Export, no manifest file is created
    - Export is intended for user merge to AML-Packages
1. Test the merged AML-Packages by running Step One, and running test again. Repeat the steps to resolve any test errors.
1. Commit and push changes to the desired branch

### Running Scripts in VS Code

It is important to avoid typing Terminal responses in the code panel.
The module now uses [System.Windows.Forms.SendKeys]::SendWait('^`')
to force focus to Terminal. This funky code needs to be called twice to produce the desired result.

## Automated testing of module

1. InnovConfig folder includes scripts DoTests.ps1 and InnovConfig.tests.ps1
1. Running the DoTests script uses Pester (Powershell Tester) to test Steps One, Two and Three
1. AML to be applied to Innovator is in src/Tests
1. It is intended to use a similar approach for some automated testing of Innovator configurations.

## Table of revisions

1. JMH 05/08/2024 - First draft of guide

## Known issues

1. Comments including /// TODO indicate planned improvements in scripts
1. Excel report needs formatting column widths, filter and freeze top row
1. Configuration Report in Excel has new code. Please report any Items that should be in the report but are not, and any other issues.
1. Restore-DB requires Master_Config .bak file to have .mdf and .ldf filenames matching db name. This can be overcome using -RelocateFile paramete. The logical file must be known and the case where mdf and ldf files are on different drives accommodated. The work has not been done yet.
1. CopyInnovatorTree is in the InnovConfig folder but not implemented in the Module.