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
- 2.7 Continue with report 3.1 for editing, use sidebar for panzoom

## DO
- 2.1 Create sidebar button and method
- 2.2 use evalMethod, passing in System AML
    - get AML from Action on System
- 2.3 Edge dev tools working, SearchDialog working in Private mode
- 2.4 iframe added in div id="viewers", and iframe.onload = function()
- 2.5 refactored show_report method  to support report and sidebar
- 2.6 checked_out branch PDCA-1.5, new method show_systemreport3 for report using se_editor3.1.js and se_editor.css
- 2.7 Continue with se_editor3.1.js and se_editor4.1.js
    - Import error with plm FormComposite ItemType in Form, must be new in CE2024


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
- 2.6 report context menu and submenu in correct x,y
    - sidebar using se_editor4.js same result as 2.4
    - I now have versions 3 and 4 of code running side by side, version 3 shows menu and submenu in the correct position but panzoom.js is not working, version 4 still has menu and submenu in the wrong position below the svg, but panzoom.js is working. I suspect panzoom may be causing the issue with version 4. here is panzoom.js. How can I get panzoom working and menus at correct position https://chatgpt.com/c/67ed89a6-99f0-8005-a471-7c7078d12ded
- 2.7 report: menu, panzoom on hover over node; sidebar menu at bottom, panzoom hover over page
    - Refresh working without panzoom, double search to add Input/Output why??
    - Rework data-options apply onserver

## ACT
    - start with refresh InnovConfig
    - fix report: menu, panzoom on hover over node; sidebar menu at bottom, panzoom hover over page
    - Refresh working without panzoom, double search to add Input/Output why??
    - Rework data-options apply onserver