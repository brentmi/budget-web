<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "tx-upload"); %>
<%@ include file="header.jsp" %>

<style>
   .upload-section { margin-bottom: 28px; }
   .upload-section h6 {
      font-size: 12px; font-weight: 700; letter-spacing: 0.06em;
      text-transform: uppercase; color: #64748b; margin-bottom: 10px;
   }
</style>

<h5 class="mb-3">Upload / Processing</h5>

<div class="upload-section">
   <div class="card shadow-sm" style="max-width: 540px;">
      <div class="card-body p-3">
         <h6><i class="fa-solid fa-file-csv me-1"></i>Transaction Ingest Categoriser</h6>
         <div class="d-flex gap-2 align-items-center flex-wrap">
            <input type="file" id="ingest-file" accept=".csv"
                   class="form-control form-control-sm" style="font-size:12px; max-width:300px;">
            <button class="btn btn-sm btn-primary" style="font-size:12px;" onclick="processIngest()">
               <i class="fa-solid fa-play me-1"></i>Process
            </button>
         </div>
         <div id="ingest-status" style="font-size:12px; margin-top:8px; min-height:18px;"></div>
      </div>
   </div>
</div>

<script>
function processIngest()
{
   var fileInput = document.getElementById('ingest-file');
   var statusEl  = document.getElementById('ingest-status');

   if (!fileInput.files.length)
   {
      statusEl.innerHTML = '<span class="text-danger">Please select a CSV file.</span>';
      return;
   }

   var formData = new FormData();
   formData.append('file', fileInput.files[0]);

   statusEl.innerHTML = '<span class="text-muted">Processing...</span>';

   fetch('ws/upload/ingestcategorise',
   {
      method:      'POST',
      credentials: 'same-origin',
      body:        formData
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok')
         statusEl.innerHTML = buildResultHtml(res);
      else
         statusEl.innerHTML = '<span class="text-danger">' + escHtml(res.msg || 'Processing failed.') + '</span>';
   })
   .catch(function()
   {
      statusEl.innerHTML = '<span class="text-danger">Request failed.</span>';
   });
}

function buildResultHtml(res)
{
   var html = '';

   // Stats badges
   html += '<div class="mb-2">'
         + '<span class="badge bg-secondary me-1">' + res.totalRows + ' rows in file</span>'
         + '<span class="badge bg-success me-1">' + res.inserted + ' inserted</span>'
         + '<span class="badge bg-secondary me-1">' + res.excluded + ' excluded</span>';
   if (res.uncategorisedRows > 0)
      html += '<span class="badge bg-warning text-dark me-1">' + res.uncategorisedRows + ' uncategorised</span>';
   html += '<span class="text-muted ms-1" style="font-size:11px;">'
         + res.rulesLoaded + ' rules, ' + res.overridesLoaded + ' overrides'
         + '</span></div>';

   // Category breakdown table
   if (res.summary && res.summary.length > 0)
   {
      html += '<table class="table table-sm mb-2" style="font-size:11px; max-width:420px;">'
            + '<thead><tr>'
            + '<th>Category</th>'
            + '<th class="text-end">Count</th>'
            + '<th class="text-end">Total Debit</th>'
            + '</tr></thead><tbody>';
      for (var i = 0; i < res.summary.length; i++)
      {
         var s = res.summary[i];
         html += '<tr>'
               + '<td>' + escHtml(s.category) + '</td>'
               + '<td class="text-end">' + s.count + '</td>'
               + '<td class="text-end">$' + s.totalDebit.toFixed(2) + '</td>'
               + '</tr>';
      }
      html += '</tbody></table>';
   }

   // Uncategorised narratives
   if (res.uncategorised && res.uncategorised.length > 0)
   {
      html += '<div style="font-size:11px;">'
            + '<span class="text-warning fw-bold">Uncategorised narratives:</span>'
            + '<ul class="mb-0 mt-1" style="word-break:break-all;">';
      for (var j = 0; j < res.uncategorised.length; j++)
         html += '<li>' + escHtml(res.uncategorised[j].narrative) + '</li>';
      html += '</ul></div>';
   }

   return html;
}

function escHtml(s)
{
   return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
}
</script>

<%@ include file="footer.jsp" %>
