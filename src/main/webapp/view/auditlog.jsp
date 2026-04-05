<%@ include file="header.jsp" %>
<script type="text/javascript">
   document.getElementById('nav-title').innerHTML = document.getElementById('nav-title').innerHTML + 'Audit Log';
</script>
<div>

   <!-- Controls row -->
   <div style="display:flex; align-items:center; gap:12px; flex-wrap:wrap; margin-bottom:8px;">

      <button id="btn-get" class="btn btn-sm btn-primary" onclick="auditToggleFetch()">Get Records</button>

      <div style="display:flex; align-items:center; gap:4px;">
         <label for="audit-date-from" style="font-size:12px; margin:0; white-space:nowrap;">From Date</label>
         <input type="date" id="audit-date-from" class="form-control form-control-sm" style="width:140px;">
      </div>

      <div style="display:flex; align-items:center; gap:4px;">
         <label for="audit-date-to" style="font-size:12px; margin:0; white-space:nowrap;">To Date</label>
         <input type="date" id="audit-date-to" class="form-control form-control-sm" style="width:140px;">
      </div>

      <div style="display:flex; align-items:center; gap:4px;">
         <label for="audit-row-limit" style="font-size:12px; margin:0; white-space:nowrap;">Row Limit</label>
         <input type="number" id="audit-row-limit" class="form-control form-control-sm" value="300" style="width:80px;">
      </div>

      <div style="display:flex; align-items:center; gap:4px;">
         <label for="audit-source" style="font-size:12px; margin:0;">Source</label>
         <select id="audit-source" class="form-select form-select-sm" style="width:120px;">
            <option value="UI">Web UI</option>
            <option value="TBA">TBA</option>
         </select>
      </div>

      <span id="audit-status" style="font-size:12px; color:#666;"></span>

   </div>

   <!-- Table area -->
   <div style="height:calc(100vh - 200px); overflow-y:auto; width:100%; border:1px solid #dee2e6; border-radius:4px;">
      <table style="width:100%; border-collapse:collapse; font-size:12px; table-layout:auto;">
         <colgroup>
            <col style="width:160px;">
            <col style="width:90px;">
            <col>
            <col>
         </colgroup>
         <thead>
            <tr style="background:#343a40; color:#fff; position:sticky; top:0; z-index:1;">
               <th style="padding:4px 8px; text-align:left; font-weight:600;">Date</th>
               <th style="padding:4px 8px; text-align:left; font-weight:600;">Type</th>
               <th style="padding:4px 8px; text-align:left; font-weight:600;">User</th>
               <th style="padding:4px 8px; text-align:left; font-weight:600;">Message</th>
            </tr>
         </thead>
         <tbody id="audit-tbody">
            <tr>
               <td colspan="4" style="padding:8px; color:#999; font-size:12px;">Press Get Records to load data.</td>
            </tr>
         </tbody>
      </table>
   </div>

</div>

<script type="text/javascript">
(function()
{
   function pad(n) { return n < 10 ? '0' + n : '' + n; }

   function toDateStr(d)
   {
      return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
   }

   function esc(val)
   {
      if(val == null) return '';
      return String(val)
         .replace(/&/g, '&amp;')
         .replace(/</g, '&lt;')
         .replace(/>/g, '&gt;');
   }

   var now = new Date();
   var twoDaysAgo = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000);
   document.getElementById('audit-date-from').value = toDateStr(twoDaysAgo);
   document.getElementById('audit-date-to').value   = toDateStr(now);

   var fetchTimer = null;
   var running    = false;

   window.auditToggleFetch = function()
   {
      if(running)
      {
         running = false;
         clearInterval(fetchTimer);
         fetchTimer = null;
         document.getElementById('btn-get').textContent = 'Get Records';
         document.getElementById('btn-get').className = 'btn btn-sm btn-primary';
         document.getElementById('audit-status').textContent = 'Stopped.';
      }
      else
      {
         running = true;
         document.getElementById('btn-get').textContent = 'Stop';
         document.getElementById('btn-get').className = 'btn btn-sm btn-danger';
         doFetch();
         fetchTimer = setInterval(doFetch, 4000);
      }
   };

   function doFetch()
   {
      var payload = {
         date_from : document.getElementById('audit-date-from').value,
         date_to   : document.getElementById('audit-date-to').value,
         row_limit : parseInt(document.getElementById('audit-row-limit').value, 10) || 300,
         source    : document.getElementById('audit-source').value
      };

      fetch('<%=request.getContextPath()%>/ws/common/audit/getlogrecords',
      {
         method  : 'POST',
         headers : { 'Content-Type': 'application/json' },
         body    : JSON.stringify(payload)
      })
      .then(function(r) { return r.json(); })
      .then(function(rows) { renderTable(rows); })
      .catch(function(err)
      {
         document.getElementById('audit-status').textContent = 'Error: ' + err.message;
      });
   }

   function renderTable(rows)
   {
      var tbody = document.getElementById('audit-tbody');
      tbody.innerHTML = '';

      if(!rows || rows.length === 0)
      {
         var empty = document.createElement('tr');
         empty.innerHTML = '<td colspan="4" style="padding:8px; color:#999;">No records found.</td>';
         tbody.appendChild(empty);
         return;
      }

      for(var i = 0; i < rows.length; i++)
      {
         var r  = rows[i];
         var tr = document.createElement('tr');

         if(i % 2 === 1)
            tr.style.background = '#f8f9fa';

         tr.innerHTML =
            '<td style="padding:2px 8px; white-space:nowrap; vertical-align:top;">'                           + esc(r.date)    + '</td>' +
            '<td style="padding:2px 8px; white-space:nowrap; vertical-align:top;">'                           + esc(r.type)    + '</td>' +
            '<td style="padding:2px 8px; white-space:nowrap; vertical-align:top;">'                           + esc(r.user)    + '</td>' +
            '<td style="padding:2px 8px; word-break:break-word; overflow-wrap:break-word; vertical-align:top;">' + esc(r.message) + '</td>';

         tbody.appendChild(tr);
      }

      document.getElementById('audit-status').textContent =
         'Updated: ' + new Date().toLocaleTimeString() + ' \u2014 ' + rows.length + ' row(s)';
   }

   window.addEventListener('beforeunload', function()
   {
      if(fetchTimer !== null)
         clearInterval(fetchTimer);
   });

})();
</script>

<%@ include file="footer.jsp" %>
