# AutoTest Guide

The purpose of this guide is to help Aras Practitioners use and create automated tests with Pester (Powershell Tester.)

There are sample scripts in InnovConfig\InnovConfig.tests.ps1 and InnovConfig\DoTests.ps1 for testing the InnovConfig Module in this repo.

Also tests for creating a PR and driving it through its workflow. This is a tiny set of 4 tests as a starting point for using Pester to provide automated tests for Innovator configurations created in this repo, and a template repo created from here.

## Using the PR example

1. The Method AML-Packages\SDtools\Import\Method\auto_vote.xml is used to complete workflow Activities using the AML Server built-in action EvaluateActivity. It passes arguments to this action and reports success or failure. At present it is necessary to apply the method using Nash.

1. Tests are in AutoTest\02-PR-WF.tests.ps1
    - BeforeAll sets up the tests
    - NewPR creates a PR with a known id
    - VoteVerify ... Verified and ... Approve complete three activities
    - InnovConfig module Send-AML function takes two parameters, login_name to apply and an AML string
    - Set-AutoTestOn function uses innovator as pasword without user input.

1. Tests are called by AutoTest\02-PR-WF.ps1
    - This script first refeshes the module
    - Reads Master-Config
    - and invokes the tests.

## Known issues

1. The assertion can be simplified and improved with $res.getResult | Should -Be 'OK' , to make it simpler and clearer
1. Ways of using AML strings can be improved, and will need to be for more elaborate testing. "Architecture happens."
1. /// TODO is inclulded in auto_vote and may be in other places.

## Table of Revisions

1. JMH, 05/02/2024. First draft