<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "pg-summary"); %>
<%@ include file="header.jsp" %>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>

<style>
   .sum-chart-wrapper { position: relative; height: 280px; }
   .section-title { font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: #64748b; margin-bottom: 10px; }
   .metric-row { display: flex; justify-content: space-between; font-size: 12px; padding: 5px 0; border-bottom: 1px solid #f1f5f9; }
   .metric-row:last-child { border-bottom: none; }
   .metric-lbl { color: #64748b; }
   .metric-val { font-weight: 600; color: #1e2738; }
   .gain-pos { color: #16a34a !important; }
   .gain-neg { color: #dc2626 !important; }
   .yr-tab { cursor:pointer; padding:5px 14px; border-radius:4px; font-size:12px; font-weight:600;
              border:1px solid #dee2e6; background:#fff; color:#64748b; }
   .yr-tab.active { background:#1e2738; color:#e2e8f0; border-color:#1e2738; }
</style>

<h5 class="mb-1">Summary &amp; Charts</h5>
<p class="text-muted mb-4" style="font-size:13px;">Balance trend and discretionary spend — selectable date range across financial years.</p>

<!-- Year selector -->
<div class="d-flex gap-2 align-items-center mb-4 flex-wrap">
   <span style="font-size:12px;color:#64748b;font-weight:600;">Year:</span>
   <div id="sum-year-tabs" class="d-flex gap-2 flex-wrap"></div>
   <button class="yr-tab" onclick="selectAllYears()" id="btn-all-years">All Years</button>
</div>

<div class="row g-4">

   <!-- Balance trend chart -->
   <div class="col-lg-8">
      <div class="card shadow-sm mb-4">
         <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
               <div class="section-title mb-0">Monthly Balance Trend</div>
               <div class="d-flex gap-2 align-items-center flex-wrap">
                  <label style="font-size:12px;color:#64748b;margin:0;">From:</label>
                  <input type="date" class="form-control form-control-sm" id="bal-from" style="width:140px;" onchange="renderBalanceChart()">
                  <label style="font-size:12px;color:#64748b;margin:0;">To:</label>
                  <input type="date" class="form-control form-control-sm" id="bal-to"   style="width:140px;" onchange="renderBalanceChart()">
               </div>
            </div>
            <div class="sum-chart-wrapper"><canvas id="balanceChart"></canvas></div>
         </div>
      </div>

      <div class="card shadow-sm">
         <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
               <div class="section-title mb-0" id="disc-chart-title">Discretionary Spend — Monthly</div>
               <div class="d-flex gap-2 align-items-center flex-wrap">
                  <label style="font-size:12px;color:#64748b;margin:0;">From:</label>
                  <input type="date" class="form-control form-control-sm" id="disc-from" style="width:140px;" onchange="renderDiscChart()">
                  <label style="font-size:12px;color:#64748b;margin:0;">To:</label>
                  <input type="date" class="form-control form-control-sm" id="disc-to"   style="width:140px;" onchange="renderDiscChart()">
               </div>
            </div>
            <div class="sum-chart-wrapper"><canvas id="discChart"></canvas></div>
         </div>
      </div>
   </div>

   <!-- Right: key metrics per year -->
   <div class="col-lg-4">
      <div class="card shadow-sm">
         <div class="card-body">
            <div class="section-title">Key Metrics by Year</div>
            <div id="year-metrics">
               <div style="font-size:12px;color:#94a3b8;">Loading...</div>
            </div>
         </div>
      </div>
   </div>

</div>

<script>
var allYears      = [];
var allMonthData  = {};   // year_id -> [{month, entries}]
var fixedYearly   = 0;
var balanceChart  = null;
var discChart     = null;
var selectedYears = [];   // year ids to show; empty = all

var MONTH_NAMES   = ['July','August','September','October','November','December',
                     'January','February','March','April','May','June'];

document.addEventListener('DOMContentLoaded', function()
{
   Promise.all([
      fetch('ws/years',       { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/fixed-input', { credentials: 'same-origin' }).then(function(r) { return r.json(); })
   ])
   .then(function(results)
   {
      allYears = results[0];
      var fixedItems = results[1];

      fixedYearly = fixedItems
         .filter(function(i) { return i.is_active; })
         .reduce(function(sum, i)
         {
            var mult = i.frequency === 'Monthly' ? 12 : i.frequency === 'Quarterly' ? 4 : i.frequency === 'Weekly' ? 52 : 1;
            return sum + i.item_cost * mult;
         }, 0);

      renderYearTabs();

      // Load data for all years
      var fetches = allYears.map(function(y) { return loadYearData(y); });
      return Promise.all(fetches);
   })
   .then(function()
   {
      selectAllYears();
      renderMetrics();
   });
});

function loadYearData(year)
{
   return fetch('ws/months?year_id=' + year.id, { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(months)
      {
         var fetches = months.map(function(m)
         {
            return fetch('ws/entries?month_id=' + m.id, { credentials: 'same-origin' })
               .then(function(r) { return r.json(); })
               .then(function(ents) { return { month: m, entries: ents }; });
         });
         return Promise.all(fetches);
      })
      .then(function(data) { allMonthData[year.id] = data; });
}

function renderYearTabs()
{
   var bar = document.getElementById('sum-year-tabs');
   bar.innerHTML = '';
   allYears.forEach(function(y)
   {
      var btn = document.createElement('button');
      btn.className = 'yr-tab';
      btn.textContent = y.year_label;
      btn.dataset.yid = y.id;
      btn.onclick = function() { selectOneYear(y.id); };
      bar.appendChild(btn);
   });
}

function selectAllYears()
{
   selectedYears = allYears.map(function(y) { return y.id; });
   document.getElementById('btn-all-years').classList.add('active');
   document.querySelectorAll('#sum-year-tabs .yr-tab').forEach(function(b) { b.classList.remove('active'); });
   applyDateRangeForSelection();
   renderBalanceChart();
   renderDiscChart();
}

function selectOneYear(yearId)
{
   selectedYears = [yearId];
   document.getElementById('btn-all-years').classList.remove('active');
   document.querySelectorAll('#sum-year-tabs .yr-tab').forEach(function(b)
   {
      b.classList.toggle('active', parseInt(b.dataset.yid) === yearId);
   });
   applyDateRangeForSelection();
   renderBalanceChart();
   renderDiscChart();
}

function applyDateRangeForSelection()
{
   // Set date pickers to span the selected years
   var allPoints = buildBalancePoints();
   if (allPoints.length === 0) return;
   var first = allPoints[0].date;
   var last  = allPoints[allPoints.length - 1].date;
   document.getElementById('bal-from').value  = first;
   document.getElementById('bal-to').value    = last;
   document.getElementById('disc-from').value = first;
   document.getElementById('disc-to').value   = last;
}

// Build [{date, balance, yearLabel}] across selected years in order.
// The balance always chains from the very first year in allYears, so individual
// year tabs for non-first years show the correct projected opening balance rather
// than the static value stored in financial_year.opening_balance.
function buildBalancePoints()
{
   var points = [];

   // Identify where in allYears the current selection begins.
   var firstYid = selectedYears[0];
   var startIdx = allYears.findIndex(function(y) { return y.id === firstYid; });

   // Pre-compute the chained balance up to (but not including) startIdx.
   // If the selection starts at year 0 there is nothing to pre-compute.
   var chainBalance = null;
   if (startIdx > 0)
   {
      chainBalance = allYears[0].opening_balance;
      for (var i = 0; i < startIdx; i++)
      {
         var prevData = allMonthData[allYears[i].id] || [];
         prevData.forEach(function(md)
         {
            var d = md.entries.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
            var c = md.entries.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
            chainBalance = chainBalance - d + c;
         });
      }
   }

   selectedYears.forEach(function(yid, selIdx)
   {
      var year = allYears.find(function(y) { return y.id === yid; });
      if (!year) return;
      var monthData = allMonthData[yid] || [];

      var balance = (chainBalance !== null) ? chainBalance : year.opening_balance;

      // Opening point shown only for the first year in the current selection.
      if (selIdx === 0)
      {
         points.push({ date: year.start_date, balance: balance, yearLabel: year.year_label });
      }

      monthData.forEach(function(md, idx)
      {
         var debits  = md.entries.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
         var credits = md.entries.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
         balance = balance - debits + credits;

         // Use end-of-month as date: month_number maps to a calendar month
         var yr    = parseInt(year.start_date.substring(0, 4));
         var calMo = md.month.month_number <= 6 ? md.month.month_number + 6 : md.month.month_number - 6;
         var calYr = md.month.month_number <= 6 ? yr : yr + 1;
         var lastDay = new Date(calYr, calMo, 0).getDate();
         var dateStr = calYr + '-' + pad(calMo) + '-' + pad(lastDay);

         points.push({ date: dateStr, balance: balance, yearLabel: year.year_label,
                       month: MONTH_NAMES[idx], debits: debits, credits: credits });
      });

      chainBalance = balance;   // carry forward to next year in selection
   });

   points.sort(function(a, b) { return a.date.localeCompare(b.date); });
   return points;
}

function buildDiscPoints()
{
   var points = [];
   selectedYears.forEach(function(yid)
   {
      var year      = allYears.find(function(y) { return y.id === yid; });
      if (!year) return;
      var monthData = allMonthData[yid] || [];

      monthData.forEach(function(md, idx)
      {
         var debits = md.entries.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);

         var yr      = parseInt(year.start_date.substring(0, 4));
         var calMo   = md.month.month_number <= 6 ? md.month.month_number + 6 : md.month.month_number - 6;
         var calYr   = md.month.month_number <= 6 ? yr : yr + 1;
         var lastDay = new Date(calYr, calMo, 0).getDate();
         var dateStr = calYr + '-' + pad(calMo) + '-' + pad(lastDay);

         points.push({ date: dateStr, debits: debits, label: MONTH_NAMES[idx] + ' ' + calYr });
      });
   });
   points.sort(function(a, b) { return a.date.localeCompare(b.date); });
   return points;
}

function renderBalanceChart()
{
   var from   = document.getElementById('bal-from').value;
   var to     = document.getElementById('bal-to').value;
   var points = buildBalancePoints().filter(function(p)
   {
      return (!from || p.date >= from) && (!to || p.date <= to);
   });

   var labels = points.map(function(p) { return p.month ? p.month + ' ' + p.date.substring(0,4) : 'Start ' + (p.yearLabel || ''); });
   var values = points.map(function(p) { return p.balance; });

   if (balanceChart) { balanceChart.destroy(); balanceChart = null; }
   var ctx = document.getElementById('balanceChart').getContext('2d');
   balanceChart = new Chart(ctx, {
      type: 'line',
      data: {
         labels: labels,
         datasets: [{
            label: 'Balance',
            data: values,
            borderColor: '#3b82f6',
            backgroundColor: 'rgba(59,130,246,0.07)',
            borderWidth: 2,
            pointRadius: points.length > 40 ? 0 : 3,
            pointHoverRadius: 5,
            tension: 0.2,
            fill: true
         }]
      },
      options: chartOptions(function(v) { return '$' + (v/1000).toFixed(0) + 'k'; })
   });
}

function renderDiscChart()
{
   var from   = document.getElementById('disc-from').value;
   var to     = document.getElementById('disc-to').value;
   var points = buildDiscPoints().filter(function(p)
   {
      return (!from || p.date >= from) && (!to || p.date <= to);
   });

   var labels       = points.map(function(p) { return p.label; });
   var avgFixed     = fixedYearly / 12;
   var fixedRounded = Math.round(avgFixed);
   var fixedLabel   = '$' + fixedRounded.toLocaleString('en-AU');

   document.getElementById('disc-chart-title').textContent =
      'Discretionary Spend — Monthly (Minimum Fixed: ' + fixedLabel + ')';

   // Bottom segment: spend up to the fixed threshold (green).
   // Top segment: spend above the fixed threshold (red).
   var baseValues = points.map(function(p) { return Math.min(Math.round(p.debits), fixedRounded); });
   var overValues = points.map(function(p) { return Math.max(0, Math.round(p.debits) - fixedRounded); });

   if (discChart) { discChart.destroy(); discChart = null; }
   var ctx = document.getElementById('discChart').getContext('2d');
   discChart = new Chart(ctx, {
      type: 'bar',
      data: {
         labels: labels,
         datasets: [
            {
               label: 'Base Spend',
               data: baseValues,
               backgroundColor: 'rgba(34,197,94,0.7)',
               stack: 'spend',
               borderRadius: 0,
               order: 2
            },
            {
               label: 'Above Fixed',
               data: overValues,
               backgroundColor: 'rgba(239,68,68,0.7)',
               stack: 'spend',
               borderRadius: 3,
               order: 2
            },
            {
               type: 'line',
               label: 'Minimum Fixed: ' + fixedLabel,
               data: labels.map(function() { return fixedRounded; }),
               borderColor: 'rgba(100,116,139,0.8)',
               borderWidth: 2,
               borderDash: [6, 4],
               pointRadius: 0,
               fill: false,
               order: 1
            }
         ]
      },
      options: discChartOptions()
   });
}

function discChartOptions()
{
   return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
         legend: { display: true, labels: { font: { size: 11 }, boxWidth: 12 } },
         tooltip: {
            callbacks: {
               label: function(c)
               {
                  if (c.parsed.y === 0) return null;
                  return c.dataset.label + ': ' + fmt(c.parsed.y);
               }
            }
         }
      },
      scales: {
         x: { stacked: true, ticks: { font: { size: 11 }, maxRotation: 45, maxTicksLimit: 18 }, grid: { display: false } },
         y: { stacked: true, ticks: { font: { size: 11 }, callback: function(v) { return '$' + (v/1000).toFixed(1) + 'k'; } }, grid: { color: 'rgba(0,0,0,0.05)' } }
      }
   };
}

function chartOptions(yFormatter)
{
   return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
         legend: { display: false },
         tooltip: { callbacks: { label: function(c) { return fmt(c.parsed.y); } } }
      },
      scales: {
         x: { ticks: { font: { size: 11 }, maxRotation: 45, maxTicksLimit: 18 }, grid: { display: false } },
         y: { ticks: { font: { size: 11 }, callback: yFormatter }, grid: { color: 'rgba(0,0,0,0.05)' } }
      }
   };
}

function renderMetrics()
{
   var html = '';
   allYears.forEach(function(year)
   {
      var monthData  = allMonthData[year.id] || [];
      var balance    = year.opening_balance;
      var totalDebit = 0;
      monthData.forEach(function(md)
      {
         var d = md.entries.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
         var c = md.entries.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
         balance    += (c - d);
         totalDebit += d;
      });
      var gain  = balance - year.opening_balance;
      var disc  = Math.max(0, totalDebit - fixedYearly);
      var onTgt = gain - year.target_gain;

      html += '<div style="margin-bottom:16px;">' +
         '<div style="font-size:12px;font-weight:700;color:#1e2738;margin-bottom:6px;">' + year.year_label + '</div>' +
         mRow('Opening',        fmt(year.opening_balance)) +
         mRow('Closing (proj)', fmt(balance)) +
         mRow('Gain / Loss',    '<span class="' + (gain >= 0 ? 'gain-pos' : 'gain-neg') + '">' + (gain >= 0 ? '+' : '') + fmt(gain) + '</span>') +
         mRow('On Target',      '<span class="' + (onTgt >= 0 ? 'gain-pos' : 'gain-neg') + '">' + (onTgt >= 0 ? '+' : '') + fmt(onTgt) + '</span>') +
         mRow('Disc. / day',    fmt(disc / 365)) +
         '</div>';
   });
   document.getElementById('year-metrics').innerHTML = html || '<div style="font-size:12px;color:#94a3b8;">No data.</div>';
}

function mRow(lbl, val)
{
   return '<div class="metric-row"><span class="metric-lbl">' + lbl + '</span><span class="metric-val">' + val + '</span></div>';
}

function pad(n) { return n < 10 ? '0' + n : '' + n; }

function fmt(n)
{
   return '$' + Number(n).toLocaleString('en-AU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}
</script>

<%@ include file="footer.jsp" %>
