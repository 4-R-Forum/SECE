# InnovConfig Setup Guide

## Setup Checklist


1. Choose a name to be shared by your new project local instance url, database and new project repository. If the name is MyProject: treat this as case sensitive
    - Your Innovator url will be 'http://localhost/MyProject"
    - The database name will be MyProject
    - The repository name will be MyProject
1. Install a new Innovator instance using the .msi on your machine using the url from the previous step, for example 'http://localhost/MyProject" .
1. Backup the database just installed as MyProject for a clean restore.
1. Create a new repo with the name MyProject at GitHub.com.
1. On your machine, clone the repo in the same folder as InnovConfig, this will be the MyProject repo
1. On your machine in VS Code, open the, InnovConfigCE Repo and run the script Use-Steps.ps1, select option 0. This will prompt for a project name (MyProject) and copy files to the Project repo.
1. In the MyProject repo, do the following:
    1. Edit Master_Config.xml for your machine name by copying and editing the sample.
    1. Edit Param_Config.xml for your project.
    1. Get ImportExport utilities for the Community Edition from http://aras.com/support
    1. Copy ConsoleUpgrade folder to the repo MyProj/tools folder, so that you have the folder MyProject/tools/ConsoleUpgrade
    1. Copy IOM.dll from the Innovator install folder MyProject/Innovator/Server/bin to the repo MyProj/tools folder, so that you have the file MyProj/tools/IOM.dll. Note that this is a different IOM.dll from the one in ConsoleUpgrade
    1. Add Packages and or src/Pre or PostProcessing to support Param_config
1. Add and commit content to local repo
1. Run the script Use-Steps.ps1 for Step 1.

## InnovConfig design and structure

InnovConfig uses the following structure.

Setup steps copy this structure to a new project folder with a new GitHub remote. The project repo uses the InnovConfig Module by importing it from a fixed location on the local machine. Its scripts are exectuted using Master_Config and Param_Config in the project repo. This allows multiple project repos to share a common code-base for InnovConfig while it is being built and tested.

When InnovConfig is stable it will be shared from a source such as  PowershellGallery, and used with Install-Module rather thatn Import-Module.

```text
+---AML-Packages           
    - Packages and manifest files
+---AutoTest
    - Pester (Powershell Tester) scripts
+---Documents
    - Documents in markdown format
+---Innovator
    - Innovator Tree
+---InnovConfig
    - Module. See Documents\InnovConfigGuide.md
+---src
    Text files, mostly AML
    +---PostProcessing
        -  applied after Import
    +---PreProcessing
        - applied after Import
    +---Test-AML
        - used by AutoTest
+---Temp
    -emporary files, excluded in .gitignore
    +---Export
        - Destination for Consolue Upgrade, for merging to AML-Pacakges
    \---Logs
        - From ConsoleUprade and other tools
+---tools
    dlls for specific Innovator release
    +---ConsoleUpgrade
    \---IOM.dll
```

## Table of revisions

1. JMH 2/25/2025 - First Community Edition 

## Known issues
