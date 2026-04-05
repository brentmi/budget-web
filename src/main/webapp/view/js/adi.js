// adi js library

const CommandsEnum = Object.freeze({

   "SSR_DEFAULT": 1,
   "SSR_CLEAR": 2,
   "SSR_EITHER": 3,
   "SSR_DEFAULT_CLEAR": 4

});
const LogsEnum = Object.freeze({

   "current_sync": 1,
   "sync_history": 2,
   "move_history": 3,
   "stalled_history": 4

});


const Transponders_Enum = Object.freeze({

   "HUME": 1,
   "BELROSE": 2,
   "LOCKRIDGE": 3

});


function createGroupContainer(title, id)
{

   var div1 = document.createElement("div");
   div1.classList.add('groupContainer');
   if (id.includes("art"))
      div1.style["float"] = "left";
   else
      div1.style["float"] = "right";

   div1.id = "group_" + id.toString();

   var div2 = document.createElement("div");
   div2.classList.add('headerbox');

   var div_row = document.createElement("div");
   div_row.classList.add("row");

   var label = document.createElement("label");
   label.classList.add("stableLabelWhite");

   if (title.includes("OPT"))
   {
      //title = "OPTUS10"
      title = title.replace("OPT", "OPTUS10");
   }

   label.innerHTML = title;
   label.id = "label_" + id.toString();

   var sat = label.innerHTML.split(",")[0];

   var dropDown = document.createElement("div");
   dropDown.classList.add('dropdown');
   dropDown.style["float"] = "right";
   dropDown.style["margin-right"] = "15px";

   var ddButton = createNewButton(id);
   var dropDownContent = document.createElement("div");
   dropDownContent.classList.add("dropdown-content");

   var l1 = document.createElement("a");
   var l2 = document.createElement("a");

   if (title.includes("OPT"))
   {
      l1.innerHTML = "Select HUME";
      l2.innerHTML = "Select BELROSE";
   }
   else
   {
      l1.innerHTML = "Select HUME";
      l2.innerHTML = "Select LOCKRIDGE";
   }

   l1.style["cursor"] = "pointer";
   l2.style["cursor"] = "pointer";

   l1.onclick = function ()
   {

      var transp = l1.innerHTML.split(" ")[1].trim();
      switch_transponder(sat, transp, label.id);

   }

   l2.onclick = function ()
   {

      var transp = l2.innerHTML.split(" ")[1].trim();
      switch_transponder(sat, transp, label.id);

   }

   dropDownContent.appendChild(l1);
   dropDownContent.appendChild(l2);


   dropDown.appendChild(ddButton)
   dropDown.appendChild(dropDownContent)

   div_row.appendChild(label);
   div_row.appendChild(dropDown);
   div2.appendChild(div_row);
   div1.appendChild(div2);

   return div1;

}

function switch_transponder(sat, transp, id)
{

   const response = confirm("Are you sure you want to set " + sat + " transponder location to " + transp + "?");

   if (!response)
   {

      return;
   }

   var flag_sent = false;

   switches.forEach(function (item, index)
   {

      if (item.sat === 'OPT' && document.getElementById(id).innerHTML.includes('OPT'))
      {
         if (item.site === 'ART')
         {
            document.getElementById('label_art_optus').innerHTML = sat + ", " + transp;
            if (transp === 'HUME')
               transponder_OPTUS10 = Transponders_Enum.HUME;
            else
               transponder_OPTUS10 = Transponders_Enum.BELROSE;
         }
         else
         {
            document.getElementById('label_oxf_optus').innerHTML = sat + ", " + transp;
            if (transp === 'HUME')
               transponder_OPTUS10 = Transponders_Enum.HUME;
            else
               transponder_OPTUS10 = Transponders_Enum.BELROSE;
         }

         if (flag_sent === false)
         {
            setTransporderLocation(item.sat, transponder_OPTUS10);
            flag_sent = true;
         }
      }
      else if (item.sat === 'D3' && document.getElementById(id).innerHTML.includes('D3'))
      {
         if (item.site === 'ART')
         {
            document.getElementById('label_art_d3').innerHTML = sat + ", " + transp;
            if (transp === 'HUME')
               transponder_D3 = Transponders_Enum.HUME;
            else
               transponder_D3 = Transponders_Enum.LOCKRIDGE;
         }
         else
         {
            document.getElementById('label_oxf_d3').innerHTML = sat + ", " + transp;
            if (transp === 'HUME')
               transponder_D3 = Transponders_Enum.HUME;
            else
               transponder_D3 = Transponders_Enum.LOCKRIDGE;
         }

         if (flag_sent === false)
         {
            setTransporderLocation(item.sat, transponder_D3)
            flag_sent = true;
         }
      }
   });


}


