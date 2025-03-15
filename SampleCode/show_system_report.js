
var svg  = this.apply("SystemReportServer").getResult();
var html = `
<html>
	<head>
	<link rel="stylesheet" href="../Client/customer/se_editor.css">	
    <script src='../Client/customer/panzoom.js' type='text/javascript' ></script>
    <script src='../Client/customer/se_editor.js' type='text/javascript' ></script>
 	</head>
    <body>
	    <script type='text/javascript'>
	        setTimeout(init,1000);
	        function init(){
	          var area = document.getElementById('graph0');
		        panzoom(area, {autocenter: true, bounds: true});
		    }
	    </script>
	    <div>
            <div id="contextMenu" class="context-menu">
        <ul id="menuItems"></ul>
    </div>
`;
html += svg;
html += `
		</div>
	</body>
</html>
`;