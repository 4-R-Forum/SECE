﻿Innovator innov = this.getInnovator();
// step 1, get ids of structure for system
string this_type = this.getType();
string system_id;
if (this_type == "sys_System") system_id = this.getID(); // called by show_se_process_report
else  system_id = this.getProperty("system_id"); // called by show_se_process_report2 Dashboard generic method

bool debug = false;
if (debug == true)
{
    //if (System.Diagnostics.Debugger.Launch()) System.Diagnostics.Debugger.Break();
    system_id = "C27D19AFCC2D470BB4F216C8B459D955"; // System 1
    //system_id = "9D4367F530114858A2BB9B9F9984EA42"; // System 2
}

string aml1 = @"<AML>
    <Item type='sys_System' action='GetItemRepeatConfig' id='{system_id}' >
        <Relationships>
            <Item type='sys_System Breakdown' action='get'  repeatProp='related_id' repeatTimes='0' />
        </Relationships>
    </Item>
</AML>";
Item res1 = innov.applyAML(aml1.Replace("{system_id}",system_id));
// return innov.newResult(aml1.Replace("{system_id}",system_id));
//return res1;
string id_list = "'" + system_id + "'";
Item element_ids = res1.getItemsByXPath("//Item[@type='sys_System Breakdown']");
for (int i = 0; i < element_ids.getItemCount(); i++)
{
	Item this_item = element_ids.getItemByIndex(i);
	id_list += ",'" + this_item.getProperty("related_id" ) + "'";
}
// if (debug) return innov.newResult(id_list);
// step 2 get processes for system
string aml2 = @"<AML>
    <Item type='SE Process' action='get' select='item_number,name'>
        <system_id condition='in'>{id_list}</system_id>
        <Relationships>
            <Item type='SE Input'  action ='get' select='is_applicable, se_input_id,  se_controlled_item_id(keyed_name,name)'  />
            <Item type='SE Output' action ='get' select='is_applicable, se_output_id, se_controlled_item_id(keyed_name,name)'  />
         
        </Relationships>
    </Item>
</AML>";
aml2 = aml2.Replace(@"{id_list}",id_list);
//return innov.newResult(aml2);
Item res2 = innov.applyAML(aml2);


// step 3 define nodes and edges for thread diagram, as dot language
StringBuilder dot = new StringBuilder("");
// 3.1 create nodes for processes
Item process_nodes = res2.getItemsByXPath("//Item[@type='SE Process']");
// return process_nodes;
for (int i = 0; i < process_nodes.getItemCount(); i++)
{
    Item this_process = process_nodes.getItemByIndex(i);
    string nickname = "x" + this_process.getID();
    string keyed_name = this_process.getProperty("item_number") + "\r\n" + this_process.getProperty("name");
    string this_node = $"{nickname}  [shape=box,label=\"{keyed_name}\"];\r\n";
    dot.Append(this_node);
}
// 3.2 create nodes and edges for IO
Item io_nodes = res2.getItemsByXPath("//Item[@type='SE Input']|//Item[@type='SE Output']");
for (int i = 0; i < io_nodes.getItemCount(); i++)
{
    Item this_io = io_nodes.getItemByIndex(i);
    string keyed_name = this_io.getPropertyAttribute("id","keyed_name");
    keyed_name = keyed_name.Replace(" ","\r\n");
    string se_controlled_item_id;
    Item se_controlled_item = this_io.getPropertyItem("se_controlled_item_id"); // null if no Item present
    if (se_controlled_item != null) se_controlled_item_id = se_controlled_item.getID();
    se_controlled_item_id = this_io.getProperty("se_controlled_item_id");
    string nickname = this_io.getPropertyAttribute("se_controlled_item_id","keyed_name","Empty");
    string name;
    Item this_controlled_item = this_io.getPropertyItem("se_controlled_item_id");
    if (null == this_controlled_item) name ="N/A";
    else name = this_controlled_item.getProperty("name","N/A");
    //string name =     this_io.getPropertyItem("se_controlled_item_id").getProperty("name","N/A");
    string source_id = this_io.getProperty("source_id");
    string relationship_id = this_io.getID();
    string node_id;
    if (String.IsNullOrEmpty(se_controlled_item_id))
    {
        node_id= relationship_id;
    }
    else
    {
        node_id = se_controlled_item_id;
    }
    //if (System.Diagnostics.Debugger.Launch()) System.Diagnostics.Debugger.Break();
    data-options="['Open', 'Add IO', 'New IO']"
    /// TODO replace hard code url in follow'ng with in{fo from server
    string this_node = $"x{node_id} , {data_options} , [shape=parallelogram,label=\"{keyed_name}\r\n{nickname}\r\n{name}\",URL=\"http://localhost/SECE/?StartItem=SE+Controlled+Item%3A{se_controlled_item_id}\"]\r\n";
    string node_from, node_to;
    node_from = node_to = "";
    if ("SE Output" ==this_io.getType())
    {
        node_from = source_id;
        node_to   = node_id;
    }
    else
    {
        node_from = node_id;
        node_to   = source_id;
    }
    string this_edge = $"x{node_from} -> x{node_to}\r\n";
    dot.Append(this_node);
    dot.Append(this_edge);
}
string dot_string = "digraph g{rankdir=LR;\r\n" + dot.ToString()  + "}";
dot_string = dot_string.Replace("&gt;",">"); // decode right angle bracket

// step 4 return svg for thread diagram
string body = "<body><dot>" + dot_string +  "</dot></body>";
return innov.applyMethod("Dot2Svg",body);
