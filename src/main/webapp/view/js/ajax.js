var xmlhttp;
function loadXMLDoc(url, cfunc)
{
   //alert(url);
   if (window.XMLHttpRequest)
   {// code for IE7+, Firefox, Chrome, Opera, Safari
      xmlhttp = new XMLHttpRequest();
   }
   else
   {// code for IE6, IE5
      xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
   }
   xmlhttp.onreadystatechange = cfunc;
   xmlhttp.open("GET", url, true);
   xmlhttp.send();
}

function getUserDetails(id)
{
   if(id == -1)
      return;
   
   loadXMLDoc('/BTChannelPlan/UserAdmin?getUserDetails=true&id=' + id, function()
   {
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         obj = JSON.parse(xmlhttp.responseText);
         
         document.getElementById('fullName').value = obj.fullName;
         document.getElementById('email').value = obj.email;
         document.getElementById('username').value = obj.username;
         document.getElementById('permissionSetDiv').innerHTML = obj.accessLevels;
         document.getElementById('userId').value = obj.id;
         
         if(obj.username === 'admin')
            document.getElementById('username').disabled = true;
         else
            document.getElementById('username').disabled = false;
      }
   });
}

function displayReportParameters(selectListName, fieldValues, rptType)
{
   loadXMLDoc('/BTChannelPlan/ReportRequest?getReportParams=true&selectListName=' + selectListName, function()
   {
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById(rptType+'ReportParamsDiv').innerHTML = xmlhttp.responseText;
         if(fieldValues != null)
         {
            var input = fieldValues.split(";");
            for(var i = 0; i < input.length; i++)
            {   
//               /alert('adding ' + (input[i].split("=")[1]) + ' to ' + input[i].split("=")[0]);
               document.getElementById(input[i].split("=")[0]).value = input[i].split("=")[1];
            }
         }   
      }
   });
}

function checkAndRunReport(rptType)
{
   var fieldValues = '';
   var fields = Array();
   
   var name = document.getElementById(rptType+'ReportSelectListId').options[document.getElementById(rptType+'ReportSelectListId').selectedIndex].value;
   if(name === '-1')
      return;
   
   if(document.getElementById(rptType+'_rpt_fields_List').value === 'none')
      fieldValues = 'params=none';
   else
   {   
      fields = document.getElementById(rptType+'_rpt_fields_List').value.split(';');
      for(var i = 0; i < fields.length; i++)
      {
         var input = document.getElementById(fields[i]);
         if(input.value === '')
         {   
            alert('Input field ' + (i+1) + ' needs a value.');
            return;
         }
         
//         if(input.value.split(" ").length > 1)
//            fieldValues += fields[i] + '=\'' + input.value + '\';';
//         else
            fieldValues += fields[i] + '=' + input.value + ';';
      }
   }
   document.getElementById(rptType+'RunReportButton').disabled = true;
   // document.getElementById('cobaltGenerateSelect').disabled = true;
   
   fieldValues = fieldValues.substring(0, fieldValues.length -1);
   
   runReport(fieldValues, name, rptType);
   
}

function runLinkedReport(rptType, rptName, fieldValues)
{
   var sel = document.getElementById(rptType+'ReportSelectListId');
   var opts = sel.options;
   for(var opt, j = 0; opt = opts[j]; j++) 
   {
      if(opt.value === rptName) 
      {
         sel.selectedIndex = j;
         break;
      }
   }
   
   runReport(fieldValues, rptName, rptType);
}

function runReport(fieldValues, rptName, rptType)
{
   var me = this;
   
   // Remove any & symbols before transmission as it screws up the query string.
   loadXMLDoc('/BTChannelPlan/ReportRequest?runReport='+rptType+'&fields='+encodeURI(fieldValues.replace(/&/g, '%26'))+'&name='+rptName, function()
   {
      document.getElementById(rptType+'ReportResultDiv').innerHTML = 'Selected report is running...';
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById(rptType+'ReportResultDiv').innerHTML = xmlhttp.responseText;
         document.getElementById(rptType+'RunReportButton').disabled = false;
         me.displayReportParameters(rptName, fieldValues, rptType);
      }
   });
}

