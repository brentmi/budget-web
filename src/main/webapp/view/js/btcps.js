var tasksHash = new Hash();
var isIE = !!navigator.userAgent.match(/Trident/g) || !!navigator.userAgent.match(/MSIE/g);

function confirmUpdateMapping()
{
   if(! confirm('Are you sure you want to commit all DTT changes?'))
      return;
   
   autofillDtt();
   document.getElementById('saveDttinputFields').value = 'saveAll';
   document.forms[1].submit();
}

function updateCheckboxAction(obj, code, type)
{
   var isChecked = obj.checked;
   document.getElementById(type + '_' + code + '_I').checked = false;
   document.getElementById(type + '_' + code + '_U').checked = false;
   document.getElementById(type + '_' + code + '_D').checked = false;
   if(isChecked)
      obj.checked = true;
}

function autofillDtt()
{
   var inputs = document.getElementsByTagName('input');
   for(i = 0; i < inputs.length; i++)
   {
//      if(inputs.item(i).getAttribute('type') === 'checkbox')
//      {
//         var name = inputs.item(i).getAttribute('name');
//         if(name.search(/dttNeighboringCheckBoxMap/) > -1 && ! inputs.item(i).checked)
//         {
//            inputs.item(i).checked = 'true';
//            var origin = inputs.item(i).value.split('_')[0];
//            
//            inputs.item(i).value = origin + '_-1';
//         }
//      }
      if(inputs.item(i).getAttribute('type') === 'text')
      {
         var name = inputs.item(i).getAttribute('name');
         if(name.search(/dtt/) > -1 && inputs.item(i).value === '')
           inputs.item(i).value = 'null';
      }
   }
}

function updateAddUserDetails()
{
   if(! confirm('Commit changes for user details?'))
      return;
   
   document.getElementById('savesuserdetails').value = 'save';
   document.forms[2].submit();
}

function setLogDays()
{
//   var days = document.getElementsByName('logDaysToView');
//   for(var i = 0; i < days.length; i++)
//      if(days[i].checked)
//         document.getElementById('logViewDays').value = days[i].value;
   
   document.forms[1].submit();
}

function showhideTask(id)
{
   var t = tasksHash.getItem(id);
   
   for(var key in t.items)
   {
      document.getElementById(key).value = '';
      document.getElementById(key).value = t.getItem(key);
      
      if(key === 'etlRules')
      {
         generateHtmlEtlRuleSet(t.getItem(key), false);
      }
      else
      {   
         if(key === 'isPushed')
         {
            if(t.getItem('type') !== 'import')
               document.getElementById(key).disabled=true;
            else
               document.getElementById(key).disabled=false;
         }
      }
   }
   document.getElementById('deleteId').value = id;
}

function generateHtmlEtlRuleSet(strRule, plusOne)
{
   document.getElementById("exportEtlDiv").style.display = "none";
   
   if(plusOne)
      strRule = getFullEtlRuleSet();
   
   var div = 'etlOverrideRuleSet';
   document.getElementById(div).innerHTML = '';
   var button = '<button class="emsButton" style="width:50px;" type="button" name="addrow" onclick="generateHtmlEtlRuleSet(null, true);">+1</button>';
   if(strRule === '')
   {   
      document.getElementById(div).innerHTML = '<input type="text" size="80" id="etlInputRule_0" name="etlInputRuleSet"> : ETL Rule ' + button;
      return;
   }
   
   var ruleSet = strRule.split(';');
   if(ruleSet.length > 0)
      document.getElementById("exportEtlDiv").style.display = "block";
   
   var htmlDivStr = '<table>';
   for(var i = 0; i < ruleSet.length; i++)
   {
      htmlDivStr += '<tr><td><input type="text" size="80" id="etlInputRule_' 
              + i + '" name="etlInputRuleSet" value="' + ruleSet[i] + '"> : ETL Rule';
      
      if(i+1 < ruleSet.length)
         htmlDivStr += '</td></tr>';
      else if(i+1 === ruleSet.length)
      {
         if(! plusOne)
            htmlDivStr += button + '</td></tr>';
         else
            htmlDivStr += '</td></tr>';
      }
   }
   if(plusOne)
   {
      var next = ruleSet.length+1;
      htmlDivStr += '<tr><td><input type="text" size="80" id="etlInputRule_' 
              + next + '" name="etlInputRuleSet" value=""> : ETL Rule' + button + '</td></tr>';
   }
   
   htmlDivStr += '</table>';
   
   document.getElementById(div).innerHTML = htmlDivStr;
}

function confirmSaveInputUpdates()
{  
   if(! confirm('Save all input field updates to the database?'))
      return;
   
   document.getElementById('savebtcpsInputfields').value = 'saveAll';
   document.forms[1].submit();
}

