PDCA SE-Editor

# Purpose
- As a system enineer I want to view and edit the SEH Processes in a single graphical interface, which shows the inputs and outputs for all the processes for a system, so that all stakeholders can see the current state and trace decisions and progress for working on current activities

## PLAN
- Current Sytems Report uses Graphviz to draw a directed graph of processes and their inputs and outputs as svg.\
- Add context menu to the html page containing the svg to provide for a process
    - open the process, which can be edited after opening
    - add existing se_controlled inputs or output to the process
    - add a new se_controlled input or output
    - all ideally on client which can be saved to server by saving the System
    - alternatively directly on the server
- For input and output se_controlled items
    - Open the se_controlled item
- for the system (context menu in white space)
    - Create a new process from template
- Add context menu to existing report  see sample code folder
    - add data_items in svg
    - add style and scripts from Client/Customer
    - add context menu in div in report method

## DO
- se_editor js and css files show context menu
