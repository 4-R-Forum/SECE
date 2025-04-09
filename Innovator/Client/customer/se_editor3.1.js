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

    function addInputOutputAction(se_io_id, process_id,add_type) {
        //debugger;
        const a = top.aras;
        let this_process = a.newIOMItem("SE Process");
        this_process.setID([process_id]);
        let new_input = a.newIOMItem(add_type,"add");
        new_input.setProperty("se_io_id", se_io_id);
        this_process.addRelationship(new_input);
        this_process = this_process.apply("edit");
        if (this_process.isError()) { 
            a.AlertError(this_process); 
        } else { 
            a.AlertSuccess("Input added."); 
        }
    }

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
            if ((option === "Add Input") || (option === "Add Output")  ) {
                //debugger;
                const a = top.aras;
                const innovator = a.IomInnovator;
                let cntxt_item = innovator.getItemById("SE Process",this_id);
                const templ_proc = innovator.getItemById("SE Process",cntxt_item.getProperty('template_id'));        
                // Select an input from template
                const source_id = templ_proc.getID();
                const add_type = option === "Add Input" ? "SE Input" : "SE Output";
                let inputs = a.newIOMItem(add_type);
                inputs.setProperty("source_id",source_id);
                inputs.setAttribute("select","se_io_id")
                let inputs_res =inputs.apply("get");
                //if (inputs_res.isEmpty()) {return "";}
                //if (inputs_res.isError()) {top.aras.AlertError(inputs_res.getErrorString());
                const subMenu = document.createElement("ul");
                subMenu.classList.add("sub-menu"); // Add a CSS class for styling        
                // Populate sub-menu with inputs_res items
                let i;
                for (i=0; i<inputs_res.getItemCount();i++){
                    const this_io = inputs_res.getItemByIndex(i);
                    const subLi = document.createElement("li");
                    const se_io_kn = this_io.getPropertyAttribute("se_io_id","keyed_name");
                    const se_io_id = this_io.getProperty("se_io_id");
                    subLi.textContent =  se_io_kn// keyed_name is a property of items in inputs_res
                    subLi.addEventListener("click", () => addInputOutputAction(se_io_id, this_id,add_type));
                    subMenu.appendChild(subLi); // Append sub-menu to "Add Input"
                };      
                li.appendChild(subMenu); 
            } else {
                li.addEventListener("click", () => menuAction(option, this_type, this_id));
            }      
            menuItems.appendChild(li);

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
                   // a.uiShowItemEx(new_item.node);
                   if (new_item.isError()) {
                        a.AlertError(new_item; 
                    } else { 
                        a.AlertSuccess("Process for System created."); 
                    }                
                }
                dialog.promise.then(callback);
                break;  
            case "Set SE Controlled Item":
                const add_type = "SE Controlled Item";
                var params = {
                    aras: a,
                    itemtypeName: add_type,
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
                    const seci_id = dialog.returnValue.itemID; // all we need is the ID, its a SECI
                    // get item clicked in svg from server so that we can add a Property
                    // this_type and this_id are in scope
                    // it must exist because it was in the diagram
                    let svg_item = a.newIOMItem("this_type");
                    svg_item.setID(this_id);
                    svg_item.setAttribute('select','id'); // all we need is the id of the input or output
                    svg_item = svg_item.apply('get');
                    // edit the svg_item to add the selected seio_id
                    svg_item.setProperty('seio_id',seci_id);
                    svg_item = svg_item.apply('edit');
                   // a.uiShowItemEx(new_item.node);
                   if (svg_item.isError()) {
                        a.AlertError(svg_item); 
                    } else { 
                        a.AlertSuccess("SE Controlled Item Set."); 
                    }                
                }
                dialog.promise.then(callback);
                break;                                   
            default:
                // alert(`Selected: ${option} for ${currentTarget.id}`);
        }

        contextMenu.style.display = "none";
    }
}
