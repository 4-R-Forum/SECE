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

    // Attach one event listener to SVG to detect clicks dynamically
    document.querySelector("svg").addEventListener("contextmenu", (event) => {
        console.log("SVG contextmenu event detected");
        //debugger;
        // Find the closest <g> with data-options (inner node)
        const targetG = event.target.closest("g[data-options]");
        if (!targetG) {
            console.log("No g[data-options] found");
            return;
        }

        console.log("Shape context menu executed");
        event.preventDefault();
        event.stopPropagation();

        currentTarget = targetG;  // The correct <g> element with data-options

        const menuOptions = currentTarget.getAttribute("data-options");
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
            li.addEventListener("click", () => menuAction(option));
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

    function menuAction(option) {
        alert(`Selected: ${option} for ${currentTarget.id}`);
        contextMenu.style.display = "none";
    }
}