function createdescriptiveLabel()
{

   var label = document.createElement("label");
   label.innerHTML = "on call contact: ";
   label.id = "descriptivePlaceholder";

   label.style["align"] = "left";
   label.style["margin-left"] = "150px";
   return label;

}


function createSeparator()
{

   var label = document.createElement("label");
   label.innerHTML = "12345";
   label.id = "separationPlaceholder";

   label.style["align"] = "left";
   label.style["width"] = "100px";
   label.style["margin-left"] = "100px";

   return label;

}



function createOnCallLabel()
{

   var label = document.createElement("label");
   label.innerHTML = "";
   label.id = "onCallPlaceholder";
   label.style["align"] = "left";
   label.style["margin-left"] = "20px";

   return label;

}


function createOnCallDropdownButton(res)
{

   var lista = res;

   var dropDown = document.createElement("div");
   dropDown.classList.add('dropdown');
   dropDown.style["float"] = "right";
   dropDown.style["margin-top"] = "10px";
   dropDown.style["margin-left"] = "15px";

   var ddButton = createNewButton("onCallByttonId");
   var dropDownContent = document.createElement("div");
   dropDownContent.classList.add("dropdown-content");

   lista.forEach(function (item, index)
   {

      var l = document.createElement("a");
      l.style["cursor"] = "pointer";
      l.innerHTML = item.operator;

      l.onclick = function ()
      {
         select_contact_function(l.innerHTML)
      }

      dropDownContent.appendChild(l);

   });

   dropDown.appendChild(ddButton)
   dropDown.appendChild(dropDownContent)

   return dropDown;
}



function createHistoryDropdownButton()
{

   var dropDown = document.createElement("div");
   dropDown.classList.add('dropdown');
   dropDown.style["float"] = "right";
   dropDown.style["margin-top"] = "10px";
   dropDown.style["margin-left"] = "15px";

   var ddButton = createNewButton("historyByttonId");
   var dropDownContent = document.createElement("div");
   dropDownContent.classList.add("dropdown-content");

   var l1 = document.createElement("a");
   l1.style["cursor"] = "pointer";
   l1.innerHTML = "get current sync errors";

   var l2 = document.createElement("a");
   l2.style["cursor"] = "pointer";
   l2.innerHTML = "get sync errors history";

   var l3 = document.createElement("a");
   l3.style["cursor"] = "pointer";
   l3.innerHTML = "get move request history";

   var l4 = document.createElement("a");
   l4.style["cursor"] = "pointer";
   l4.innerHTML = "get stalled autosync rqs";

   l1.onclick = function ()
   {
      get_log_function(LogsEnum.current_sync)
   }
   l2.onclick = function ()
   {
      get_log_function(LogsEnum.sync_history)
   }
   l3.onclick = function ()
   {
      get_log_function(LogsEnum.move_history)
   }
   l4.onclick = function ()
   {
      get_log_function(LogsEnum.stalled_history)
   }

   dropDownContent.appendChild(l1);
   dropDownContent.appendChild(l2);
   dropDownContent.appendChild(l3);
   dropDownContent.appendChild(l4);

   dropDown.appendChild(ddButton)
   dropDown.appendChild(dropDownContent)

   return dropDown;
}

