<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "pg-yearly"); %>
<%@ include file="header.jsp" %>

<style>
   .year-tab { cursor: pointer; padding: 8px 20px; border-radius: 4px 4px 0 0; font-size: 13px; font-weight: 600; color: #64748b; border: 1px solid transparent; border-bottom: none; }
   .year-tab.active { background: #fff; border-color: #dee2e6; color: #1e2738; }
   .year-tab:hover:not(.active) { background: #f1f5f9; color: #1e2738; }
   .year-tabs-bar { display: flex; gap: 4px; border-bottom: 1px solid #dee2e6; margin-bottom: 0; }

   .month-row td { vertical-align: middle; font-size: 13px; padding: 9px 12px; border-color: #e9ecef; }
   .month-row:hover { background: #f8fafc; }
   .month-row th { background: #1e2738; color: #94a3b8; font-size: 11px; font-weight: 600; letter-spacing: 0.05em; text-transform: uppercase; border: none; padding: 10px 12px; }

   .reconciled-badge { display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 10px; font-weight: 700; letter-spacing: 0.05em; }
   .reconciled-yes { background: #dcfce7; color: #166534; }
   .reconciled-no  { background: #f1f5f9; color: #94a3b8; }

   .stat-panel { background: #1e2738; border-radius: 6px; padding: 16px 20px; color: #e2e8f0; }
   .stat-panel .sp-label { font-size: 10px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; color: #64748b; margin-bottom: 4px; }
   .stat-panel .sp-value { font-size: 18px; font-weight: 700; }
   .stat-panel .sp-sub   { font-size: 11px; color: #64748b; margin-top: 2px; }

   .gain-pos { color: #4ade80; }
   .gain-neg { color: #f87171; }
   .on-target-pos { color: #4ade80; }
   .on-target-neg { color: #f87171; }

   #year-chart-wrapper { position: relative; height: 240px; }
   .add-year-btn { font-size: 12px; }
</style>

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
   <h5 class="mb-0">Yearly Overview</h5>
   <button class="btn btn-sm btn-outline-primary add-year-btn" id="add-year-btn" onclick="showAddYear()" style="display:none!important;">
      <i class="fa-solid fa-plus"></i> Add Next Year
   </button>
</div>

<!-- Year tabs -->
<div class="year-tabs-bar" id="year-tabs"></div>

<!-- Content card (shown once a year is selected) -->
<div class="card shadow-sm" style="border-top-left-radius:0;" id="year-content" style="display:none;">
   <div class="card-body">

      <div class="row g-3 mb-4">
         <!-- Summary stats -->
         <div class="col-lg-8">
            <div class="row g-3">
               <div class="col-sm-3">
                  <div class="stat-panel">
                     <div class="sp-label">Opening Balance</div>
                     <div class="sp-value" id="sp-opening">—</div>
                  </div>
               </div>
               <div class="col-sm-3">
                  <div class="stat-panel">
                     <div class="sp-label">Projected Close</div>
                     <div class="sp-value" id="sp-closing">—</div>
                     <div class="sp-sub">based on entries</div>
                  </div>
               </div>
               <div class="col-sm-3">
                  <div class="stat-panel">
                     <div class="sp-label">Gain / Loss</div>
                     <div class="sp-value" id="sp-gain">—</div>
                     <div class="sp-sub">vs opening</div>
                  </div>
               </div>
               <div class="col-sm-3">
                  <div class="stat-panel">
                     <div class="sp-label">Target ($<span id="sp-target-val">20,000</span>)</div>
                     <div class="sp-value" id="sp-on-target">—</div>
                     <div class="sp-sub">gain vs target</div>
                  </div>
               </div>

               <div class="col-sm-3">
                  <div class="stat-panel">
                     <div class="sp-label">Fixed Required</div>
                     <div class="sp-value" id="sp-fixed">—</div>
                     <div class="sp-sub">from Fixed Inputs</div>
                  </div>
               </div>
               <div class="col-sm-3">
                  <div class="stat-panel">
                     <div class="sp-label">Total Spent</div>
                     <div class="sp-value" id="sp-spent">—</div>
                     <div class="sp-sub">all debits</div>
                  </div>
               </div>
               <div class="col-sm-3">
                  <div class="stat-panel">
                     <div class="sp-label">Discretionary</div>
                     <div class="sp-value" id="sp-disc">—</div>
                     <div class="sp-sub">spent − fixed</div>
                  </div>
               </div>
               <div class="col-sm-3">
                  <div class="stat-panel">
                     <div class="sp-label">Daily Disc.</div>
                     <div class="sp-value" id="sp-daily">—</div>
                     <div class="sp-sub">discretionary / 365</div>
                  </div>
               </div>
            </div>
         </div>

         <!-- Mini chart -->
         <div class="col-lg-4">
            <div class="card h-100" style="border-color:#e9ecef;">
               <div class="card-body p-2">
                  <div style="font-size:11px;color:#94a3b8;font-weight:600;letter-spacing:0.05em;text-transform:uppercase;margin-bottom:6px;">Balance Trend</div>
                  <div id="year-chart-wrapper"><canvas id="yearChart"></canvas></div>
               </div>
            </div>
         </div>
      </div>

      <!-- Months table -->
      <table class="table" id="months-table">
         <thead>
            <tr>
               <th style="background:#1e2738;color:#94a3b8;font-size:11px;font-weight:600;letter-spacing:0.05em;text-transform:uppercase;border:none;padding:10px 12px;">Month</th>
               <th style="background:#1e2738;color:#94a3b8;font-size:11px;font-weight:600;letter-spacing:0.05em;text-transform:uppercase;border:none;padding:10px 12px;">Opening</th>
               <th style="background:#1e2738;color:#94a3b8;font-size:11px;font-weight:600;letter-spacing:0.05em;text-transform:uppercase;border:none;padding:10px 12px;">Debits</th>
               <th style="background:#1e2738;color:#94a3b8;font-size:11px;font-weight:600;letter-spacing:0.05em;text-transform:uppercase;border:none;padding:10px 12px;">Credits</th>
               <th style="background:#1e2738;color:#94a3b8;font-size:11px;font-weight:600;letter-spacing:0.05em;text-transform:uppercase;border:none;padding:10px 12px;">Net</th>
               <th style="background:#1e2738;color:#94a3b8;font-size:11px;font-weight:600;letter-spacing:0.05em;text-transform:uppercase;border:none;padding:10px 12px;">Closing</th>
               <th style="background:#1e2738;color:#94a3b8;font-size:11px;font-weight:600;letter-spacing:0.05em;text-transform:uppercase;border:none;padding:10px 12px;">Status</th>
               <th style="background:#1e2738;color:#94a3b8;font-size:11px;font-weight:600;letter-spacing:0.05em;text-transform:uppercase;border:none;padding:10px 12px;width:80px;"></th>
            </tr>
         </thead>
         <tbody id="months-rows">
            <tr><td colspan="8" class="text-center text-muted py-3">Select a year above.</td></tr>
         </tbody>
      </table>

   </div>
</div>

<!-- ADD YEAR MODAL -->
<div class="modal fade" id="addYearModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
         <div class="modal-header">
            <h6 class="modal-title" id="addYearTitle">Add New Financial Year</h6>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
         </div>
         <div class="modal-body">
            <p style="font-size:13px;color:#64748b;" id="add-year-desc"></p>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Opening Balance ($)</label>
               <input type="number" class="form-control form-control-sm" id="new-year-opening" step="0.01">
               <div style="font-size:11px;color:#94a3b8;margin-top:4px;">Defaults to projected closing balance of the previous year.</div>
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Target Gain ($)</label>
               <input type="number" class="form-control form-control-sm" id="new-year-target" value="20000" step="0.01">
            </div>
            <div id="add-year-error" class="text-danger" style="font-size:12px;display:none;"></div>
         </div>
         <div class="modal-footer">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary btn-sm" onclick="confirmAddYear()">Create Year</button>
         </div>
      </div>
   </div>
</div>

<script>
var years        = [];
var allEntries   = {};   // month_id -> [entries]
var allMonths    = {};   // year_id  -> [months]
var fixedYearly  = 0;
var activeYearId = -1;
var yearChart    = null;
var addYearModal;

var MONTH_NAMES = ['July','August','September','October','November','December',
                   'January','February','March','April','May','June'];

document.addEventListener('DOMContentLoaded', function()
{
   addYearModal = new bootstrap.Modal(document.getElementById('addYearModal'));
   loadFixed();
   loadYears();
});

function loadFixed()
{
   fetch('ws/fixed-input', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(items)
      {
         fixedYearly = items
            .filter(function(i) { return i.is_active; })
            .reduce(function(sum, i)
            {
               var mult = i.frequency === 'Monthly' ? 12 : i.frequency === 'Quarterly' ? 4 : i.frequency === 'Weekly' ? 52 : 1;
               return sum + i.item_cost * mult;
            }, 0);
      });
}

function loadPrevYearEntries(prevYearId)
{
   if (allMonths[prevYearId]) return Promise.resolve();

   return fetch('ws/months?year_id=' + prevYearId, { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         allMonths[prevYearId] = data;
         var fetches = data.map(function(m)
         {
            return fetch('ws/entries?month_id=' + m.id, { credentials: 'same-origin' })
               .then(function(r) { return r.json(); })
               .then(function(entries) { allEntries[m.id] = entries; });
         });
         return Promise.all(fetches);
      });
}

function calcPrevYearClose(year)
{
   var idx      = years.findIndex(function(y) { return y.id === year.id; });
   var prevYear = idx > 0 ? years[idx - 1] : null;
   if (!prevYear || !allMonths[prevYear.id]) return year.opening_balance;

   var balance = calcPrevYearClose(prevYear);
   allMonths[prevYear.id].forEach(function(m)
   {
      var ents = allEntries[m.id] || [];
      var d    = ents.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      var c    = ents.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      balance  = balance - d + c;
   });
   return balance;
}

function loadYears()
{
   fetch('ws/years', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         years = data;
         renderTabs();
         updateAddYearButton();
         if (years.length > 0)
            selectYear(years[0].id);
      });
}

function renderTabs()
{
   var bar = document.getElementById('year-tabs');
   bar.innerHTML = '';
   years.forEach(function(y)
   {
      var tab = document.createElement('div');
      tab.className = 'year-tab' + (y.id === activeYearId ? ' active' : '');
      tab.textContent = y.year_label;
      tab.onclick = function() { selectYear(y.id); };
      bar.appendChild(tab);
   });
}

function updateAddYearButton()
{
   // Show "Add Next Year" only if fewer than 2 years exist or the latest year
   // is the second-to-last expected year. Simple rule: always show it.
   var btn = document.getElementById('add-year-btn');
   btn.style.removeProperty('display');
}

function selectYear(yearId)
{
   activeYearId = yearId;
   renderTabs();
   document.getElementById('year-content').style.display = '';

   var yearIdx  = years.findIndex(function(y) { return y.id === yearId; });
   var prevYear = yearIdx > 0 ? years[yearIdx - 1] : null;

   if (allMonths[yearId])
   {
      var prevLoad = prevYear ? loadPrevYearEntries(prevYear.id) : Promise.resolve();
      prevLoad.then(function() { renderYear(yearId); });
      return;
   }

   fetch('ws/months?year_id=' + yearId, { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(months)
      {
         allMonths[yearId] = months;
         // Load entries for all months in parallel
         var fetches = months.map(function(m)
         {
            return fetch('ws/entries?month_id=' + m.id, { credentials: 'same-origin' })
               .then(function(r) { return r.json(); })
               .then(function(entries) { allEntries[m.id] = entries; });
         });
         var prevFetch = prevYear ? loadPrevYearEntries(prevYear.id) : Promise.resolve();
         return Promise.all(fetches.concat([prevFetch]));
      })
      .then(function() { renderYear(yearId); });
}

function renderYear(yearId)
{
   var year   = years.find(function(y) { return y.id === yearId; });
   var months = allMonths[yearId] || [];

   // Calculate running balances
   var opening   = calcPrevYearClose(year);
   var balance   = opening;
   var totalDebit  = 0;
   var totalCredit = 0;
   var monthData   = [];

   months.forEach(function(m)
   {
      var entries  = allEntries[m.id] || [];
      var debits   = entries.filter(function(e) { return e.entry_type === 'DEBIT'; })
                            .reduce(function(s, e) { return s + e.amount; }, 0);
      var credits  = entries.filter(function(e) { return e.entry_type === 'CREDIT'; })
                            .reduce(function(s, e) { return s + e.amount; }, 0);
      var open     = balance;
      balance      = open - debits + credits;
      totalDebit  += debits;
      totalCredit += credits;

      monthData.push({ month: m, open: open, debits: debits, credits: credits, close: balance });
   });

   var gain   = balance - opening;
   var disc   = totalDebit - fixedYearly;
   var onTgt  = gain - year.target_gain;

   // Stats
   document.getElementById('sp-opening').textContent    = fmt(opening);
   document.getElementById('sp-closing').textContent    = fmt(balance);
   document.getElementById('sp-target-val').textContent = fmtNum(year.target_gain);

   var gainEl = document.getElementById('sp-gain');
   gainEl.textContent = (gain >= 0 ? '+' : '') + fmt(gain);
   gainEl.className = 'sp-value ' + (gain >= 0 ? 'gain-pos' : 'gain-neg');

   var tgtEl = document.getElementById('sp-on-target');
   tgtEl.textContent = (onTgt >= 0 ? '+' : '') + fmt(onTgt);
   tgtEl.className = 'sp-value ' + (onTgt >= 0 ? 'on-target-pos' : 'on-target-neg');

   document.getElementById('sp-fixed').textContent = fmt(fixedYearly);
   document.getElementById('sp-spent').textContent = fmt(totalDebit);

   var discEl = document.getElementById('sp-disc');
   discEl.textContent = fmt(Math.max(0, disc));

   document.getElementById('sp-daily').textContent = fmt(Math.max(0, disc) / 365);

   // Months table
   var html = '';
   monthData.forEach(function(md, idx)
   {
      var net    = md.credits - md.debits;
      var hasData = md.debits > 0 || md.credits > 0;
      html += '<tr class="month-row">' +
         '<td><strong>' + MONTH_NAMES[idx] + '</strong></td>' +
         '<td>' + fmt(md.open) + '</td>' +
         '<td>' + (hasData ? '<span class="text-danger">' + fmt(md.debits) + '</span>' : '<span class="text-muted">—</span>') + '</td>' +
         '<td>' + (hasData ? '<span class="text-success">' + fmt(md.credits) + '</span>' : '<span class="text-muted">—</span>') + '</td>' +
         '<td>' + (hasData ? '<span class="' + (net >= 0 ? 'text-success' : 'text-danger') + '">' + (net >= 0 ? '+' : '') + fmt(net) + '</span>' : '<span class="text-muted">—</span>') + '</td>' +
         '<td><strong>' + fmt(md.close) + '</strong></td>' +
         '<td><span class="reconciled-badge ' + (md.month.is_reconciled ? 'reconciled-yes' : 'reconciled-no') + '">' +
            (md.month.is_reconciled ? 'Reconciled' : 'Open') +
         '</span></td>' +
         '<td>' +
            '<a href="/budgetapi?rq=pg-monthly&year_id=' + yearId + '&month=' + (idx + 1) + '" class="btn btn-xs btn-outline-secondary" style="padding:2px 7px;font-size:11px;">' +
               '<i class="fa-solid fa-pencil"></i> Edit' +
            '</a>' +
         '</td>' +
      '</tr>';
   });
   document.getElementById('months-rows').innerHTML = html || '<tr><td colspan="8" class="text-muted text-center py-3">No month data.</td></tr>';

   renderYearChart(monthData, year);
}

function renderYearChart(monthData, year)
{
   var labels = MONTH_NAMES;
   var values = monthData.map(function(md) { return md.close; });
   // prepend opening as first point
   var chartLabels = ['Start'].concat(labels);
   var chartValues = [year.opening_balance].concat(values);

   if (yearChart) { yearChart.destroy(); yearChart = null; }
   var ctx = document.getElementById('yearChart').getContext('2d');
   yearChart = new Chart(ctx, {
      type: 'line',
      data: {
         labels: chartLabels,
         datasets: [{
            data: chartValues,
            borderColor: '#3b82f6',
            backgroundColor: 'rgba(59,130,246,0.08)',
            borderWidth: 2,
            pointRadius: 3,
            pointHoverRadius: 5,
            tension: 0.2,
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
                  label: function(c) { return fmt(c.parsed.y); }
               }
            }
         },
         scales: {
            x: { ticks: { font: { size: 10 }, maxRotation: 45 }, grid: { display: false } },
            y: {
               ticks: { font: { size: 10 }, callback: function(v) { return '$' + (v/1000).toFixed(0) + 'k'; } },
               grid: { color: 'rgba(0,0,0,0.05)' }
            }
         }
      }
   });
}

// --- Add Year ---

function showAddYear()
{
   // Determine what the next year would be
   var lastYear = years.length > 0 ? years[years.length - 1] : null;
   if (!lastYear) return;

   var lastLabel  = lastYear.year_label;             // e.g. '2026-2027'
   var parts      = lastLabel.split('-');
   var nextStart  = parseInt(parts[0]) + 1;
   var nextEnd    = parseInt(parts[1]) + 1;
   var nextLabel  = nextStart + '-' + nextEnd;
   var nextSDate  = nextStart + '-07-01';
   var nextEDate  = nextEnd   + '-06-30';

   document.getElementById('addYearTitle').textContent  = 'Add Year: ' + nextLabel;
   document.getElementById('add-year-desc').textContent = 'Creates ' + nextLabel + ' (' + nextSDate + ' to ' + nextEDate + ') with 12 blank months.';
   document.getElementById('new-year-opening').value    = '';
   document.getElementById('new-year-target').value     = 20000;
   document.getElementById('add-year-error').style.display = 'none';

   document.getElementById('addYearModal').dataset.nextLabel = nextLabel;
   document.getElementById('addYearModal').dataset.nextSDate = nextSDate;
   document.getElementById('addYearModal').dataset.nextEDate = nextEDate;

   // Ensure lastYear's entries are loaded before computing the projected close
   loadPrevYearEntries(lastYear.id).then(function()
   {
      var months    = allMonths[lastYear.id] || [];
      var projClose = calcPrevYearClose(lastYear);
      months.forEach(function(m)
      {
         var entries = allEntries[m.id] || [];
         var debits  = entries.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
         var credits = entries.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
         projClose   = projClose - debits + credits;
      });
      document.getElementById('new-year-opening').value = Math.round(projClose * 100) / 100;
   });

   addYearModal.show();
}

function confirmAddYear()
{
   var modal   = document.getElementById('addYearModal');
   var opening = parseFloat(document.getElementById('new-year-opening').value);
   var target  = parseFloat(document.getElementById('new-year-target').value);
   var errEl   = document.getElementById('add-year-error');

   if (isNaN(opening))
   {
      errEl.textContent = 'Enter a valid opening balance.';
      errEl.style.display = 'block';
      return;
   }
   errEl.style.display = 'none';

   var payload = {
      year_label:      modal.dataset.nextLabel,
      start_date:      modal.dataset.nextSDate,
      end_date:        modal.dataset.nextEDate,
      opening_balance: opening,
      target_gain:     isNaN(target) ? 20000 : target
   };

   fetch('ws/years', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok')
      {
         addYearModal.hide();
         // Clear cache and reload
         allMonths  = {};
         allEntries = {};
         loadYears();
      }
      else
      {
         errEl.textContent = res.msg || 'Failed to create year.';
         errEl.style.display = 'block';
      }
   })
   .catch(function()
   {
      errEl.textContent = 'Network error.';
      errEl.style.display = 'block';
   });
}

function fmt(n)
{
   return '$' + Number(n).toLocaleString('en-AU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtNum(n)
{
   return Number(n).toLocaleString('en-AU', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
}
</script>

<%@ include file="footer.jsp" %>