function showCurrentDttMapping()
{
   loadXMLDoc('/BTChannelPlan/DttMapData?Neighbors=true&id=1', function()
   {
      //alert('xmlhttp.readyState='+xmlhttp.readyState + ' xmlhttp.status=' +xmlhttp.status);
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById('dttNeighborContainer').innerHTML = xmlhttp.responseText;
      }
   });
}

function loadReports(rptType)
{
   var selectListId = rptType+'ReportSelectListId',
       selectDiv = rptType+'ReportSelectDiv', 
       resultDiv = rptType+'ReportResultDiv', 
       paramsDiv = rptType+'ReportParamsDiv';
       
   var me = this;
  
   // Will only exist when the appropriate reports tab is selected and the page loads.
   if(! document.getElementById(selectDiv))
      return;
  
   document.getElementById(selectDiv).innerHTML = '<select><option value="default">Please wait ...... </option></select>';
   document.getElementById(paramsDiv).innerHTML = '';
   // document.getElementById('cobaltGenerateSelect').disabled = true;
   
   loadXMLDoc('/BTChannelPlan/ReportRequest?getAvailableReports='+rptType+'&selectListId=' + selectListId + '&selectDiv=' + selectDiv + '&resultDiv=' + resultDiv + '&paramsDiv=' + paramsDiv, function()
   {
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById(selectDiv).innerHTML = xmlhttp.responseText;
         me.displayDefaultDescriptions();
      }
   });
}

function displayDefaultDescriptions()
{
   loadXMLDoc('/BTChannelPlan/ReportRequest?getDefaultRptDescriptions=true', function()
   {
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById('cobaltReportResultDiv').innerHTML = xmlhttp.responseText;
      }
   });
}

function getDttNeighboringRegions(id, type, div)
{
   loadXMLDoc('/BTChannelPlan/DttMapData?' + type + '=true&id=' + id, function()
   {
      //alert('xmlhttp.readyState='+xmlhttp.readyState + ' xmlhttp.status=' +xmlhttp.status);
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById(div).innerHTML = xmlhttp.responseText;
      }
   });
 }

function getDttTableData(id, type, div)
{
   loadXMLDoc('/BTChannelPlan/DttMapData?' + type + '=true&id=' + id, function()
   {
      //alert('xmlhttp.readyState='+xmlhttp.readyState + ' xmlhttp.status=' +xmlhttp.status);
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById(div).innerHTML = xmlhttp.responseText;
      }
   });
 }
 
function getStatsResult(type, days, menu, div)
{
   var daysValue = 0;
   if(document.getElementById(days))
      daysValue = document.getElementById(days).value;
   
   var menuObj = document.getElementById(menu);
   var id = menuObj.options[menuObj.selectedIndex].value;
   if(id == null || id == -1)
      return;
   
   //alert('sending: id=' +id + ' days=' +daysValue + ' type=' + type + ' div=' + div);
   loadXMLDoc('/BTChannelPlan/ReportRequest?' + type + '=true&days=' + daysValue + '&id=' + id, function()
   {
      //alert('xmlhttp.readyState='+xmlhttp.readyState + ' xmlhttp.status=' +xmlhttp.status);
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById(div).innerHTML = xmlhttp.responseText;
      }
   });
 }
 
function setScheduleRptDefaults()
{
   var days = document.getElementById('scheduleRptDays').value;
   var start = document.getElementById('scheduleRptStartTime').value;
   var end = document.getElementById('scheduleRptEndTime').value;
   
   if(days === '' || ! /\d+/.test(days) || parseInt(days) > 14)
   {
      alert('Please supply a valid Days value between 1 and 14 to continue.');
      return;
   }
   
   var dateFmt = /\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d/;
   if(start === '' || ! dateFmt.test(start) || end === '' || ! end === '' || ! dateFmt.test(end))
   {
      alert('Please supply a valid in the format yyyy-mm-dd hh:mm:ss.');
      return;
   }
 
   var startHms = start.split(" ")[1];
   var endHms = end.split(" ")[1];
   
   loadXMLDoc('/BTChannelPlan/ReportRequest?saveScheduleRptDefaults=true&start=' + startHms + '&end=' + endHms + '&interval=' + days, function()
   {
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById('setScheduleReportDefault').value = 'Saved';
         document.getElementById('setScheduleReportDefault').disabled = true;
      }
   });
}