function createServiceContainer(title, id)
{

   var div1 = document.createElement("div");
   div1.classList.add('streamContainer');
   if (id.includes("art"))
      div1.style["float"] = "left";
   else
      div1.style["float"] = "right";

   div1.id = "group_" + id.toString();

   var div2 = document.createElement("div");
   div2.classList.add('headerbox');

   var div_row = document.createElement("div");
   div_row.classList.add("row");

   var label = document.createElement("label");
   label.classList.add("stableLabelWhite");

   label.innerHTML = title;

   var dropDown = document.createElement("div");
   dropDown.classList.add('dropdown');
   dropDown.style["float"] = "right";
   dropDown.style["margin-right"] = "15px";

   var ddButton = createNewButton(id);
   var dropDownContent = document.createElement("div");
   dropDownContent.classList.add("dropdown-content");

   if (id === "channelsContainerId")
   {

      var l1 = document.createElement("a");
      l1.style["cursor"] = "pointer";
      l1.innerHTML = "Set All Clear";

      var l2 = document.createElement("a");
      l2.style["cursor"] = "pointer";
      l2.innerHTML = "Set All Scrambled";

      l1.onclick = function ()
      {
         setAllServiceState("CLEAR")
      }
      l2.onclick = function ()
      {
         setAllServiceState("SCRAMBLED")
      }
      dropDownContent.appendChild(l1);
      dropDownContent.appendChild(l2);
   }

   dropDown.appendChild(ddButton)
   dropDown.appendChild(dropDownContent)

   div_row.appendChild(label);
   div_row.appendChild(dropDown);
   div2.appendChild(div_row);
   div1.appendChild(div2);

   return div1;

}

function createStreamContainer(title, id)
{

   var div1 = document.createElement("div");
   div1.classList.add('streamContainer');
   if (id.includes("art"))
      div1.style["float"] = "left";
   else
      div1.style["float"] = "right";

   div1.id = "group_" + id.toString();

   var div2 = document.createElement("div");
   div2.classList.add('headerbox');

   var div_row = document.createElement("div");
   div_row.classList.add("row");

   var label = document.createElement("label");
   label.classList.add("stableLabelWhite");

   label.innerHTML = title;

   var dropDown = document.createElement("div");
   dropDown.classList.add('dropdown');
   dropDown.style["float"] = "right";
   dropDown.style["margin-right"] = "15px";

   var ddButton = createNewButton(id);
   var dropDownContent = document.createElement("div");
   dropDownContent.classList.add("dropdown-content");

   if (id === "channelsContainerId")
   {

      var l1 = document.createElement("a");
      l1.style["cursor"] = "pointer";
      l1.innerHTML = "Set All Clear";

      var l2 = document.createElement("a");
      l2.style["cursor"] = "pointer";
      l2.innerHTML = "Set All Scrambled";

      l1.onclick = function ()
      {
         setAllServiceState("CLEAR")
      }
      l2.onclick = function ()
      {
         setAllServiceState("SCRAMBLED")
      }
      dropDownContent.appendChild(l1);
      dropDownContent.appendChild(l2);
   }

   dropDown.appendChild(ddButton)
   dropDown.appendChild(dropDownContent)

   div_row.appendChild(label);
   div_row.appendChild(dropDown);
   div2.appendChild(div_row);
   div1.appendChild(div2);

   return div1;

}




function createNewButton(id)
{
   var button = document.createElement("input");
   button.type = "button";
   button.value = "▼";
   button.id = "new-" + id + "-dropdown-button";
   button.name = button.id;
   button.style["cursor"] = "pointer";

   return button;
}

function createCanvas(site)
{

   var canvas = document.createElement("canvas");
   canvas.left = 0;
   canvas.top = 0
   canvas.width = "300";
   canvas.height = "150";
   canvas.id = "canvas-" + site;
   canvas.style.zIndex = 8;
   canvas.style.position = "absolute";
   canvas.style.border = "1px solid";
   return canvas;

}

