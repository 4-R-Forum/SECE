# InnovConfig Project Guide

## Pre-requisites

1) Innovator pre-requisites
    - Windows Pro OS with Admin privileges
    - IIS installed and configured for Innovator
    - SQL Server installed with SysAdmin privileges

1) Git installed
    - .ssh setup for GitHub anautics-inc

1) Powershell latest LTS (Long Term Support, 7.5 at time of writing) is installed. This includes the Pester 5.2 module. (OOTB Windows includes Powershell 5.1 for .Net Framework compatability.)  

1) Powershell Modules installed.
    - ImportExcel
    - SqlServer

1) VS Code installed, with extensions
    - IntelliCode
    - markdownwlint

1) InnovConfig and Project repos in same folder
    - Project will use InnovConfig using Import-Module
    - Multiple Projects share same InnovConfig

## Setup steps

1. Read guides in InnovConfig repo
    - 

1. Follow steps in InnovConfig/Documents/SetupGuide.md

## Usage notes

- KISS
- main is the root branch
- See Documents\RepoFolderStructure.md for description of folder structure. There may be script errors if any are missing.
- Former Installers folder is removed and replaced by Module InnovConfig. See Documents\InnovConfigGuide.md
- MasterConfig.xml needs to be edited for repos on different machines
- *.-code-workspace is the VS Code workspace file, excluded in .gitignore

## Table of revisions

1) JMH 02/26/2025 First Community Edition
