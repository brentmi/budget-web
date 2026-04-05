<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "pg-archive"); %>
<%@ include file="header.jsp" %>

<style>
   .arch-table th { background: #1e2738; color: #94a3b8; font-size: 11px; font-weight: 600;
                    letter-spacing: 0.05em; text-transform: uppercase; border: none; padding: 10px 12px; }
   .arch-table td { vertical-align: middle; padding: 8px 12px; border-color: #e9ecef; font-size: 13px; }
   .arch-table tbody tr:hover { background: #f8fafc; }
   .yr-heading { font-size: 13px; font-weight: 700; color: #1e2738; margin: 20px 0 8px; }
   .yr-heading:first-child { margin-top: 0; }
   .total-row td { font-weight: 700; background: #f1f5f9; border-top: 2px solid #cbd5e0 !important; }
   .section-title { font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: #64748b; margin-bottom: 10px; }
   .stat-mini { background: #1e2738; border-radius: 6px; padding: 12px 14px; color: #e2e8f0; }
   .stat-mini .sm-label { font-size: 10px; font-weight: 700; letter-spacing: 0.07em; text-transform: uppercase; color: #64748b; }
   .stat-mini .sm-value { font-size: 16px; font-weight: 700; margin-top: 3px; }
</style>

<div class="d-flex justify-content-between align-items-center mb-1">
   <h5 class="mb-0">Interest Archive</h5>
   <button class="btn btn-sm btn-primary" onclick="openAddModal()">
      <i class="fa-solid fa-plus"></i> Add Record
   </button>
</div>
<p class="text-muted mb-4" style="font-size:13px;">Historical interest income records grouped by financial year. 47% tax rate applied.</p>

<div class="row g-3 mb-4" id="summary-cards"></div>

<div id="year-sections">
   <div class="text-muted text-center py-4" style="font-size:13px;">Loading...</div>
</div>

<!-- ADD / EDIT MODAL -->
<div class="modal fade" id="archModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
         <div class="modal-header">
            <h6 class="modal-title" id="archModalTitle">Add Interest Record</h6>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
         </div>
         <div class="modal-body">
            <input type="hidden" id="arch-id" value="">
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Date</label>
               <input type="date" class="form-control form-control-sm" id="arch-date">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Net Amount ($)</label>
               <input type="number" class="form-control form-control-sm" id="arch-amount" min="0" step="0.01" oninput="updateArchCalc()">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Financial Year</label>
               <input type="text" class="form-control form-control-sm" id="arch-year" placeholder="e.g. 2024-2025">
               <div style="font-size:11px;color:#94a3b8;margin-top:3px;">Australian FY e.g. 2024-2025 for Jul 2024–Jun 2025.</div>
            </div>
            <div class="mb-1 p-2 rounded" style="background:#f8fafc;font-size:12px;">
               <div style="color:#64748b;">Gross (net / 0.53): <strong id="arch-calc-gross">—</strong></div>
               <div style="color:#64748b;">Tax paid (47%): <strong id="arch-calc-tax">—</strong></div>
            </div>
            <div id="arch-error" class="text-danger" style="font-size:12px;display:none;"></div>
         </div>
         <div class="modal-footer">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary btn-sm" onclick="saveRecord()">Save</button>
         </div>
      </div>
   </div>
</div>

<!-- DELETE CONFIRM -->
<div class="modal fade" id="archDeleteModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered modal-sm">
      <div class="modal-content">
         <div class="modal-body text-center py-4">
            <i class="fa-solid fa-triangle-exclamation text-warning" style="font-size:28px;"></i>
            <p class="mt-3 mb-1" style="font-size:14px;">Delete record for <strong id="arch-del-date"></strong>?</p>
         </div>
         <div class="modal-footer justify-content-center">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-danger btn-sm" onclick="confirmDelete()">Delete</button>
         </div>
      </div>
   </div>
</div>

<script>
var allRecords  = [];
var archModal, archDeleteModal;
var deleteId    = -1;

var MONTHS = ['January','February','March','April','May','June',
              'July','August','September','October','November','December'];

document.addEventListener('DOMContentLoaded', function()
{
   archModal       = new bootstrap.Modal(document.getElementById('archModal'));
   archDeleteModal = new bootstrap.Modal(document.getElementById('archDeleteModal'));
   loadRecords();
});

function loadRecords()
{
   fetch('ws/interest', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         allRecords = data;
         renderPage();
      })
      .catch(function()
      {
         document.getElementById('year-sections').innerHTML =
            '<div class="text-danger text-center py-3">Failed to load records.</div>';
      });
}

function renderPage()
{
   // Group by year_label
   var groups = {};
   allRecords.forEach(function(rec)
   {
      if (!groups[rec.year_label]) groups[rec.year_label] = [];
      groups[rec.year_label].push(rec);
   });

   var yearLabels = Object.keys(groups).sort();

   // Summary cards (one per year)
   var cardHtml = '';
   yearLabels.forEach(function(yr)
   {
      var recs    = groups[yr];
      var netSum  = recs.reduce(function(s, r) { return s + r.net_amount; }, 0);
      var gross   = netSum / 0.53;
      var taxPaid = gross - netSum;
      cardHtml +=
         '<div class="col-6 col-md-3">' +
         '<div class="stat-mini">' +
         '<div class="sm-label">' + escHtml(yr) + ' Net</div>' +
         '<div class="sm-value">' + fmt(netSum) + '</div>' +
         '<div style="font-size:11px;color:#64748b;margin-top:2px;">Tax paid ' + fmt(taxPaid) + '</div>' +
         '</div></div>';
   });
   document.getElementById('summary-cards').innerHTML = cardHtml;

   // Year sections
   var sectHtml = '';
   yearLabels.forEach(function(yr)
   {
      var recs    = groups[yr];
      var netSum  = recs.reduce(function(s, r) { return s + r.net_amount; }, 0);
      var grossSum = netSum / 0.53;
      var taxSum   = grossSum - netSum;

      sectHtml += '<div class="yr-heading"><i class="fa-solid fa-folder-open me-2" style="color:#94a3b8;"></i>' + escHtml(yr) + '</div>';
      sectHtml += '<table class="table arch-table mb-3"><thead><tr>' +
         '<th>Date</th><th>Net ($)</th><th>Gross (est.)</th><th>Tax (47%)</th><th style="width:80px;"></th>' +
         '</tr></thead><tbody>';

      recs.forEach(function(rec)
      {
         var gross = rec.net_amount / 0.53;
         var tax   = gross - rec.net_amount;
         var d     = new Date(rec.record_date + 'T00:00:00');
         var label = MONTHS[d.getMonth()] + ' ' + d.getFullYear();
         sectHtml += '<tr>' +
            '<td>' + escHtml(label) + '</td>' +
            '<td>' + fmt(rec.net_amount) + '</td>' +
            '<td>' + fmt(gross) + '</td>' +
            '<td>' + fmt(tax)   + '</td>' +
            '<td><div style="display:flex;gap:4px;">' +
               '<button class="btn btn-xs btn-outline-secondary" style="padding:2px 7px;font-size:11px;" onclick="openEditModal(' + rec.id + ')">' +
                  '<i class="fa-solid fa-pencil"></i>' +
               '</button>' +
               '<button class="btn btn-xs btn-outline-danger" style="padding:2px 7px;font-size:11px;" onclick="openDeleteModal(' + rec.id + ',\'' + escHtml(label) + '\')">' +
                  '<i class="fa-solid fa-trash"></i>' +
               '</button>' +
            '</div></td>' +
         '</tr>';
      });

      // Totals row
      sectHtml += '<tr class="total-row">' +
         '<td>Total ' + escHtml(yr) + '</td>' +
         '<td>' + fmt(netSum) + '</td>' +
         '<td>' + fmt(grossSum) + '</td>' +
         '<td>' + fmt(taxSum) + '</td>' +
         '<td></td>' +
      '</tr>';

      sectHtml += '</tbody></table>';
   });

   document.getElementById('year-sections').innerHTML = sectHtml ||
      '<div class="text-muted text-center py-4">No interest records. Click Add Record to begin.</div>';
}

// --- Modals ---

function openAddModal()
{
   document.getElementById('arch-id').value     = '';
   document.getElementById('arch-date').value   = '';
   document.getElementById('arch-amount').value = '';
   document.getElementById('arch-year').value   = '';
   document.getElementById('arch-calc-gross').textContent = '--';
   document.getElementById('arch-calc-tax').textContent   = '--';
   document.getElementById('archModalTitle').textContent  = 'Add Interest Record';
   document.getElementById('arch-error').style.display   = 'none';
   archModal.show();
}

function openEditModal(id)
{
   var rec = allRecords.find(function(r) { return r.id === id; });
   if (!rec) return;
   document.getElementById('arch-id').value     = rec.id;
   document.getElementById('arch-date').value   = rec.record_date;
   document.getElementById('arch-amount').value = rec.net_amount;
   document.getElementById('arch-year').value   = rec.year_label;
   updateArchCalc();
   document.getElementById('archModalTitle').textContent = 'Edit Interest Record';
   document.getElementById('arch-error').style.display  = 'none';
   archModal.show();
}

function updateArchCalc()
{
   var net = parseFloat(document.getElementById('arch-amount').value);
   if (!isNaN(net) && net > 0)
   {
      var gross = net / 0.53;
      document.getElementById('arch-calc-gross').textContent = fmt(gross);
      document.getElementById('arch-calc-tax').textContent   = fmt(gross - net);
   }
   else
   {
      document.getElementById('arch-calc-gross').textContent = '--';
      document.getElementById('arch-calc-tax').textContent   = '--';
   }
}

function saveRecord()
{
   var id     = document.getElementById('arch-id').value;
   var date   = document.getElementById('arch-date').value;
   var amount = parseFloat(document.getElementById('arch-amount').value);
   var year   = document.getElementById('arch-year').value.trim();
   var errEl  = document.getElementById('arch-error');

   if (!date)
   {
      errEl.textContent = 'Date is required.'; errEl.style.display = 'block'; return;
   }
   if (isNaN(amount) || amount < 0)
   {
      errEl.textContent = 'Enter a valid amount.'; errEl.style.display = 'block'; return;
   }
   if (!year || !/^\d{4}-\d{4}$/.test(year))
   {
      errEl.textContent = 'Enter a valid year label (e.g. 2024-2025).'; errEl.style.display = 'block'; return;
   }
   errEl.style.display = 'none';

   var payload = { record_date: date, net_amount: amount, year_label: year };
   var url     = id ? 'ws/interest/' + id : 'ws/interest';
   var method  = id ? 'PUT' : 'POST';

   fetch(url, {
      method: method, credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok') { archModal.hide(); loadRecords(); }
      else { errEl.textContent = res.msg || 'Save failed.'; errEl.style.display = 'block'; }
   })
   .catch(function() { errEl.textContent = 'Network error.'; errEl.style.display = 'block'; });
}

function openDeleteModal(id, label)
{
   deleteId = id;
   document.getElementById('arch-del-date').textContent = label;
   archDeleteModal.show();
}

function confirmDelete()
{
   if (deleteId < 0) return;
   fetch('ws/interest/' + deleteId, { method: 'DELETE', credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function() { archDeleteModal.hide(); loadRecords(); })
      .catch(function() { archDeleteModal.hide(); });
}

function fmt(n)
{
   return '$' + Number(n).toLocaleString('en-AU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function escHtml(str)
{
   return String(str)
      .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
      .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}
</script>

<%@ include file="footer.jsp" %>
