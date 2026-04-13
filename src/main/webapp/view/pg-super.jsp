<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "pg-super"); %>
<%@ include file="header.jsp" %>

<style>
   .super-table th {
      background: #1e2738;
      color: #94a3b8;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      border: none;
      padding: 10px 12px;
   }
   .super-table td {
      vertical-align: middle;
      padding: 8px 12px;
      border-color: #e9ecef;
      font-size: 13px;
   }
   .super-table tbody tr:hover { background: #f8fafc; }
   .stat-card {
      background: #1e2738;
      color: #e2e8f0;
      border-radius: 6px;
      padding: 16px 18px;
   }
   .stat-label { font-size: 10px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; color: #64748b; }
   .stat-value { font-size: 20px; font-weight: 700; margin-top: 4px; }
   .stat-sub   { font-size: 11px; color: #64748b; margin-top: 2px; }
   .gain-pos   { color: #4ade80; }
   .gain-neg   { color: #f87171; }
   #chart-wrapper { position: relative; height: 300px; }
</style>

<h5 class="mb-1">Superannuation</h5>
<p class="text-muted mb-4" style="font-size:13px;">HESTA balance history. Add the latest balance at end of each month.</p>

<!-- Stats row -->
<div class="row g-3 mb-4">
   <div class="col-sm-3">
      <div class="stat-card">
         <div class="stat-label">Latest Balance</div>
         <div class="stat-value" id="stat-latest">—</div>
         <div class="stat-sub" id="stat-latest-date">—</div>
      </div>
   </div>
   <div class="col-sm-3">
      <div class="stat-card">
         <div class="stat-label">1 Year Change</div>
         <div class="stat-value" id="stat-1yr">—</div>
         <div class="stat-sub">vs 12 months ago</div>
      </div>
   </div>
   <div class="col-sm-3">
      <div class="stat-card">
         <div class="stat-label">YTD (Jul 1)</div>
         <div class="stat-value" id="stat-ytd">—</div>
         <div class="stat-sub">since start of FY</div>
      </div>
   </div>
   <div class="col-sm-3">
      <div class="stat-card">
         <div class="stat-label">All-time start</div>
         <div class="stat-value" id="stat-start">—</div>
         <div class="stat-sub" id="stat-start-date">—</div>
      </div>
   </div>
</div>

<!-- Chart -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
         <p class="mb-0" style="font-size:13px;font-weight:600;">Balance Over Time</p>
         <div class="d-flex gap-2 align-items-center flex-wrap">
            <label style="font-size:12px;color:#64748b;margin:0;">From:</label>
            <input type="date" class="form-control form-control-sm" id="chart-from" style="width:140px;" onchange="renderChart()">
            <label style="font-size:12px;color:#64748b;margin:0;">To:</label>
            <input type="date" class="form-control form-control-sm" id="chart-to" style="width:140px;" onchange="renderChart()">
            <button class="btn btn-sm btn-outline-secondary" onclick="setChartRange('all')">All</button>
            <button class="btn btn-sm btn-outline-secondary" onclick="setChartRange('2y')">2Y</button>
            <button class="btn btn-sm btn-outline-secondary" onclick="setChartRange('1y')">1Y</button>
         </div>
      </div>
      <div id="chart-wrapper"><canvas id="superChart"></canvas></div>
   </div>
</div>

<!-- Balance table + Add button -->
<div class="card shadow-sm">
   <div class="card-body">
      <div class="d-flex justify-content-between align-items-center mb-3">
         <p class="mb-0" style="font-size:13px;font-weight:600;">Balance History</p>
         <button class="btn btn-sm btn-primary" onclick="openAddModal()">
            <i class="fa-solid fa-plus"></i> Add Balance
         </button>
      </div>
      <table class="table super-table">
         <thead>
            <tr><th>Date</th><th>Balance</th><th>Change</th><th>Notes</th><th style="width:80px"></th></tr>
         </thead>
         <tbody id="super-rows">
            <tr><td colspan="5" class="text-center text-muted py-3">Loading...</td></tr>
         </tbody>
      </table>
   </div>
</div>

<!-- ADD / EDIT MODAL -->
<div class="modal fade" id="superModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
         <div class="modal-header">
            <h6 class="modal-title" id="superModalTitle">Add Balance</h6>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
         </div>
         <div class="modal-body">
            <input type="hidden" id="sup-id" value="">
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Date</label>
               <input type="date" class="form-control form-control-sm" id="sup-date">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Balance ($)</label>
               <input type="number" class="form-control form-control-sm" id="sup-amount" min="0" step="0.01">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Notes (optional)</label>
               <input type="text" class="form-control form-control-sm" id="sup-notes">
            </div>
            <div id="sup-error" class="text-danger" style="font-size:12px;display:none;"></div>
         </div>
         <div class="modal-footer">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary btn-sm" onclick="saveBalance()">Save</button>
         </div>
      </div>
   </div>
</div>

<!-- DELETE CONFIRM -->
<div class="modal fade" id="supDeleteModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered modal-sm">
      <div class="modal-content">
         <div class="modal-body text-center py-4">
            <i class="fa-solid fa-triangle-exclamation text-warning" style="font-size:28px;"></i>
            <p class="mt-3 mb-1" style="font-size:14px;">Delete entry for <strong id="sup-del-date"></strong>?</p>
         </div>
         <div class="modal-footer justify-content-center">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-danger btn-sm" onclick="confirmDelete()">Delete</button>
         </div>
      </div>
   </div>
</div>

<script>
var superData    = [];
var deleteId     = -1;
var superModal, supDeleteModal;
var chartInst    = null;

var MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

document.addEventListener('DOMContentLoaded', function()
{
   superModal    = new bootstrap.Modal(document.getElementById('superModal'));
   supDeleteModal = new bootstrap.Modal(document.getElementById('supDeleteModal'));
   loadData();
});

function loadData()
{
   fetch('ws/super', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         superData = data;
         renderStats();
         renderTable();
         initChartRange();
         renderChart();
      })
      .catch(function()
      {
         document.getElementById('super-rows').innerHTML =
            '<tr><td colspan="5" class="text-danger text-center">Failed to load.</td></tr>';
      });
}

function renderStats()
{
   if (superData.length === 0) return;
   var latest = superData[superData.length - 1];
   document.getElementById('stat-latest').textContent      = fmt(latest.balance_amount);
   document.getElementById('stat-latest-date').textContent = fmtDate(latest.balance_date);

   var start = superData[0];
   document.getElementById('stat-start').textContent      = fmt(start.balance_amount);
   document.getElementById('stat-start-date').textContent = fmtDate(start.balance_date);

   // 1-year change: find entry ~12 months ago
   var oneYearAgo = new Date(latest.balance_date);
   oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
   var closest = findClosest(oneYearAgo);
   if (closest)
   {
      var change1y  = latest.balance_amount - closest.balance_amount;
      var el1y      = document.getElementById('stat-1yr');
      el1y.textContent = (change1y >= 0 ? '+' : '') + fmt(change1y);
      el1y.className = 'stat-value ' + (change1y >= 0 ? 'gain-pos' : 'gain-neg');
   }

   // YTD: find entry closest to Jul 1 of current FY
   var now      = new Date(latest.balance_date);
   var fyStart  = new Date(now.getMonth() >= 6 ? now.getFullYear() : now.getFullYear() - 1, 6, 1);
   var fyEntry  = findClosest(fyStart);
   if (fyEntry)
   {
      var ytd   = latest.balance_amount - fyEntry.balance_amount;
      var elYtd = document.getElementById('stat-ytd');
      elYtd.textContent = (ytd >= 0 ? '+' : '') + fmt(ytd);
      elYtd.className = 'stat-value ' + (ytd >= 0 ? 'gain-pos' : 'gain-neg');
   }
}

function findClosest(targetDate)
{
   if (superData.length === 0) return null;
   var target = targetDate.getTime();
   var best   = superData[0];
   var bestDiff = Math.abs(new Date(best.balance_date).getTime() - target);
   superData.forEach(function(d)
   {
      var diff = Math.abs(new Date(d.balance_date).getTime() - target);
      if (diff < bestDiff) { bestDiff = diff; best = d; }
   });
   return best;
}

function renderTable()
{
   var tbody = document.getElementById('super-rows');
   if (superData.length === 0)
   {
      tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted py-3">No data. Add the first balance entry.</td></tr>';
      return;
   }
   // Render newest first
   var html = '';
   for (var i = superData.length - 1; i >= 0; i--)
   {
      var rec    = superData[i];
      var prev   = i > 0 ? superData[i - 1] : null;
      var change = prev ? (rec.balance_amount - prev.balance_amount) : null;
      var changeTxt = change === null ? '—' :
         '<span class="' + (change >= 0 ? 'text-success' : 'text-danger') + '">' +
         (change >= 0 ? '+' : '') + fmt(change) + '</span>';
      html += '<tr>' +
         '<td>' + escHtml(fmtDate(rec.balance_date)) + '</td>' +
         '<td><strong>' + fmt(rec.balance_amount) + '</strong></td>' +
         '<td>' + changeTxt + '</td>' +
         '<td style="font-size:12px;color:#94a3b8;">' + escHtml(rec.notes || '') + '</td>' +
         '<td><div style="display:flex;gap:4px;">' +
            '<button class="btn btn-xs btn-outline-secondary" style="padding:2px 7px;font-size:11px;" onclick="openEditModal(' + rec.id + ')">' +
               '<i class="fa-solid fa-pencil"></i>' +
            '</button>' +
            '<button class="btn btn-xs btn-outline-danger" style="padding:2px 7px;font-size:11px;" onclick="openDeleteModal(' + rec.id + ',\'' + escHtml(rec.balance_date) + '\')">' +
               '<i class="fa-solid fa-trash"></i>' +
            '</button>' +
         '</div></td>' +
      '</tr>';
   }
   tbody.innerHTML = html;
}

function initChartRange()
{
   if (superData.length === 0) return;
   var first = superData[0].balance_date;
   var last  = superData[superData.length - 1].balance_date;
   document.getElementById('chart-from').value = first;
   document.getElementById('chart-to').value   = last;
}

function setChartRange(range)
{
   if (superData.length === 0) return;
   var last = new Date(superData[superData.length - 1].balance_date);
   var from = new Date(last);
   if (range === '1y') from.setFullYear(from.getFullYear() - 1);
   else if (range === '2y') from.setFullYear(from.getFullYear() - 2);
   else from = new Date(superData[0].balance_date);

   document.getElementById('chart-from').value = from.toISOString().split('T')[0];
   document.getElementById('chart-to').value   = last.toISOString().split('T')[0];
   renderChart();
}

function renderChart()
{
   var from = document.getElementById('chart-from').value;
   var to   = document.getElementById('chart-to').value;

   var filtered = superData.filter(function(d)
   {
      return (!from || d.balance_date >= from) && (!to || d.balance_date <= to);
   });

   var labels = filtered.map(function(d)
   {
      var dt = new Date(d.balance_date);
      return MONTHS[dt.getMonth()] + ' ' + dt.getFullYear();
   });
   var values = filtered.map(function(d) { return d.balance_amount; });

   if (chartInst) { chartInst.destroy(); chartInst = null; }

   var ctx = document.getElementById('superChart').getContext('2d');
   chartInst = new Chart(ctx, {
      type: 'line',
      data: {
         labels: labels,
         datasets: [{
            label: 'HESTA Balance',
            data: values,
            borderColor: '#3b82f6',
            backgroundColor: 'rgba(59,130,246,0.08)',
            borderWidth: 2,
            pointRadius: filtered.length > 60 ? 0 : 3,
            pointHoverRadius: 5,
            tension: 0.3,
            fill: true
         }]
      },
      options: {
         responsive: true,
         maintainAspectRatio: false,
         plugins: {
            legend: { display: false },
            tooltip: {
               callbacks: {
                  label: function(ctx)
                  {
                     return fmt(ctx.parsed.y);
                  }
               }
            }
         },
         scales: {
            x: {
               ticks: { maxTicksLimit: 12, font: { size: 11 } },
               grid: { display: false }
            },
            y: {
               ticks: {
                  font: { size: 11 },
                  callback: function(v) { return '$' + (v/1000).toFixed(0) + 'k'; }
               },
               grid: { color: 'rgba(0,0,0,0.05)' }
            }
         }
      }
   });
}

// --- Modals ---

function openAddModal()
{
   document.getElementById('sup-id').value     = '';
   document.getElementById('sup-date').value   = '';
   document.getElementById('sup-amount').value = '';
   document.getElementById('sup-notes').value  = '';
   document.getElementById('superModalTitle').textContent = 'Add Balance';
   document.getElementById('sup-error').style.display = 'none';
   superModal.show();
}

function openEditModal(id)
{
   var rec = superData.find(function(d) { return d.id === id; });
   if (!rec) return;
   document.getElementById('sup-id').value     = rec.id;
   document.getElementById('sup-date').value   = rec.balance_date;
   document.getElementById('sup-amount').value = rec.balance_amount;
   document.getElementById('sup-notes').value  = rec.notes || '';
   document.getElementById('superModalTitle').textContent = 'Edit Balance';
   document.getElementById('sup-error').style.display = 'none';
   superModal.show();
}

function saveBalance()
{
   var id     = document.getElementById('sup-id').value;
   var date   = document.getElementById('sup-date').value;
   var amount = parseFloat(document.getElementById('sup-amount').value);
   var notes  = document.getElementById('sup-notes').value.trim();
   var errEl  = document.getElementById('sup-error');

   if (!date)
   {
      errEl.textContent = 'Date is required.';
      errEl.style.display = 'block';
      return;
   }
   if (isNaN(amount) || amount <= 0)
   {
      errEl.textContent = 'Enter a valid balance amount.';
      errEl.style.display = 'block';
      return;
   }
   errEl.style.display = 'none';

   var payload = { balance_date: date, balance_amount: amount, notes: notes };
   var url    = id ? 'ws/super/' + id : 'ws/super';
   var method = id ? 'PUT' : 'POST';

   fetch(url, {
      method: method,
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok') { superModal.hide(); loadData(); }
      else { errEl.textContent = res.msg || 'Save failed.'; errEl.style.display = 'block'; }
   })
   .catch(function() { errEl.textContent = 'Network error.'; errEl.style.display = 'block'; });
}

function openDeleteModal(id, date)
{
   deleteId = id;
   document.getElementById('sup-del-date').textContent = fmtDate(date);
   supDeleteModal.show();
}

function confirmDelete()
{
   if (deleteId < 0) return;
   fetch('ws/super/' + deleteId, { method: 'DELETE', credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function() { supDeleteModal.hide(); loadData(); })
      .catch(function() { supDeleteModal.hide(); });
}

// --- Utilities ---

function fmt(n)
{
   return '$' + Number(n).toLocaleString('en-AU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtDate(str)
{
   var d = new Date(str + 'T00:00:00');
   return d.getDate() + ' ' + ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.getMonth()] + ' ' + d.getFullYear();
}

function escHtml(str)
{
   return String(str)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}
</script>

<%@ include file="footer.jsp" %>