function createGroupButton(group, site, sat)
{

   var button = document.createElement("input");
   button.type = "button";
   button.classList.add('btn');

   if (group.out_of_sync === true)
   {
      button.classList.add('btn-danger');
      button.title = "Group : out of sync";
   }
   else if (group.active_site === site)
   {
      button.classList.add('btn-success');
      button.title = "Group : active";
   }
   else
   {
      button.classList.add('btn-primary.disabled');
      button.title = "Group : inactive";
   }

   button.value = "Grp " + group.group_id.toLocaleString('en-US', {minimumIntegerDigits: 2, useGrouping: false}) + " - " + group.ts_id;

   button.id = "site-" + site + "-sat-" + sat + "-group-" + group.group_id;
   button.name = button.id;
   button.style["cursor"] = "pointer";
   button.style["margin"] = "10px";

   button.onclick = function ()
   {
      group.buttonId = button.id;
      group.selected_site = site;
      switch_device_function(group);
   }
   group.sat = sat;
   button.group = group;

   return button;
}



function createStreamButton(item)
{

   var button = document.createElement("input");
   button.type = "button";
   button.classList.add('btn');

   if (item.total == item.defaults)
   {
      button.classList.add('btn-success');
      button.title = "DEFAULT";
      button.value = "Stream " + item.out_stream_id + " DEFAULT";
   }
   else if (item.total == item.clear)
   {
      button.classList.add('btn-danger');
      button.title = "CLEAR";
      button.value = "Stream " + item.out_stream_id + " CLEAR";
   }
   else
   {
      button.classList.add('btn-warning');
      button.title = "MIXED";
      button.value = "Stream " + item.out_stream_id + " MIXED";
   }


   if(item.sync_error == true)
   {
      var classList = button.classList;
      while (classList.length > 0) {
         classList.remove(classList.item(0));
      }
      button.classList.add('btn');
      button.classList.add('.btn-default');
   }

   button.id = "stream-" + item.out_stream_id + "-button";
   button.name = button.id;
   button.style["cursor"] = "pointer";
   button.style["margin"] = "10px";
   button.style["width"] = "100px";
   button.style["white-space"] = "normal";
   button.style["display"] = "inline-flex";

   button.onclick = function ()
   {
      getServiceLevel(item.out_stream_id, true);
   }

   return button;
}

function createNmxGroupButton(items, id)
{

   var button = document.createElement("input");
   button.type = "button";
   button.classList.add('btn');

   var total = 0, defaults = 0, clear = 0;

   items.forEach(function (item, index)
   {

      total += 1;
      if (item.nmxStatus === "Scramble")
         defaults += 1;
      else
         clear += 1;
   });

   if (total == defaults)
   {
      button.classList.add('btn-success');
      button.title = "DEFAULT";
      button.value = "Stream " + id.toString() + " DEFAULT";
   }
   else if (total == clear)
   {
      button.classList.add('btn-danger');
      button.title = "CLEAR";
      button.value = "Stream " + id.toString() + " CLEAR";
   }
   else
   {
      button.classList.add('btn-warning');
      button.title = "MIXED";
      button.value = "Stream " + id.toString() + " MIXED";
   }

   button.id = "nmxGroup-" + id.toString() + "-button";
   button.name = button.id;
   button.style["cursor"] = "pointer";
   button.style["margin"] = "10px";
   button.style["width"] = "100px";
   button.style["white-space"] = "normal";
   button.style["display"] = "inline-flex";

   button.onclick = function ()
   {
      update_nmx_services(items, id);
   }

   return button;
}

/*
 NMX api
 */

