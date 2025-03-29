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
- Add context menu to existing report  see sample code folder 1.1
    - add data_items in svg
    - add style and scripts from Client/Customer
    - add context menu in div in report method
- Alternative menus 1.2
    - Different menus for nodes Process and SECI
        - add type to title in server method, more code to get edges right
        - add attribute in client method, call to server for each node (selected)
    - get type and id
    - invoke IOM
- Add menu items 1.3
    - use top.aras, IOM and open window
- Menu Item New Process 1.4
    - use ModalDialog example
        - Open modal dialog
        - Select process and copy
        - template = 0, new name, add system/element, owner and save
        - refresh graph
        
    

## DO
- se_editor js and css files show context menu 1.1
- explore menu option context in debugger
    - top.aras is the aras object with IomInnovator and ItemsCache properties
- menu options set in client method 1.2
- menu option Open working 1.3
- menu options Add Process and Add Input working 1.4




## CHECK
- 1.1 test successful, context menu shows and executes code on select item
    - click out of node -> default context menu
    - error message on close "The method 'cui_svicm_reports_click' failed"
- 1.2 menu options working, type and id attr in svg,  error message on close resolved
- 1.4 menu working, Add Input does not reproduce osd behavior, use custom sub-menu