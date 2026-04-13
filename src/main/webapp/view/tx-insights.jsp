<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "tx-insights"); %>
<%@ include file="header.jsp" %>

<style>
   .yr-tab        { cursor: pointer; padding: 5px 14px; border-radius: 4px; font-size: 12px; font-weight: 600;
                    border: 1px solid #dee2e6; background: #fff; color: #64748b; }
   .yr-tab.active { background: #1e2738; color: #e2e8f0; border-color: #1e2738; }
   .section-title { font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: #64748b; margin-bottom: 10px; }
   .chart-wrap    { position: relative; height: 280px; }
   .chart-wrap-sm { position: relative; height: 240px; }
   .ins-note      { font-size: 11px; color: #94a3b8; margin-top: 4px; }
   #ins-largest-table th, #ins-largest-table td { font-size: 12px; }
   .proj-total td { font-weight: 700; color: #1e2738; border-top: 2px solid #dee2e6 !important; }
</style>

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
   <h5 class="mb-0">Transaction Insights</h5>
   <a href="/budgetapi?rq=tx-dashboard" class="text-muted" style="font-size:12px;">
      <i class="fa-solid fa-arrow-left me-1"></i>Back to Dashboard
   </a>
</div>

<!-- ── Year tabs ──────────────────────────────────────────────────────── -->
<div class="d-flex gap-2 align-items-center mb-4 flex-wrap">
   <span style="font-size:12px;color:#64748b;font-weight:600;">Year:</span>
   <div id="ins-year-tabs" class="d-flex gap-2 flex-wrap">
      <span style="font-size:12px;color:#94a3b8;">Loading...</span>
   </div>
</div>

<!-- ── Section 1: Rolling Average & Trajectory ────────────────────────── -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Rolling Average &amp; Trajectory — <span id="ins-rolling-year">...</span></div>
      <p class="ins-note mb-2">Bars = monthly spend &nbsp;|&nbsp; Line = 3-month rolling average</p>
      <div class="chart-wrap"><canvas id="insRollingChart"></canvas></div>
   </div>
</div>

<!-- ── Section 2: Largest Single Transactions ─────────────────────────── -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Largest Single Transactions — <span id="ins-largest-year">...</span></div>
      <table id="ins-largest-table" class="table table-sm table-hover" style="width:100%;">
         <thead>
            <tr>
               <th>Date</th>
               <th>Narrative</th>
               <th class="text-end">Amount</th>
               <th>Category</th>
            </tr>
         </thead>
         <tbody id="ins-largest-tbody"></tbody>
      </table>
   </div>
</div>

<!-- ── Section 3: Day-of-Week + Category Ratios ───────────────────────── -->
<div class="row g-3 mb-4">
   <div class="col-lg-6">
      <div class="card shadow-sm h-100">
         <div class="card-body">
            <div class="section-title">Spend by Day of Week</div>
            <p class="ins-note mb-2">Average total spend per occurrence of that weekday &nbsp;|&nbsp; <span style="color:#ef4444;">&#9632;</span> Weekend</p>
            <div class="chart-wrap-sm"><canvas id="insDowChart"></canvas></div>
         </div>
      </div>
   </div>
   <div class="col-lg-6">
      <div class="card shadow-sm h-100">
         <div class="card-body">
            <div class="section-title">Category Share of Total Spend</div>
            <p class="ins-note mb-2">% of total debit spend per category</p>
            <div class="chart-wrap-sm"><canvas id="insCatRatioChart"></canvas></div>
         </div>
      </div>
   </div>
</div>

<!-- ── Section 4: Annual Cost Projection ──────────────────────────────── -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Annual Cost Projection — <span id="ins-proj-year">...</span></div>
      <p class="ins-note mb-3">Based on average monthly spend for the selected year extrapolated to 12 months. "Months" shows how many months had activity.</p>
      <div class="table-responsive">
         <table class="table table-sm table-hover" style="width:100%;">
            <thead>
               <tr>
                  <th>Category</th>
                  <th class="text-center">Months</th>
                  <th class="text-end">Avg / Month</th>
                  <th class="text-end">Projected Annual</th>
               </tr>
            </thead>
            <tbody id="ins-proj-tbody"></tbody>
            <tfoot id="ins-proj-tfoot"></tfoot>
         </table>
      </div>
   </div>
</div>

<script>
var MONTH_LABELS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
var PALETTE = [
   '#3b82f6','#ef4444','#10b981','#f59e0b','#8b5cf6',
   '#06b6d4','#f97316','#ec4899','#14b8a6','#84cc16',
   '#6366f1','#e11d48','#0ea5e9','#22c55e','#eab308'
];

var insRollingChart  = null;
var insDowChart      = null;
var insCatRatioChart = null;
var selectedYear     = null;

document.addEventListener('DOMContentLoaded', function()
{
   fetch('ws/tx-data/years', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(years)
      {
         if (!years.length)
         {
            document.getElementById('ins-year-tabs').innerHTML =
               '<span style="font-size:12px;color:#94a3b8;">No transaction data found.</span>';
            return;
         }
         renderYearTabs(years);
         selectYear(years[0]);
      })
      .catch(function(e) { console.error('tx-insights init failed', e); });
});

function renderYearTabs(years)
{
   var html = '';
   years.forEach(function(yr)
   {
      html += '<button class="yr-tab" id="yr-tab-' + yr + '" onclick="selectYear(' + yr + ')">' + yr + '</button>';
   });
   document.getElementById('ins-year-tabs').innerHTML = html;
}

function selectYear(year)
{
   selectedYear = year;
   document.querySelectorAll('.yr-tab').forEach(function(b) { b.classList.remove('active'); });
   var tab = document.getElementById('yr-tab-' + year);
   if (tab) tab.classList.add('active');

   document.getElementById('ins-rolling-year').textContent = year;
   document.getElementById('ins-largest-year').textContent = year;
   document.getElementById('ins-proj-year').textContent    = year;

   Promise.all([
      fetch('ws/tx-insights/rolling/'    + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-insights/largest?year=' + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-insights/dow/'        + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-insights/projection/' + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); })
   ])
   .then(function(results)
   {
      renderRollingSection(results[0], year);
      renderLargestTable(results[1]);
      renderDowChart(results[2]);
      renderCatRatioChart(results[3]);
      renderProjectionTable(results[3]);
   })
   .catch(function(e) { console.error('tx-insights selectYear failed', e); });
}

// ── Rolling Average ───────────────────────────────────────────────────

function renderRollingSection(rawData, yr)
{
   if (insRollingChart) { insRollingChart.destroy(); insRollingChart = null; }

   // Separate context months (prior year) from display months (selected year)
   var thisYear = [];
   rawData.forEach(function(d) { if (d.year === yr) thisYear.push(d); });

   if (!thisYear.length)
   {
      document.getElementById('insRollingChart').style.display = 'none';
      return;
   }
   document.getElementById('insRollingChart').style.display = '';

   var labels  = thisYear.map(function(d) { return MONTH_LABELS[d.month - 1]; });
   var actuals = thisYear.map(function(d) { return d.totalDebit; });

   // Compute 3-month rolling average using rawData (which includes context months)
   var rolling = thisYear.map(function(m)
   {
      // Find this month's position in the full rawData array
      var idx = -1;
      for (var j = 0; j < rawData.length; j++)
      {
         if (rawData[j].year === m.year && rawData[j].month === m.month)
         {
            idx = j;
            break;
         }
      }
      var win = rawData.slice(Math.max(0, idx - 2), idx + 1);
      var sum = win.reduce(function(s, d) { return s + d.totalDebit; }, 0);
      return Math.round(sum / win.length * 100) / 100;
   });

   var ctx = document.getElementById('insRollingChart').getContext('2d');
   insRollingChart = new Chart(ctx, {
      type: 'bar',
      data: {
         labels: labels,
         datasets: [
            {
               label:           'Monthly Spend',
               data:            actuals,
               backgroundColor: 'rgba(239,68,68,0.60)',
               borderRadius:    3,
               order:           2
            },
            {
               type:                'line',
               label:               '3-Month Rolling Avg',
               data:                rolling,
               borderColor:         '#3b82f6',
               backgroundColor:     'rgba(59,130,246,0.08)',
               borderWidth:         2.5,
               pointRadius:         4,
               pointBackgroundColor:'#3b82f6',
               tension:             0.3,
               fill:                false,
               order:               1
            }
         ]
      },
      options: {
         responsive: true,
         maintainAspectRatio: false,
         plugins: {
            legend:  { position: 'top', labels: { font: { size: 11 }, boxWidth: 12 } },
            tooltip: { callbacks: { label: function(c) { return c.dataset.label + ': ' + fmt(c.parsed.y); } } }
         },
         scales: {
            x: { ticks: { font: { size: 11 } }, grid: { display: false } },
            y: {
               ticks: { font: { size: 11 }, callback: function(v) { return '$' + (v / 1000).toFixed(0) + 'k'; } },
               grid:  { color: 'rgba(0,0,0,0.05)' }
            }
         }
      }
   });
}

// ── Largest Transactions ──────────────────────────────────────────────

function renderLargestTable(rows)
{
   if ($.fn.DataTable.isDataTable('#ins-largest-table'))
      $('#ins-largest-table').DataTable().destroy();

   var html = '';
   rows.forEach(function(r)
   {
      html += '<tr>'
            + '<td style="white-space:nowrap;">' + escHtml(r.date) + '</td>'
            + '<td>' + escHtml(r.narrative) + '</td>'
            + '<td class="text-end" data-order="' + r.debitAmount + '">'
            +    '<span style="color:#ef4444;font-weight:600;">' + fmt(r.debitAmount) + '</span>'
            + '</td>'
            + '<td>' + escHtml(r.category) + '</td>'
            + '</tr>';
   });
   document.getElementById('ins-largest-tbody').innerHTML = html;

   $('#ins-largest-table').DataTable({
      pageLength: 20,
      order:      [[2, 'desc']],
      language:   { search: '', searchPlaceholder: 'Filter...' },
      columnDefs: [{ targets: [2], type: 'num' }]
   });
}

// ── Day of Week ───────────────────────────────────────────────────────

function renderDowChart(data)
{
   if (insDowChart) { insDowChart.destroy(); insDowChart = null; }
   if (!data.length) return;

   // MySQL DAYOFWEEK: 1=Sun, 2=Mon ... 7=Sat — sort to ensure correct order
   data.sort(function(a, b) { return a.dow - b.dow; });

   var labels = data.map(function(d) { return d.dowName.substring(0, 3); });
   // Average total spend per occurrence of that weekday (not per-transaction average)
   var values = data.map(function(d)
   {
      return d.daysCount > 0 ? Math.round(d.totalDebit / d.daysCount * 100) / 100 : 0;
   });
   // Weekends (dow 1=Sun, 7=Sat) in red; weekdays in blue
   var colors = data.map(function(d)
   {
      return (d.dow === 1 || d.dow === 7) ? 'rgba(239,68,68,0.75)' : 'rgba(59,130,246,0.75)';
   });

   var ctx = document.getElementById('insDowChart').getContext('2d');
   insDowChart = new Chart(ctx, {
      type: 'bar',
      data: {
         labels: labels,
         datasets: [{
            label:           'Avg Spend',
            data:            values,
            backgroundColor: colors,
            borderRadius:    3
         }]
      },
      options: {
         responsive: true,
         maintainAspectRatio: false,
         plugins: {
            legend:  { display: false },
            tooltip: {
               callbacks: {
                  label: function(c)
                  {
                     return 'Avg ' + fmt(c.parsed.y) + ' on a typical ' + c.label;
                  }
               }
            }
         },
         scales: {
            x: { ticks: { font: { size: 11 } }, grid: { display: false } },
            y: {
               ticks: { font: { size: 11 }, callback: function(v) { return '$' + v.toFixed(0); } },
               grid:  { color: 'rgba(0,0,0,0.05)' }
            }
         }
      }
   });
}

// ── Category Ratios ───────────────────────────────────────────────────

function renderCatRatioChart(projData)
{
   if (insCatRatioChart) { insCatRatioChart.destroy(); insCatRatioChart = null; }
   if (!projData.length) return;

   var total  = projData.reduce(function(s, d) { return s + d.totalDebit; }, 0);
   var cats   = projData.slice(0, 12); // top 12 for readability
   var labels = cats.map(function(d) { return d.category; });
   var values = cats.map(function(d)
   {
      return total > 0 ? Math.round(d.totalDebit / total * 1000) / 10 : 0;
   });
   var colors = cats.map(function(_, i) { return PALETTE[i % PALETTE.length]; });

   var ctx = document.getElementById('insCatRatioChart').getContext('2d');
   insCatRatioChart = new Chart(ctx, {
      type: 'bar',
      data: {
         labels: labels,
         datasets: [{
            data:            values,
            backgroundColor: colors,
            borderRadius:    3
         }]
      },
      options: {
         indexAxis: 'y',
         responsive: true,
         maintainAspectRatio: false,
         plugins: {
            legend:  { display: false },
            tooltip: {
               callbacks: {
                  label: function(c) { return c.parsed.x.toFixed(1) + '% of total spend'; }
               }
            }
         },
         scales: {
            x: {
               ticks: { font: { size: 11 }, callback: function(v) { return v + '%'; } },
               grid:  { color: 'rgba(0,0,0,0.05)' }
            },
            y: { ticks: { font: { size: 10 } }, grid: { display: false } }
         }
      }
   });
}

// ── Annual Projection ─────────────────────────────────────────────────

function renderProjectionTable(data)
{
   if (!data.length)
   {
      document.getElementById('ins-proj-tbody').innerHTML =
         '<tr><td colspan="4" style="font-size:12px;color:#94a3b8;">No data.</td></tr>';
      return;
   }

   var totalProjected = data.reduce(function(s, d) { return s + d.projectedAnnual; }, 0);
   var html = '';
   data.forEach(function(d)
   {
      var monthsLabel = d.monthsActive + '/12';
      var partialNote = d.monthsActive < 12
         ? ' <span style="font-size:10px;color:#f59e0b;" title="Fewer than 12 months of data">&#9651;</span>'
         : '';
      html += '<tr>'
            + '<td>' + escHtml(d.category) + '</td>'
            + '<td class="text-center" style="color:#94a3b8;">' + monthsLabel + partialNote + '</td>'
            + '<td class="text-end">' + fmt(d.avgMonthly) + '</td>'
            + '<td class="text-end" style="font-weight:600;">' + fmt(d.projectedAnnual) + '</td>'
            + '</tr>';
   });
   document.getElementById('ins-proj-tbody').innerHTML = html;

   document.getElementById('ins-proj-tfoot').innerHTML =
      '<tr class="proj-total">'
    + '<td colspan="3">Total Estimated Annual</td>'
    + '<td class="text-end">' + fmt(totalProjected) + '</td>'
    + '</tr>';
}

// ── Utilities ─────────────────────────────────────────────────────────

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