function runPESCmd()
{
   var requestType = null;
   var request = document.getElementsByName('pesRequestType');
   var resultDiv = 'pesRequestResultDiv';
   var asset = '';
   var caAction;
   
   for (var i = 0; i < request.length; i++) 
   {
      if (request[i].checked) 
      {
         requestType = request[i].value;
         break;
      }
   }
   
   if(requestType === null)
   {
      alert('Please select a request type.');
      return;
   }
   
   if(requestType === 'ca')
   {
      asset = document.getElementById('pesAssetName').value;
      var e = document.getElementById("caRequestAction");
      caAction = e.options[e.selectedIndex].value;
      if(parseInt(caAction) === 0)
      {
         alert('You need to select a Change Asset action.');
         return;
      }

      if(asset === '')
      {
         alert('When requesting ChangeAsset the asset field cannot be empty.');
         return;
      }
   }
   document.getElementById(resultDiv).innerHTML = '';
   document.getElementById('runPESCmd').disabled = true;
   loadXMLDoc('/BTChannelPlan/Utils?action=runPESCmd&pesRequest=' + requestType + '&pesAsset=' + asset + '&pesAssetAction=' + caAction, function()
   {
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById(div).innerHTML = xmlhttp.responseText;
         return;
      }
   });
   
   var count = 0;
   var finished = false;
   (function loop()
   {
      var currentContent = document.getElementById(resultDiv).innerHTML;
      setTimeout(function()
      {
         if(finished)
            return;
         
         if(++count > 30)
         {
            document.getElementById(resultDiv).innerHTML = currentContent + '<br>Irdeto PES request failed, timed out after 30 seconds!';
            return;
         }

         try
         { 
            loadXMLDoc('/BTChannelPlan/Utils?action=getPesResult', function()
            {
               if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
               {
                  var response = xmlhttp.responseText;
                  if(/exit:/.test(response))
                  {
                     if(! /exit:0/.test(response))
                        document.getElementById(resultDiv).innerHTML = response + '<p>Irdeto PES request complete but errors detected!';
                     else
                     {   
                        response = response.replace("exit:0<br>", "");
                        document.getElementById(resultDiv).innerHTML = response;
                     }
                        
                     finished = true;
                     
                     document.getElementById('runPESCmd').disabled = false;
                     document.getElementById('pesAssetName').value = '';
                     document.getElementById('caRequestAction').options[0].selected = true;
                  } 
                  else
                     document.getElementById(resultDiv).innerHTML = response;
        
                  return;
               }
            });
         }
         catch(e)
         {
            document.getElementById(resultDiv).innerHTML = currentContent + '<br>An unkown error has occurred: ' + e;
            return;
         }
         loop();
      }, 1000);
   })();
}

