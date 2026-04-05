function validateJdbcUrl(url)
{
   var msg = 'xxxx Bad url: jdbc:mysql://host:port/db?user=usr&password=pass&useSSL=false@select col from table where x = \'y\'';
   // jdbc:mysql://localhost:3306/test?user=root&password=copsaretops@f0101_faults,cdsn
   
   if(url.startsWith("jdbc:mysql:"))
   {   
      var str = url.split("?");
      if(str.length !== 2)
         throw 'Param split on ? failed, len='+str.length;

      var params = str[1].split("@");
      if(params.length !== 2)
         throw 'Param split on @ failed, len='+params.length;
      
      return;
   }
   else if(url.startsWith("jdbc:cdsn:") || url.startsWith("jdbc:soak:"))
   {
      // jdbc:cdsn:batch3:1071:swdl_iq5_ipsat_dist_6_r17_v1.2.3.4
      var str = url.split(":");
      if(str.length !== 5)
         throw 'BAd split on : failed, len='+str.length + " should be 5!";
      
      return;
   }
   
   throw 'Unable to figure what to do with '+url;
   
//   var tbleData = params[1].split(",");
//   if(tbleData.length !== 2)
//      throw msg;
}

function setDatetime(date, time) 
{
   var st = time.split(":");
   
   if(isNaN(parseInt(st[0])) || isNaN(parseInt(st[1])) || isNaN(parseInt(st[2])))
      throw "Bad time values isNaN.";
   
   if(st[0] < 0 || st[0] > 24)
      throw "Bad time hour value.";
   
   if(st[1] < 0 || st[1] > 59)
      throw "Bad time minute value.";
   
   if(st[2] < 0 || st[2] > 59)
      throw "Bad time second value.";
   
   date.setHours(st[0]);
   date.setMinutes(st[1]);
   date.setSeconds(st[2]);
} 

function compareDatetimes(start, end)
{
   if(end !== null && end <= start)
      throw "The 'End Datetime' must be greater than 'Start Datetime'";
  
   var now = new Date();
   if(start <= now)
      throw "'Start Datetime' must be greater than current time!";
}

function validateDateimeInputs(startdate, starttime, enddate, endtime)
{
   if((startdate !== null && startdate !== undefined) && (enddate !== null && enddate !== undefined))
   {    
      // Validate the start / end dates and times
      // The backend still expects hh:mm:ss at ths stage so we do still POST both even though the date object is fully set. 
      try
      {
         setDatetime(startdate, starttime);
         setDatetime(enddate, endtime);
         compareDatetimes(startdate, enddate);
      }
      catch(err)
      {
         throw err;
      }
   }
   else if(startdate !== null && startdate !== undefined) // Startdate set, frequency once only or No End Date
   {
      try
      {
         setDatetime(startdate, starttime);
         compareDatetimes(startdate, null);
      }
      catch(err)
      {
         throw err;
      }
   }
   else
   {
      // Is Immediate
   }
}

var instanceCount = 0;
function validatecron(e)
{
   // This hack for the double firing of blur event (window and element) 
   // is shit but seems to work. Anyone know a better way please fix.
   if(instanceCount > 0)
   {
      instanceCount = 0;
      return;
   }
 
   instanceCount++;
   if(e.value.length > 1)
   {
     $.get("/BTChannelPlan/ws/command-scheduler/validatecron",
      {
         expression: e.value
      },
      function(data, status)
      {
         if(data.cron === 'failed')
         {
            alert('Cron Expresion is not valid:\n' + data.error);
            e.focus();
            
            return;
         }
         instanceCount = 0;
      });
   }   
}