function createServiceButton(item)
{

   var button = document.createElement("input");
   button.type = "button";
   button.classList.add('btn');

   var command = CommandsEnum.SSR_EITHER;

   if (item.nmxStatus == "Scramble")
   {
      button.classList.add('btn-success');
      button.title = "DEFAULT";
      button.value = item.Channel + " " + item.Name + " DEFAULT";
      command = CommandsEnum.SSR_CLEAR;
   }
   else if (item.nmxStatus == "Clear")
   {
      button.classList.add('btn-danger');
      button.title = "CLEAR";
      button.value = item.Channel + " " + item.Name + " CLEAR";
      command = CommandsEnum.SSR_DEFAULT;
   }
   else
   {
      button.classList.add('btn-warning');
      button.title = "UNKNOWN";
      button.value = item.Channel + " " + item.Name + " UNKNOWN";
   }

   button.id = "service-" + item.ServiceNumber + "-button";
   button.name = button.id;

   button.style["cursor"] = "pointer";
   button.style["margin"] = "10px";
   button.style["width"] = "350px";
   button.style["white-space"] = "normal";
   button.style["display"] = "inline-flex";

   button.onclick = function ()
   {
      setNmxServiceScrambledState(item, command);
   }

   return button;
}

function createChannelButton(item, bmsIsMaster)
{
//   console.log("createChannelButton(");
//   console.log(item);
   var button = document.createElement("button");
   button.type = "button";
   button.classList.add('btn');

   var command = CommandsEnum.SSR_EITHER;
   var ssr_status = undefined;

   var span = document.createElement("span");
   span.classList.add('badge');
   span.style["align"] = "left";
   span.style["margin-right"] = "1em";

   button.title = "Service Id: " + item.si_service_id + ", Service Key: " + item.si_service_key;

   if (item.defaults === item.clear)
   {
      ssr_status = "Clear";
      button.classList.add('btn-success');
      button.innerHTML = item.source_chan_id + " " + item.name + " Default CLEAR &nbsp;";
      command = CommandsEnum.SSR_DEFAULT_CLEAR;
   }
   else if (item.total == item.defaults)
   {
      ssr_status = "Scramble";
      button.classList.add('btn-success');
      button.innerHTML = item.source_chan_id + " " + item.name + " SCRAMBLE &nbsp;";
      command = CommandsEnum.SSR_CLEAR;
   }
   else if (item.total == item.clear)
   {
      ssr_status = "Clear";
      button.classList.add('btn-danger');
      button.innerHTML = item.source_chan_id + " " + item.name + " CLEAR &nbsp;";
      command = CommandsEnum.SSR_DEFAULT;
   }
   else if (item.clear == 0)
   {
      button.classList.add('btn-dark');
      button.innerHTML = item.source_chan_id + " " + item.name + " INVALID &nbsp;";
      ssr_status = "Invalid";
   }
   else
   {
      button.classList.add('btn-dark');
      button.innerHTML = item.source_chan_id + " " + item.name + " UNKNOWN &nbsp;";
      ssr_status = "Unknown";
   }

   button.id = "channel-" + item.source_chan_id + "-button";

   if (item.Phantom === true)
   {
      button.name = "si_service_id_" + "undefined" + "_stream_" + item.stream.toString();
      span.id = "channel-" + "undefined" + "-span";
   }
   else
   {
      button.name = "si_service_id_" + item.si_service_id.toString() + "_stream_" + item.stream.toString();
      span.id = "channel-" + item.si_service_id.toString() + "-span";
   }

   button.style["cursor"] = "pointer";
   button.style["margin"] = "10px";
   button.style["width"] = "415px";
   button.style["white-space"] = "normal";
   button.style["display"] = "inline-flex";

   //console.log("item.nmxStatus.length = " + item.nmxStatus.length);
   
   
   let dislplayText = getClrScrDisplayString(item, bmsIsMaster);
   
   if(item.nmxStatus[0].length > 0 && item.si_gen_status[0].length > 0)
   {
      // everything
      if (item.nmxStatus[0] === ssr_status && item.nmxStatus[1] === ssr_status && item.si_gen_status[0]  === ssr_status)
      {
         // all good
         span.innerHTML = dislplayText + "&nbsp;&#10003;";
      }
      else
      {
         removeAddClass(button, 'btn-dark');
         span.innerHTML = dislplayText + "&nbsp;&#9888;"
      }
      
   }
   else if(item.nmxStatus[0].length > 0 && item.si_gen_status[0].length == 0)
   {
      // nmx - no si_gen
      if (item.nmxStatus[0] === ssr_status && item.nmxStatus[1] === ssr_status)
      {
         // all good
         span.innerHTML = dislplayText + "&nbsp;&#10003;";
      }
      else
      {
         // dont match
         removeAddClass(button, 'btn-dark');
         span.innerHTML = dislplayText + "&nbsp;&#9888;"
      }
   }
   else if(item.nmxStatus[0].length == 0 && item.si_gen_status[0].length > 0)
   {
      // si_gen - no nmx
      if (item.si_gen_status[0]  === ssr_status)
      {
         // all good
         span.innerHTML = dislplayText + "&nbsp;&#10003;";
      }
      else
      {
         // dont match
         removeAddClass(button, 'btn-dark');
         span.innerHTML = dislplayText + "&nbsp;&#9888;"
      }
   }
   else // bms or ssr only
   {   
       span.innerHTML = dislplayText;
   }
   
   
//   if (item.nmxStatus.length === 2 && item.nmxStatus[0].length > 0 && item.nmxStatus[1].length > 0)
//   {
//      console.log("====>>> this is X1!!!");
//      console.log(item);
//      console.log("====>>> END X1!!!");
//      //alert('this doenst normally fire - check console.log!')
//      // 2 nxm server results, why? anyhow...
//      if (item.nmxStatus !== "" && item.nmxStatus[0] === ssr_status && item.nmxStatus[1] === ssr_status && item.si_gen_status[0] === "")
//      {
//         // again I dont think we should be falling into this bliock.
//         //alert('sigen should have service_id??? look closer!!!!');
//         span.innerHTML = "nmx/ssr&nbsp;&#10003;";
//      }
//      else if (item.nmxStatus !== "" && item.nmxStatus[0] === ssr_status && item.nmxStatus[1] === ssr_status && item.si_gen_status[0] === ssr_status)
//      {
//         span.innerHTML = "nmx/ssr/sigen&nbsp;&#10003;";
//      }
//      else
//      {
//         if (ssr_status === "Clear")
//         {
//            button.classList.remove('btn-danger');
//         }
//         else
//         {
//            button.classList.remove('btn-success');
//         }
//
//         if (item.nmxStatus[0] === item.nmxStatus[1])
//            button.classList.add('btn-dark');
//         else
//            button.classList.add('btn-primary');
//
//         if (item.si_gen_status[0] === "")
//            span.innerHTML = "nmx/ssr&nbsp;&#9888;"; // warning sign because nmx and ssr don't match!!!
//         else
//            span.innerHTML = "nmx/ssr/sigen&nbsp;&#9888;";
//
//      }
//
//   }
//   else if (item.nmxStatus[0].length > 0) // true when this: 'nmxStatus': ['Scramble', 'Scramble', '']
//   {
//      console.log("====>>> this is BBBB!!!");
//      console.log(item);
//      console.log("====>>> END BBBB!!!");
//      //this appears to be the only block we fall into. length is always 1 or 3 for the nnx rubbish
//      // len is 1 when there is no status 'nmxStatus': ['']
//      // len is 3 when there is(with the 3rd element being empty: 'nmxStatus': ['Scramble', 'Scramble', '']
//
//      //console.log("item.nmxStatus[0] = " + typeof(item.nmxStatus[0]) + " ssr_status = " + typeof(ssr_status) + " item.si_gen_status = " + typeof(item.si_gen_status));
//      if (item.nmxStatus[0] === ssr_status && item.nmxStatus[1] === ssr_status && item.si_gen_status[0] === "")
//      {
//         span.innerHTML = "nmx/ssr&nbsp;&#10003;";
//      }
//      else if (item.nmxStatus[0] === ssr_status && item.nmxStatus[1] === ssr_status && item.si_gen_status[0] === ssr_status)
//      {
//         span.innerHTML = "nmx/ssr/sigen&nbsp;&#10003;";
//      }
//      else
//      {
//         if (ssr_status === "Clear")
//         {
//            button.classList.remove('btn-danger');
//         }
//         else
//         {
//            button.classList.remove('btn-success');
//         }
//         button.classList.add('btn-dark');
//
//         if (item.si_gen_status[0] === "")
//            span.innerHTML = "nmx/ssr&nbsp;&#9888;"; // warning sign because nmx and ssr don't match!!!
//         else
//            span.innerHTML = "nmx/ssr/sigen&nbsp;&#9888;";
//
//      }
//   }
//   else if (item.Phantom) // true when 'Phantom': True
//   {
//      console.log("====>>> this is PHANTOM!!!");
//      console.log(item);
//      console.log("====>>> END PHANTOM!!!");
//      span.innerHTML = "phantom";
//   }
//   else // otherwise this? 'nmxServiceId': ['']
//   {
//      console.log("====>>> this is ELSE!!!");
//      console.log(item);
//      console.log("====>>> END ELSE!!!");
//      if (item.si_gen_status[0] !== "")
//         span.innerHTML = "ssr/sigen&nbsp;";
//      else
//         span.innerHTML = "ssr only&nbsp;";
//   }

   if(bmsIsMaster)
      item.BMS_Status = ssr_status;
   else
      item.SSR_Status = ssr_status;
   
   button.title = JSON.stringify(item, null, 3);
   button.prepend(span);

   button.onclick = function ()
   {
      setServiceScrambledState(item, command, item.Phantom);
   }

   return button;
}

