<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "tx-explore"); %>
<%@ include file="header.jsp" %>

<style>
   .yr-tab { cursor: pointer; padding: 5px 14px; border-radius: 4px; font-size: 12px; font-weight: 600;
              border: 1px solid #dee2e6; background: #fff; color: #64748b; }
   .yr-tab.active { background: #1e2738; color: #e2e8f0; border-color: #1e2738; }
   .section-title { font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: #64748b; margin-bottom: 10px; }
   .chart-wrap { position: relative; height: 300px; }
   #exp-tx-table th, #exp-tx-table td { font-size: 12px; }
   .conf-high { background: #dcfce7; color: #166534; font-size: 10px; font-weight: 700; padding: 1px 5px; border-radius: 3px; }
   .conf-med  { background: #fef9c3; color: #854d0e; font-size: 10px; font-weight: 700; padding: 1px 5px; border-radius: 3px; }
   .conf-low  { background: #fee2e2; color: #991b1b; font-size: 10px; font-weight: 700; padding: 1px 5px; border-radius: 3px; }
</style>

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
   <h5 class="mb-0">Transaction Explorer</h5>
   <a href="/budgetapi?rq=tx-dashboard" class="text-muted" style="font-size:12px;">
      <i class="fa-solid fa-arrow-left me-1"></i>Back to Dashboard
   </a>
</div>

<!-- ── Year tabs ─────────────────────────────────────────────────────── -->
<div class="d-flex gap-2 align-items-center mb-3 flex-wrap">
   <span style="font-size:12px;color:#64748b;font-weight:600;">Year:</span>
   <div id="exp-year-tabs" class="d-flex gap-2 flex-wrap">
      <span style="font-size:12px;color:#94a3b8;">Loading...</span>
   </div>
</div>

<!-- ── Filters ────────────────────────────────────────────────────────── -->
<div class="d-flex gap-3 align-items-center mb-4 flex-wrap">
   <div class="d-flex align-items-center gap-2">
      <label style="font-size:12px;color:#64748b;font-weight:600;margin:0;">Month:</label>
      <select id="exp-month" class="form-select form-select-sm" style="font-size:12px;width:130px;" onchange="onFilterChange()">
         <option value="0">All months</option>
         <option value="1">January</option>
         <option value="2">February</option>
         <option value="3">March</option>
         <option value="4">April</option>
         <option value="5">May</option>
         <option value="6">June</option>
         <option value="7">July</option>
         <option value="8">August</option>
         <option value="9">September</option>
         <option value="10">October</option>
         <option value="11">November</option>
         <option value="12">December</option>
      </select>
   </div>
   <div class="d-flex align-items-center gap-2">
      <label style="font-size:12px;color:#64748b;font-weight:600;margin:0;">Category:</label>
      <select id="exp-category" class="form-select form-select-sm" style="font-size:12px;width:190px;" onchange="onFilterChange()">
         <option value="">All categories</option>
      </select>
   </div>
   <span id="exp-tx-count" style="font-size:12px;color:#94a3b8;"></span>
</div>

<!-- ── Stacked bar chart ──────────────────────────────────────────────── -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Monthly Spend by Category — <span id="exp-chart-year">...</span></div>
      <div class="chart-wrap"><canvas id="expStackedChart"></canvas></div>
   </div>
</div>

<!-- ── Transactions DataTable ────────────────────────────────────────── -->
<div class="card shadow-sm">
   <div class="card-body">
      <div class="section-title">Transactions</div>
      <table id="exp-tx-table" class="table table-sm table-hover" style="width:100%;">
         <thead>
            <tr>
               <th>Date</th>
               <th>Narrative</th>
               <th class="text-end">Debit</th>
               <th class="text-end">Credit</th>
               <th>Category</th>
               <th>Conf.</th>
            </tr>
         </thead>
         <tbody id="exp-tx-tbody"></tbody>
      </table>
   </div>
</div>

<script>
var MONTH_LABELS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
var PALETTE = [
   '#3b82f6','#ef4444','#10b981','#f59e0b','#8b5cf6',
   '#06b6d4','#f97316','#ec4899','#14b8a6','#84cc16',
   '#6366f1','#e11d48','#0ea5e9','#22c55e','#eab308'
];

var expChart     = null;
var selectedYear = null;
var mbcData      = []; // monthly-by-category data for the selected year

document.addEventListener('DOMContentLoaded', function()
{
   fetch('ws/tx-data/years', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(years)
      {
         if (!years.length)
         {
            document.getElementById('exp-year-tabs').innerHTML =
               '<span style="font-size:12px;color:#94a3b8;">No transaction data found.</span>';
            return;
         }
         renderYearTabs(years);
         selectYear(years[0]);
      })
      .catch(function(e) { console.error('tx-explore init failed', e); });
});

function renderYearTabs(years)
{
   var html = '';
   years.forEach(function(yr)
   {
      html += '<button class="yr-tab" id="yr-tab-' + yr + '" onclick="selectYear(' + yr + ')">' + yr + '</button>';
   });
   document.getElementById('exp-year-tabs').innerHTML = html;
}

function selectYear(year)
{
   selectedYear = year;
   document.getElementById('exp-chart-year').textContent = year;

   document.querySelectorAll('.yr-tab').forEach(function(b) { b.classList.remove('active'); });
   var tab = document.getElementById('yr-tab-' + year);
   if (tab) tab.classList.add('active');

   // Reset filters when switching year
   document.getElementById('exp-month').value    = '0';
   document.getElementById('exp-category').value = '';

   Promise.all([
      fetch('ws/tx-data/monthly-by-category/' + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-data/categories/' + year,           { credentials: 'same-origin' }).then(function(r) { return r.json(); })
   ])
   .then(function(results)
   {
      mbcData = results[0];
      populateCategoryDropdown(results[1]);
      renderStackedChart(0, '');
      loadTransactions();
   })
   .catch(function(e) { console.error('selectYear failed', e); });
}

function populateCategoryDropdown(categories)
{
   var sel = document.getElementById('exp-category');
   while (sel.options.length > 1) sel.remove(1);
   categories.forEach(function(c)
   {
      var opt = document.createElement('option');
      opt.value       = c.category;
      opt.textContent = c.category + ' (' + fmt(c.totalDebit) + ')';
      sel.appendChild(opt);
   });
}

function onFilterChange()
{
   var month    = parseInt(document.getElementById('exp-month').value, 10);
   var category = document.getElementById('exp-category').value;
   renderStackedChart(month, category);
   loadTransactions();
}

// Builds the stacked bar chart from mbcData, optionally filtered.
function renderStackedChart(filterMonth, filterCategory)
{
   if (expChart) { expChart.destroy(); expChart = null; }

   // Determine months present in the filtered view
   var monthSet = {};
   mbcData.forEach(function(d)
   {
      if (filterMonth === 0 || d.month === filterMonth)
         monthSet[d.month] = true;
   });
   var months = Object.keys(monthSet).map(Number).sort(function(a, b) { return a - b; });

   // Determine categories present in the filtered view
   var catOrder = [];
   var catSeen  = {};
   mbcData.forEach(function(d)
   {
      if ((filterMonth === 0 || d.month === filterMonth) &&
          (!filterCategory || d.category === filterCategory))
      {
         if (!catSeen[d.category]) { catSeen[d.category] = true; catOrder.push(d.category); }
      }
   });

   // Build lookup: "month|category" -> totalDebit
   var lookup = {};
   mbcData.forEach(function(d)
   {
      if (!filterCategory || d.category === filterCategory)
         lookup[d.month + '|' + d.category] = d.totalDebit;
   });

   var labels   = months.map(function(m) { return MONTH_LABELS[m - 1]; });
   var datasets = catOrder.map(function(cat, i)
   {
      return {
         label:           cat,
         data:            months.map(function(m) { return lookup[m + '|' + cat] || 0; }),
         backgroundColor: PALETTE[i % PALETTE.length],
         borderRadius:    2,
         stack:           'spend'
      };
   });

   var ctx = document.getElementById('expStackedChart').getContext('2d');
   expChart = new Chart(ctx, {
      type: 'bar',
      data: { labels: labels, datasets: datasets },
      options: {
         responsive: true,
         maintainAspectRatio: false,
         plugins: {
            legend: {
               position: 'bottom',
               labels:   { font: { size: 10 }, boxWidth: 12, padding: 6 }
            },
            tooltip: {
               callbacks: { label: function(c) { return c.dataset.label + ': ' + fmt(c.parsed.y); } }
            }
         },
         scales: {
            x: {
               stacked: true,
               ticks:   { font: { size: 11 } },
               grid:    { display: false }
            },
            y: {
               stacked: true,
               ticks:   { font: { size: 11 }, callback: function(v) { return '$' + (v / 1000).toFixed(0) + 'k'; } },
               grid:    { color: 'rgba(0,0,0,0.05)' }
            }
         }
      }
   });
}

function loadTransactions()
{
   if (!selectedYear) return;

   var month    = parseInt(document.getElementById('exp-month').value, 10);
   var category = document.getElementById('exp-category').value;

   var url = 'ws/tx-data/transactions?year=' + selectedYear;
   if (month > 0) url += '&month=' + month;
   if (category)  url += '&category=' + encodeURIComponent(category);

   fetch(url, { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(rows)
      {
         var label = rows.length + ' transaction' + (rows.length !== 1 ? 's' : '');
         if (rows.length === 2000) label += ' (limit reached)';
         document.getElementById('exp-tx-count').textContent = label;
         renderTransactionsTable(rows);
      })
      .catch(function(e) { console.error('loadTransactions failed', e); });
}

function renderTransactionsTable(rows)
{
   if ($.fn.DataTable.isDataTable('#exp-tx-table'))
      $('#exp-tx-table').DataTable().destroy();

   var html = '';
   rows.forEach(function(r)
   {
      var confClass = r.confidence === 'high'   ? 'conf-high'
                    : r.confidence === 'medium' ? 'conf-med'
                    :                             'conf-low';
      html += '<tr>'
            + '<td style="white-space:nowrap;">'   + escHtml(r.date) + '</td>'
            + '<td>'                               + escHtml(r.narrative) + '</td>'
            + '<td class="text-end">' + (r.debitAmount  > 0 ? '<span class="text-danger">'  + fmt(r.debitAmount)  + '</span>' : '') + '</td>'
            + '<td class="text-end">' + (r.creditAmount > 0 ? '<span class="text-success">' + fmt(r.creditAmount) + '</span>' : '') + '</td>'
            + '<td>'                               + escHtml(r.category) + '</td>'
            + '<td><span class="' + confClass + '">' + escHtml(r.confidence) + '</span></td>'
            + '</tr>';
   });
   document.getElementById('exp-tx-tbody').innerHTML = html;

   $('#exp-tx-table').DataTable({
      pageLength: 25,
      order:      [[0, 'desc']],
      language:   { search: '', searchPlaceholder: 'Filter...' },
      columnDefs: [{ orderable: false, targets: [5] }]
   });
}

function fmt(n)
{
   return '$' + Number(n).toLocaleString('en-AU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function escHtml(s)
{
   return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}
</script>

<%@ include file="footer.jsp" %>