function confirmUpload(destination)
{  
   if(document.getElementById('file').value == '')
   {
      alert('No file selected!');
      return;
   }
   
   if(! confirm('Upload File ' + document.getElementById('file').value + '?'))
      return;
      
   document.getElementById('localDirectory').value = destination;   
   document.forms[1].submit();
}

function confirmTaskDelete()
{
   //
   // TO-DO: add some form validation
   //
   if(document.getElementById('name').value === '')
   {   
      alert('You need to select a task to delete first.');
      return;
   }
   if(! confirm('Are you sure you want to delete the following task?\n\n' + document.getElementById('name').value))
      return;
   
   document.getElementById('deleteTask').value = 'delete';
   document.forms[2].submit();
}

function confirmTaskEdidSave()
{
   //
   // TO-DO: add some form validation
   //
   if(document.getElementById('name').value === '')
   {   
      alert('You need to select a task to modify first.');
      return;
   }
   if(! confirm('Are you sure you want to update the following task?\n\n' + document.getElementById('name').value))
      return;
   
   document.getElementById('saveEditTask').value = 'save';
   var strRuleSet = getFullEtlRuleSet();
   //alert(strRuleSet);
   document.getElementById('etlRules').value = strRuleSet;
   
   //return;
   document.forms[1].submit();
}

function getFullEtlRuleSet()
{
   var inputParams = document.getElementsByName('etlInputRuleSet');
   var etlParams = '';
   for(var i = 0; i < inputParams.length; i++)
   {
      var strParam = inputParams[i].value;
      if(strParam === '')
         continue;
      
      etlParams += strParam;
      if(i+1 < inputParams.length)
         etlParams += ';';
   }
   
   var lastSemi = etlParams.lastIndexOf(';');
   if(lastSemi+1 === etlParams.length)
      etlParams = etlParams.substring(0, lastSemi)
   
   return etlParams;
}

function confirmRunNow()
{
   if(! confirm('Are you sure you want to run the import/export processes?'))
      return;
   
   document.getElementById('forcerunnow').value = 'run';
   document.forms[1].submit();
}

function confirmSaveSchedule()
{
   //
   // TO-DO: add some form validation
   //
   if(document.getElementById('schedule').value === '')
   {   
      alert('Schedule cannot be empty.');
      return;
   }
   if(! confirm('Are you sure you want to update the Schedule settings?'))
      return;
   
   document.getElementById('saveschedule').value = 'save';
   document.forms[1].submit();
}

function moveListItem(listID, direction)
{
   var listbox = document.getElementById(listID);
   var selIndex = listbox.selectedIndex;
 
    if(-1 == selIndex) {
        alert("Please select an option to move.");
        return;
    }
 
    var increment = -1;
    if(direction == 'up')
        increment = -1;
    else
        increment = 1;
 
    if((selIndex + increment) < 0 ||
        (selIndex + increment) > (listbox.options.length-1)) {
        return;
    }
 
    var selValue = listbox.options[selIndex].value;
    var selText = listbox.options[selIndex].text;
    listbox.options[selIndex].value = listbox.options[selIndex + increment].value
    listbox.options[selIndex].text = listbox.options[selIndex + increment].text
 
    listbox.options[selIndex + increment].value = selValue;
    listbox.options[selIndex + increment].text = selText;
 
    listbox.selectedIndex = selIndex + increment;
}

function confirmSaveTaskReOrder()
{
   if(! confirm('Are you sure you want to update the run-order?'))
      return;
   
   document.getElementById('reorderTasks').value = 'save';
   var listbox = document.getElementById('taskOrder');
      for(var count=0; count < listbox.options.length; count++) 
         listbox.options[count].selected = true;
   
   document.forms[1].submit();
}

function Hash()
{
   this.length = 0;
   this.items = new Array();
   for (var i = 0; i < arguments.length; i += 2) {
      if (typeof(arguments[i + 1]) != 'undefined') {
         this.items[arguments[i]] = arguments[i + 1];
         this.length++;
      }
   }
   
   this.removeItem = function(in_key)
   {
      var tmp_value;
      if (typeof(this.items[in_key]) != 'undefined') {
         this.length--;
         var tmp_value = this.items[in_key];
         delete this.items[in_key];
      }
      
      return tmp_value;
   }

   this.getItem = function(in_key) {
      return this.items[in_key];
   }

   this.setItem = function(in_key, in_value)
   {
      if (typeof(in_value) != 'undefined') {
         if (typeof(this.items[in_key]) == 'undefined') {
            this.length++;
         }

         this.items[in_key] = in_value;
      }
      
      return in_value;
   }

   this.hasItem = function(in_key)
   {
      return typeof(this.items[in_key]) != 'undefined';
   }
}

var currentHelpTopic = null;
function help(topic)
{
   if(currentHelpTopic != null)
      closeHelp(currentHelpTopic);
      
   document.getElementById(topic).style.display = 'block';
   currentTopicHelp = topic;
}

function closeHelp(topic)
{
   document.getElementById(topic).style.display='none';
}