function removeAddClass(button, klass)
{
   button.classList.remove('btn-danger');
   button.classList.remove('btn-success');
   button.classList.remove('btn-dark');
   
   button.classList.add(klass);
}

function getClrScrDisplayString(item, bmsIsMaster)
{
   let dislplayText = "ssr";
   if(bmsIsMaster)
      dislplayText = "bms";
   
   if(item.nmxStatus[0].length > 0 && item.si_gen_status[0].length > 0)
   {
      // everything
      dislplayText += "/nmx/sigen";
   }
   else if(item.nmxStatus[0].length > 0 && item.si_gen_status[0].length == 0)
   {
      // nmx - no si_gen
      dislplayText += "/nmx";
   }
   else if(item.nmxStatus[0].length == 0 && item.si_gen_status[0].length > 0)
   {
      // si_gen - no nmx
      dislplayText += "/sigen";
   }
   else // bms or ssr only
   {   
       dislplayText += " only";
   }
   
   if(item.Phantom)
      dislplayText += " phantom";
   
   
   return dislplayText;
}
function createTestSwitch(id)
{

   var swap = false;

   var switchcontainer = document.createElement("div");
   switchcontainer.classList.add('switchcontainer');
   switchcontainer.onclick = function ()
   {

      swap = !checkbox.checked;

      if (swap)
      {

         checkbox.checked = true;

      }
      else
      {

         checkbox.checked = false;

      }

      setControlMode(checkbox.checked);

   }


   var onoffswitch = document.createElement("div");
   onoffswitch.classList.add('onoffswitch');

   var checkbox = document.createElement("input");
   checkbox.type = "checkbox";
   checkbox.classList.add('onoffswitch-checkbox');
   checkbox.id = id;
   checkbox.tabIndex = 1;

   var label = document.createElement("label");
   label.classList.add('onoffswitch-label');
   label.for = id;

   var span1 = document.createElement("span");
   span1.classList.add('onoffswitch-inner');

   var span2 = document.createElement("span");
   span2.classList.add('onoffswitch-switch');

   label.appendChild(span1);
   label.appendChild(span2);

   onoffswitch.appendChild(checkbox);
   onoffswitch.appendChild(label);
   switchcontainer.appendChild(onoffswitch);

   return switchcontainer;

}