function runScheduleRpt(div, type)
{
   var tag = document.getElementById('scheduleRptTag').value;
   var start = document.getElementById('scheduleRptStartTime').value;
   var end = document.getElementById('scheduleRptEndTime').value;
   
   var downloadableFiles = '';
   
   var filesDownloadCb = document.getElementsByName('schedRptFileWrite');
   
   for(var i = 0; i < filesDownloadCb.length; i++)
   {
      if(filesDownloadCb[i].checked)
      {
         downloadableFiles += filesDownloadCb[i].value + ',';
      }
   }
   downloadableFiles = downloadableFiles.substring(0, downloadableFiles.length - 1);
  
   if(tag === '')
   {
      alert('Please supply a valid TAG or ServiceKey.');
      return;
   }
   
   var dateFmt = /\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d/;
   if(start === '' || ! dateFmt.test(start) || end === '' || ! end === '' || ! dateFmt.test(end))
   {
      alert('Please supply a valid in the format yyyy-mm-dd hh:mm:ss.');
      return;
   }
   
   loadXMLDoc('/BTChannelPlan/ReportRequest?' + type + '=true&tag=' + tag + '&start=' + start + '&end=' + end + '&dlfiles=' + downloadableFiles, function()
   {
      //alert('/BTChannelPlan/ReportRequest?' + type + '=true&tag=' + tag + '&start=' + start + '&end=' + end + '&dlfiles=' + downloadableFiles);
      //document.getElementById(div).innerHTML = '<div style="width: 450px; padding: 200px 0px 0px 300px;">This may take a minute.<p><img src=view/images/ajax-loader.gif></div>';
      
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
      {
         document.getElementById(div).innerHTML = xmlhttp.responseText;
         return;
      }
   });
 
   var count = 0;
   var finished = false;
   (function loop()
   {
      var currentContent = document.getElementById(div).innerHTML;
      setTimeout(function()
      {
         if(finished)
            return;
         
         if(++count > 200)
         {
            document.getElementById(div).innerHTML = currentContent + '<br>Report failed, timed out after 200 seconds!';
            return;
         }

         try
         { 
            loadXMLDoc('/BTChannelPlan/ReportRequest?getScheduleRptResult=true&tag=', function()
            {
               if (xmlhttp.readyState == 4 && xmlhttp.status == 200)
               {
                  var response = xmlhttp.responseText;
                  if(/exit:/.test(response))
                  {
                     if(! /exit:0/.test(response))
                        document.getElementById(div).innerHTML = response + '<br>Report process complete but errors detected!';
                     else
                        document.getElementById(div).innerHTML = response + '<br>Report process complete!<p>A copy of the report will be available \'Static Downloads.\'';
                        
                     finished = true;
                  } 
                  else
                     document.getElementById(div).innerHTML = response;
        
                  return;
               }
            });
         }
         catch(e)
         {
            document.getElementById(div).innerHTML = currentContent + '<br>An unkown error has occurred: ' + e;
            return;
         }
         
      
         
         loop();
      }, 1000);
   })();
 }
 
function dateAddtoRptSchedule()
{
   var start = document.getElementById('scheduleRptStartTime').value;
   var end = document.getElementById('scheduleRptEndTime').value;
   var dInt = document.getElementById('scheduleRptDays').value;
  
   var dateFmt = /\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d/;
   if(start === '' || ! dateFmt.test(start) || end === '' || ! end === '' || ! dateFmt.test(end))
   {
      alert('Please supply a valid in the format yyyy-mm-dd hh:mm:ss.');
      return;
   }
   
   if(dInt === '' || ! /^\d+$/.test(dInt) || parseInt(dInt) > 14 || parseInt(dInt) <= 0)
      return;
   
   var startDateLong = Date.parse(start);
   var dateAddInt = (parseInt(dInt)-1) * 60 * 60 * 24 * 1000;
   var newDate = new Date(startDateLong + dateAddInt);

   var endDateLong = Date.parse(end);
   var endDateObj = new Date(endDateLong);

   var year = newDate.getFullYear();
   var mon = (newDate.getMonth()+1) < 10 ? '0'+(newDate.getMonth()+1) : newDate.getMonth()+1;
   var day = newDate.getDate() < 10 ? '0'+newDate.getDate() : newDate.getDate();

   var hr = endDateObj.getHours() < 10 ? '0'+endDateObj.getHours() : endDateObj.getHours();
   var min = endDateObj.getMinutes() < 10 ? '0'+endDateObj.getMinutes() : endDateObj.getMinutes();
   var sec = endDateObj.getSeconds() < 10 ? '0'+endDateObj.getSeconds() : endDateObj.getSeconds();
   var dateStr = year + '-' + mon + '-' + day + ' ' + hr + ':' + min + ':' + sec;

   document.getElementById('scheduleRptEndTime').value = dateStr;
}
 //this.options[this.selectedIndex].value
 
 