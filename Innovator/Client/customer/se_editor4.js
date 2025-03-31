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

    function addInputAction(se_io_id, process_id) {
        debugger;
        const a = top.aras;
        let this_process = a.newIOMItem("SE Process");
        this_process.setID([process_id]);
        let new_input = a.newIOMItem("SE Input","add");
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
    // this code will be executed every time the SVG is clicked
    // and in turn call the menuAction function
    // which has its own nested event listener
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
                let inputs = a.newIOMItem("SE Input");
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
                    subLi.addEventListener("click", () => addInputAction(se_io_id, this_id));
                    subMenu.appendChild(subLi); // Append sub-menu to "Add Input"
                };      
                li.appendChild(subMenu); 
            } else {
                li.addEventListener("click", () => menuAction(option, this_type, this_id));
            }      
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
        const innovator = a.IomInnovator
        const svg_id = this_id;
        /*
            We have been unable to find a way to reproduce the behavior of client onSearhDialog events, they may use DoJo.
            As an alternative a sub-menu is used in the context menu, following suggestion from ChatGPT.
            In our case we know from this_type what was clicked. If it is SE Process,
            and the option is Add Input or Output, we can get the SE IO items for the template
            to populate the sub menu in the addInput nested function.
            Each menu item has its own event listener  setup by init_contextmenu, called by a timeout
            when the page loads. 
        */
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
