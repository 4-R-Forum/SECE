function init_contextMenu() {
    console.log("se_editor.js loaded!");
    //debugger;

    const contextMenu = document.getElementById("contextMenu");
    if (!contextMenu) {
        console.error("Error: #contextMenu element not found.");
        return;
    }

    const menuItems = document.getElementById("menuItems");
    let currentTarget = null;

    // Attach ONE event listener to the entire SVG
    document.querySelector("svg").addEventListener("contextmenu", (event) => {
        console.log("SVG contextmenu event detected");
        event.preventDefault();
        event.stopPropagation();

        let targetG = event.target.closest("g[data-options]");

        // Handle right-click on graph0 (background area)
        if (!targetG) {
            const graph0 = document.querySelector("g#graph0");
            if (graph0 && graph0.contains(event.target)) {
                console.log("Right-clicked on graph0");
                targetG = graph0;  // Assign graph0 as the target
            } 
        }

        // If still no target, the click was on empty space in SVG
        if (!targetG) {
            console.log("Right-clicked on empty space inside SVG");
            targetG = document.querySelector("svg");
            if (!targetG) return;
            
            // Assign default options for empty space
            targetG.setAttribute("data-options", '["Open System", "Close Report"]');
        }

        console.log("Shape context menu executed");

        currentTarget = targetG;  // The correct <g> or <svg> element

        const menuOptions = currentTarget.getAttribute("data-options");
        const this_type = currentTarget.getAttribute("this_type");
        const this_id = currentTarget.getAttribute("this_id");

        if (!menuOptions) {
            console.warn("No 'data-options' attribute found.");
            return;
        }

        // Safe JSON parsing
        let options;
        try {
            options = JSON.parse(menuOptions);
        } catch (error) {
            console.error("Error parsing JSON:", error);
            return;
        }

        // Clear previous menu options
        menuItems.innerHTML = "";
        options.forEach(option => {
            const li = document.createElement("li");
            li.textContent = option;
            li.addEventListener("click", () => menuAction(option, this_type, this_id));
            menuItems.appendChild(li);
        });

        // Show menu at cursor position
        contextMenu.style.left = `${event.pageX}px`;
        contextMenu.style.top = `${event.pageY}px`;
        contextMenu.style.display = "block";
    });

    // Hide menu when clicking anywhere else
    document.addEventListener("click", () => {
        contextMenu.style.display = "none";
    });

    function menuAction(option, this_type, this_id) {
        const a = top.aras;
        const innov = a.IomInnovator;
        //const c = a.itemsCache;
        const svg_id = this_id;
        //debugger;
        switch (option) {
            case "Open":
                a.uiShowItem(this_type, this_id, 'tab view', false);
                break;
            case "New Process":
                var params = {
                    aras: a,
                    itemtypeName: 'SE Process',
                    type: 'SearchDialog'
                };
                var win = a.getMostTopWindowWithAras(window);
                var dialog = win.ArasModules.MaximazableDialog.show(
                    'iframe',
                    params
                );              
                var callback = function() {
                    //Perform logic using dialog result here
                    // dialog.returnValue is javacript object with properties item, itemId, keyed_name
                    // item is an xml Node which the client Aras object uses rather than IOM Item
                    const src_id = dialog.returnValue.itemID;
                    // get item selected in dialog from server
                    let src = a.newIOMItem("SE Process");
                    src.setID(src_id);
                    src.setAttribute('select','item_number,name,description,process_type');
                    src = src.apply("get");
                    src.fetchRelationships("SE Activity");
                    // get item clicked in svg from server to get name
                    let svg_item = a.newIOMItem("SE Process");
                    svg_item.setID(svg_id);
                    svg_item.setAttribute('select','owned_by_id,system_id(name)');
                    svg_item=svg_item.apply('get');
                    const sys_name = svg_item.getPropertyItem('system_id').getProperty('name');
                    // clone the source process, updagte properties, save and open the result
                    let new_item = src.clone(true);
                    new_item.setProperty('name',src.getProperty('name'));
                    new_item.setProperty('process_type',src.getProperty('process_type'));
                    new_item.setProperty('description',src.getProperty('description'));
                    new_item.setProperty('template_id', src.getID());
                    new_item.setProperty('item_number',sys_name + " " + src.getProperty("item_number"));
                    new_item.setProperty('system_id',svg_item.getProperty('system_id'));
                    new_item.setProperty('owned_by_id', svg_item.getProperty('owned_by_id'));
                    new_item = new_item.apply('add');
                    a.uiShowItemEx(new_item.node);                
                }
                dialog.promise.then(callback);
                break;
            case "Add Input":
               
                // Get the context Process
                const innovator = a.IomInnovator
                let cntxt_item = innovator.getItemById("SE Process",this_id);
                const templ_proc = innovator.getItemById("SE Process",cntxt_item.getProperty('template_id'));
                
                // Select an input from template
                // +++
                    const source_id = templ_proc.getID();
                    let qry1 = a.newIOMItem("SE Input");
                    qry1.setProperty("source_id",source_id);
                    let res = qry1.apply("get");
                    if (res.isEmpty()) {return "";}
                    if (res.isError()) {top.aras.AlertError(res.getErrorString());}
                    const count = res.getItemCount();
                    let idarray = new Array();
                    for (i=0;i<count;i++) {
                        const item=res.getItemByIndex(i);
                        idarray[i]=item.getProperty("se_io_id");
                    }
                    const idlist = idarray.join(",");
                    // create QryItem to add to pass in params
                    const iom_item_param = a.newIOMItem("SE IO","get");
                    iom_item_param.setAttribute("idlist",idlist);
                    iom_item_param.setAttribute("returnMode","itemsOnly");
                    item_param = iom_item_param.node;                   
                    debugger;
                    // add a new SE Input to context SE Process
                    let new_input = a.newIOMItem("SE Input");
                    new_input.setProperty("source_id",this_id);
                    new_input = new_input.apply("add");
                    a.uiShowItemEx(new_input.node); 
                    /*
                    new_input = cntxt_item.apply("edit");
                    if (cntxt_item.isError()) {top.aras.AlertError(res.getErrorString());}
                    //inArgs.QryItem.item.setAttribute("idlist",idlist);
                    let query_item = a.newQryItem("SE Input");
                    query_item.item = item_param;
                    let query_res = query_item.getResponse();
                    
                // ---

                
                var params = {
                    aras: a,
                    classList: "aras-dialgog_search",
                    itemContext: new_input, // type SE Input, with source_id of the svg Process
                    itemSelectedID: new_input.getID(), // the itemContext id
                    itemtypeName: 'SE Input', // the itemContext type
                    multiselect: false,
                    sourceItemtypeName: "SE Input", // the type where we will put the value
                    sourcePropertyName: "se_io_id", // where to put the returned value value
                    QryItem: query_item, // the query that will populate the SearchDialog
                    type: 'SearchDialog'
                };


                var win = a.getMostTopWindowWithAras(window);
                var dialog = win.ArasModules.MaximazableDialog.show(
                    'iframe',
                    params
                );
                dialog.QryItem = query_item;            
                var callback = function() {
                    //Perform logic using dialog result here
                    // dialog.returnValue is javacript object with properties item, itemId, keyed_name
                    // item is an xml Node which the client Aras object uses rather than IOM Item                   
                    // add SE Input to context process from svg
                    debugger;
                    const sel_io_id = dialog.returnValue.itemID;
                    let new_input = a.newIOMItem("SE Input");
                    new_input.setProperty("source_id",svg_id)
                    new_input.setProperty("se_io_id",sel_io_id);
                    new_input = new_input.apply("add");
                    // report result
                    if (new_input.isError()) { a.AlertError(new_input)}
                    else {a.AlertSuccess("Input added.")};           
                }
                dialog.promise.then(callback);
                */
                break;                      
            case "Add 0utput":
                a.newItem("SE Output");
                break;    
            case "New Input/Output":
                a.newItem("SE Controlled Item");
                break;                                   
            default:
            alert(`Selected: ${option} for ${currentTarget.id}`);
        }

        contextMenu.style.display = "none";
    }
}
