PDCA-SE-Editor-2

# Purpose
- Show SE Editor from html page in Client/customer
    - consider sidebar for System ItemType
- add all menu items
- refresh button

## PLAN
- Use NotebookLM to investigate documentation including CUI
- Open editor from sidebar button
- 2.4 consider options other than report
    - use report method to write html directly to window -> svg displayed but context menu not working
    - use window.open to open html -> opens in a new window
    - find iframce and open there - how to?
    - open form with html in iframe, and open there
    - use dashboard and form
- 2.5 revert to report

## DO
- 2.1 Create sidebar button and method
- 2.2 use evalMethod, passing in System AML
    - get AML from Action on System
- 2.3 Edge dev tools working, SearchDialog working in Private mode
- 2.4 iframe added in div id="viewers", and iframe.onload = function()
- 2.5 refactored show_report method  to support report and sidebar


## CHECK
- 2.1 button populates and runs method, but no debugger!
- 2.2 debugger is working in Edge, but not Chrome??
    - in Method thisItem is context item, aml in SampleCode\SE-Editor-CommandButton-AML.xml
- 2.3 svg displaying when sidebar button clicked, css and js files not loading
- 2.4 graph displays with context menu, default suppressed, and panzoom after manual setting visbility. issues:
    - toggle visibility
    - context menu wrong x,y, pushes iframe down
    - SE Output sub-menu wrong IOs
- 2.5 now get same behavior in report as in sidebar, cannot reproduce behavior in 1.5