function createAllertTable(obj)
{

   var tableArray = [];

   var x = ["Stream ID", "Service ID", "Channel Name", "Harmonic Status"];

   parent = document.getElementById("alertLabel");
   while (parent.children.length > 1)
   {
      parent.removeChild(parent.lastChild);
   }

   obj.forEach(function (item, index)
   {

      tableRow = [];
      tableRow.push(item.Group);
      tableRow.push(item.ServiceNumber);
      tableRow.push(item.Name);
      tableRow.push(item.nmxStatus);
      tableArray.push(tableRow);

   });

   tableArray.unshift(x);

   let table = document.createElement('table');
   for (let row of tableArray)
   {
      table.insertRow();
      for (let cell of row)
      {
         let newCell = table.rows[table.rows.length - 1].insertCell();
         newCell.textContent = cell;
      }
   }

   table.classList.add('center');
   document.getElementById("alertLabel").appendChild(table);

}

function updateButtonStatus(obj, set)
{

   //console.log("updateButtonStatus(");
   //console.log(obj);
   obj.forEach(function (item, index)
   {

      var name = "si_service_id_" + item.ServiceNumber.toString() + "_stream_" + item.Group.toString()
      var button = document.getElementsByName(name)[0];

      if (button !== undefined)
      {

         var id = "channel-" + item.ServiceNumber.toString() + "-span";
         var span = document.getElementById(id);

         params = JSON.parse(button.title);


         if (set === true)
         {

            params.nmxStatus = item.nmxStatus;
            button.title = JSON.stringify(params, null, 3);

            if (params.defaults === params.clear || params.total == params.clear)
            {
               button.classList.remove('btn-danger');
            }
            else
            {
               button.classList.remove('btn-success');
            }
            button.classList.add('btn-dark');

            //console.log(span.innerHTML);
            // nmx/ssr/sigen
            // fucking cluncky!
            if (span.innerHTML.length > 10)
               span.innerHTML = "nmx/ssr/sigen&nbsp;&#9888;";
            else
               span.innerHTML = "nmx/ssr&nbsp;&#9888;"; // warning sign because nmx and ssr don't match!!!
         }
         else
         {

            if (item.nmxStatus === "Scramble")
            {

               params.nmxStatus = "Clear";
            }
            else
            {

               params.nmxStatus = "Scramble";
            }
            button.title = JSON.stringify(params, null, 3);

            button.classList.remove('btn-dark');

            if (params.defaults === params.clear || params.total == params.clear)
            {
               button.classList.add('btn-danger');
            }
            else
            {
               button.classList.add('btn-success');
            }
            if (span.innerHTML.length > 10)
               span.innerHTML = "nmx/ssr/sigen&nbsp;&#10003;"
            else
               span.innerHTML = "nmx/ssr&nbsp;&#10003;"

         }

      }

   });
}

function show_allert_tab(allertMessage, duration)
{

   document.getElementById("alertText").innerHTML = allertMessage;
   document.getElementById("alertLabel").style.display = "block";
   document.getElementById("alertText").style.opacity = 1;

   if (duration > 0)
   {

      clearInterval(myInterval);
      myInterval = undefined;
      setTimeout(function ()
      {

         document.getElementById("alertLabel").style.display = "none";

      }, duration);
   }
   else
   {

      myInterval = setInterval(
              () => blinker(1000), 2000)
   }
}

function blinker(duration)
{

   led = document.getElementById("alertText");
   led.style.display = "block";
   led.style.opacity = 1;

   setTimeout(function ()
   {

      if (myInterval !== undefined)
      {
         led.style.opacity = 0.2;
      }

   }, duration);

}

