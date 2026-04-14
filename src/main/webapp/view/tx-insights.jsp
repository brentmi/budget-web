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
   .anomaly-high  { background: #fee2e2; color: #991b1b; font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 3px; }
   .anomaly-med   { background: #fef9c3; color: #854d0e; font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 3px; }
   .freq-label    { font-size: 10px; font-weight: 600; padding: 2px 7px; border-radius: 3px; }
   #ins-velocity-table th, #ins-velocity-table td,
   #ins-subs-table th, #ins-subs-table td,
   #ins-merchants-table th, #ins-merchants-table td { font-size: 12px; }
   .wi-saving-val { font-size: 22px; font-weight: 700; color: #10b981; margin-top: 4px; }
</style>

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
   <h5 class="mb-0">Transaction Insights</h5>
   <a href="/budgetapi?rq=tx-dashboard" class="text-muted" style="font-size:12px;">
      <i class="fa-solid fa-arrow-left me-1"></i>Back to Dashboard
   </a>
</div>

<!-- ââ Year tabs ââââââââââââââââââââââââââââââââââââââââââââââââââââââââ -->
<div class="d-flex gap-2 align-items-center mb-4 flex-wrap">
   <span style="font-size:12px;color:#64748b;font-weight:600;">Year:</span>
   <div id="ins-year-tabs" class="d-flex gap-2 flex-wrap">
      <span style="font-size:12px;color:#94a3b8;">Loading...</span>
   </div>
</div>

<!-- ââ Section 1: Rolling Average & Trajectory ââââââââââââââââââââââââââ -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Rolling Average &amp; Trajectory â <span id="ins-rolling-year">...</span></div>
      <p class="ins-note mb-2">Bars = monthly spend &nbsp;|&nbsp; Line = 3-month rolling average</p>
      <div class="chart-wrap"><canvas id="insRollingChart"></canvas></div>
   </div>
</div>

<!-- ââ Section 2: Largest Single Transactions âââââââââââââââââââââââââââ -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Largest Single Transactions â <span id="ins-largest-year">...</span></div>
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

<!-- ââ Section 3: Day-of-Week + Category Ratios âââââââââââââââââââââââââ -->
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

<!-- ââ Section 4: Annual Cost Projection ââââââââââââââââââââââââââââââââ -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Annual Cost Projection â <span id="ins-proj-year">...</span></div>
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

<!-- ââ Section 5: Spending Anomalies ââââââââââââââââââââââââââââââââââââ -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Spending Anomalies â <span id="ins-anomaly-year">...</span></div>
      <p class="ins-note mb-3">Months where a category spiked &gt;25% above its 6-month trailing average. Requires at least 2 prior months of data per category.</p>
      <div id="ins-anomaly-content"><div style="font-size:12px;color:#94a3b8;">Loading...</div></div>
   </div>
</div>

<!-- ââ Section 6: Spending Velocity âââââââââââââââââââââââââââââââââââââ -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Spending Velocity â <span id="ins-velocity-year">...</span></div>
      <p class="ins-note mb-3">Average number of days between consecutive transactions per category. How frequently are you spending in each area?</p>
      <table id="ins-velocity-table" class="table table-sm table-hover" style="width:100%;">
         <thead>
            <tr>
               <th>Category</th>
               <th class="text-center">Transactions</th>
               <th class="text-center">Avg Days Between</th>
               <th class="text-center">Range</th>
               <th class="text-center">Frequency</th>
            </tr>
         </thead>
         <tbody id="ins-velocity-tbody"></tbody>
      </table>
   </div>
</div>

<!-- ââ Section 7: Subscription Audit âââââââââââââââââââââââââââââââââââ -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Subscription Audit</div>
      <p class="ins-note mb-3">Recurring charges detected over the last 24 months â same narrative, stable amount (CV &lt; 30%), roughly monthly cadence (20â50 day interval). <em>Year selector does not affect this section.</em></p>
      <div id="ins-subs-summary" class="mb-3"></div>
      <table id="ins-subs-table" class="table table-sm table-hover" style="width:100%;">
         <thead>
            <tr>
               <th>Narrative</th>
               <th>Category</th>
               <th class="text-center">Occurrences</th>
               <th class="text-center">Avg Interval</th>
               <th class="text-end">Avg Amount</th>
               <th class="text-end">Est. Annual Cost</th>
            </tr>
         </thead>
         <tbody id="ins-subs-tbody"></tbody>
         <tfoot id="ins-subs-tfoot"></tfoot>
      </table>
   </div>
</div>

<!-- ââ Section 8: Top Merchants âââââââââââââââââââââââââââââââââââââââââ -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Top Merchants â <span id="ins-merchants-year">...</span></div>
      <p class="ins-note mb-3">Top 30 narratives by total spend. Use the category filter to focus or exclude fixed costs.</p>
      <div class="d-flex align-items-center gap-2 mb-3">
         <label style="font-size:12px;color:#64748b;font-weight:600;margin:0;">Category:</label>
         <select id="merchants-cat-filter" class="form-select form-select-sm" style="font-size:12px;width:210px;" onchange="filterMerchantsTable()">
            <option value="">All categories</option>
         </select>
      </div>
      <table id="ins-merchants-table" class="table table-sm table-hover" style="width:100%;">
         <thead>
            <tr>
               <th>Narrative</th>
               <th>Category</th>
               <th class="text-center">Transactions</th>
               <th class="text-end">Total Spent</th>
               <th class="text-end">Avg per Transaction</th>
            </tr>
         </thead>
         <tbody id="ins-merchants-tbody"></tbody>
      </table>
   </div>
</div>

<!-- ââ Section 9: What If Sensitivity ââââââââââââââââââââââââââââââââââ -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">What If Sensitivity</div>
      <p class="ins-note mb-3">Select a category and a monthly reduction to see your projected 12-month saving. Projection uses the average monthly spend for the selected year.</p>
      <div class="row g-3 align-items-end mb-3">
         <div class="col-auto">
            <label style="font-size:12px;color:#64748b;font-weight:600;">Category</label>
            <div style="margin-top:4px;">
               <select id="wi-category" class="form-select form-select-sm" style="font-size:12px;width:210px;" onchange="onWhatIfCategoryChange()">
                  <option value="">â select a category â</option>
               </select>
            </div>
         </div>
         <div class="col-auto">
            <label style="font-size:12px;color:#64748b;font-weight:600;">Reduce by ($/month)</label>
            <div class="d-flex align-items-center gap-2 mt-1">
               <input type="range"  id="wi-slider"    min="0" max="500" step="10" value="0" style="width:150px;" oninput="syncWhatIfSlider(this)">
               <input type="number" id="wi-reduction" min="0" step="10" value="0" class="form-control form-control-sm" style="font-size:12px;width:78px;" oninput="syncWhatIfInput(this)">
            </div>
         </div>
         <div class="col-auto">
            <label style="font-size:12px;color:#64748b;font-weight:600;">Annual saving</label>
            <div id="wi-saving" class="wi-saving-val">$0.00</div>
         </div>
         <div class="col-auto">
            <label style="font-size:12px;color:#64748b;font-weight:600;">2-year saving</label>
            <div id="wi-saving-2yr" class="wi-saving-val">$0.00</div>
         </div>
      </div>
      <p id="wi-avg-label" class="ins-note mb-2"></p>
      <div class="chart-wrap"><canvas id="insWhatIfChart"></canvas></div>
   </div>
</div>

<!-- ââ Section 10: Subscription Creep Timeline âââââââââââââââââââââââââ -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="section-title">Subscription Creep Timeline</div>
      <p class="ins-note mb-3">Monthly charge amounts for each detected recurring subscription over its full history. One line per subscription. Year selector does not affect this section.</p>
      <div id="ins-sub-creep-wrap" style="position:relative;height:340px;">
         <canvas id="insSubCreepChart"></canvas>
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
var insWhatIfChart   = null;
var insSubCreepChart = null;
var selectedYear     = null;
var projData         = [];

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
         loadSubscriptions();
         loadSubCreep();
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

   document.getElementById('ins-rolling-year').textContent   = year;
   document.getElementById('ins-largest-year').textContent   = year;
   document.getElementById('ins-proj-year').textContent      = year;
   document.getElementById('ins-anomaly-year').textContent   = year;
   document.getElementById('ins-velocity-year').textContent  = year;
   document.getElementById('ins-merchants-year').textContent = year;

   Promise.all([
      fetch('ws/tx-insights/rolling/'      + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-insights/largest?year=' + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-insights/dow/'          + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-insights/projection/'   + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-insights/anomalies/'    + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-insights/velocity/'     + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/tx-insights/merchants/'    + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); })
   ])
   .then(function(results)
   {
      renderRollingSection(results[0], year);
      renderLargestTable(results[1]);
      renderDowChart(results[2]);
      projData = results[3];
      renderCatRatioChart(projData);
      renderProjectionTable(projData);
      populateWhatIfDropdown(projData);
      renderAnomalyTable(results[4], year);
      renderVelocityTable(results[5]);
      renderMerchantsTable(results[6]);
   })
   .catch(function(e) { console.error('tx-insights selectYear failed', e); });
}

// ââ Rolling Average âââââââââââââââââââââââââââââââââââââââââââââââââââ

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

// ââ Largest Transactions ââââââââââââââââââââââââââââââââââââââââââââââ

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

// ââ Day of Week âââââââââââââââââââââââââââââââââââââââââââââââââââââââ

function renderDowChart(data)
{
   if (insDowChart) { insDowChart.destroy(); insDowChart = null; }
   if (!data.length) return;

   // MySQL DAYOFWEEK: 1=Sun, 2=Mon ... 7=Sat â sort to ensure correct order
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

// ââ Category Ratios âââââââââââââââââââââââââââââââââââââââââââââââââââ

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


function renderAnomalyTable(anomalies, yr)
{
   var el = document.getElementById('ins-anomaly-content');
   if (!anomalies.length)
   {
      el.innerHTML = '<div style="font-size:12px;color:#10b981;font-weight:600;">'
                   + '<i class="fa-solid fa-circle-check me-1"></i>'
                   + 'No significant spending anomalies detected for ' + yr + '.</div>';
      return;
   }

   var cats = {};
   anomalies.forEach(function(a) { cats[a.category] = true; });
   var catCount = Object.keys(cats).length;

   var html = '<div class="mb-2" style="font-size:12px;color:#64748b;">'
            + '<strong style="color:#1e2738;">' + anomalies.length + ' spike'
            + (anomalies.length !== 1 ? 's' : '') + '</strong> detected across '
            + '<strong style="color:#1e2738;">' + catCount + '</strong> '
            + (catCount !== 1 ? 'categories' : 'category') + '</div>';

   html += '<table class="table table-sm" style="font-size:12px;">'
         + '<thead><tr>'
         + '<th>Month</th><th>Category</th>'
         + '<th class="text-end">Actual</th><th class="text-end">6-Month Avg</th>'
         + '<th class="text-end">% Above</th>'
         + '</tr></thead><tbody>';

   anomalies.forEach(function(a)
   {
      var pct        = a.pctAbove.toFixed(1);
      var badgeClass = a.pctAbove >= 75 ? 'anomaly-high' : 'anomaly-med';
      html += '<tr>'
            + '<td style="white-space:nowrap;">' + MONTH_LABELS[a.month - 1] + ' ' + yr + '</td>'
            + '<td>' + escHtml(a.category) + '</td>'
            + '<td class="text-end" style="color:#ef4444;font-weight:600;">' + fmt(a.actualSpend) + '</td>'
            + '<td class="text-end" style="color:#64748b;">' + fmt(a.avgSpend) + '</td>'
            + '<td class="text-end"><span class="' + badgeClass + '">+' + pct + '%</span></td>'
            + '</tr>';
   });
   html += '</tbody></table>';
   el.innerHTML = html;
}


function renderVelocityTable(data)
{
   if ($.fn.DataTable.isDataTable('#ins-velocity-table'))
      $('#ins-velocity-table').DataTable().destroy();

   if (!data.length)
   {
      document.getElementById('ins-velocity-tbody').innerHTML =
         '<tr><td colspan="5" style="font-size:12px;color:#94a3b8;">No data.</td></tr>';
      return;
   }

   var html = '';
   data.forEach(function(d)
   {
      var label, bg, fg;
      if      (d.avgDays < 3)  { label = 'Daily';       bg = '#fee2e2'; fg = '#991b1b'; }
      else if (d.avgDays < 10) { label = 'Weekly';      bg = '#ffedd5'; fg = '#9a3412'; }
      else if (d.avgDays < 20) { label = 'Fortnightly'; bg = '#fef9c3'; fg = '#854d0e'; }
      else if (d.avgDays < 45) { label = 'Monthly';     bg = '#dbeafe'; fg = '#1e40af'; }
      else                     { label = 'Sporadic';    bg = '#f1f5f9'; fg = '#475569'; }

      html += '<tr>'
            + '<td>' + escHtml(d.category) + '</td>'
            + '<td class="text-center">' + d.txCount + '</td>'
            + '<td class="text-center" data-order="' + d.avgDays + '" style="font-weight:600;">'
            +    d.avgDays.toFixed(1) + ' days'
            + '</td>'
            + '<td class="text-center" style="color:#94a3b8;font-size:11px;">'
            +    d.minGap + 'â' + d.maxGap + ' days'
            + '</td>'
            + '<td class="text-center">'
            +    '<span class="freq-label" style="background:' + bg + ';color:' + fg + ';">' + label + '</span>'
            + '</td>'
            + '</tr>';
   });
   document.getElementById('ins-velocity-tbody').innerHTML = html;

   $('#ins-velocity-table').DataTable({
      pageLength:  25,
      order:       [[2, 'asc']],
      language:    { search: '', searchPlaceholder: 'Filter...' },
      columnDefs:  [{ targets: [2], type: 'num' }]
   });
}

// ââ Subscription Audit ââââââââââââââââââââââââââââââââââââââââââââââââ

function loadSubscriptions()
{
   fetch('ws/tx-insights/subscriptions', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(renderSubscriptionTable)
      .catch(function(e) { console.error('subscriptions load failed', e); });
}

function renderSubscriptionTable(data)
{
   if ($.fn.DataTable.isDataTable('#ins-subs-table'))
      $('#ins-subs-table').DataTable().destroy();

   if (!data.length)
   {
      document.getElementById('ins-subs-summary').innerHTML =
         '<div style="font-size:12px;color:#94a3b8;">No recurring subscriptions detected.</div>';
      document.getElementById('ins-subs-tbody').innerHTML  = '';
      document.getElementById('ins-subs-tfoot').innerHTML  = '';
      return;
   }

   var totalAnnual = data.reduce(function(s, d) { return s + d.projectedAnnual; }, 0);
   document.getElementById('ins-subs-summary').innerHTML =
      '<div style="font-size:12px;color:#64748b;">'
    + '<strong style="color:#1e2738;">' + data.length + '</strong> likely subscription'
    + (data.length !== 1 ? 's' : '') + ' identified â estimated total '
    + '<strong style="color:#ef4444;">' + fmt(totalAnnual) + ' / year</strong></div>';

   var html = '';
   data.forEach(function(d)
   {
      var costColor = d.projectedAnnual >= 1000 ? '#ef4444'
                    : d.projectedAnnual >= 500  ? '#f97316'
                    :                             '#1e2738';
      html += '<tr>'
            + '<td>' + escHtml(d.narrative) + '</td>'
            + '<td>' + escHtml(d.category)  + '</td>'
            + '<td class="text-center">' + d.occurrenceCount + '</td>'
            + '<td class="text-center" style="color:#64748b;">~' + d.impliedInterval.toFixed(0) + ' days</td>'
            + '<td class="text-end" data-order="' + d.avgAmount + '">' + fmt(d.avgAmount) + '</td>'
            + '<td class="text-end" data-order="' + d.projectedAnnual + '" style="font-weight:600;color:' + costColor + ';">'
            +    fmt(d.projectedAnnual)
            + '</td>'
            + '</tr>';
   });
   document.getElementById('ins-subs-tbody').innerHTML = html;

   document.getElementById('ins-subs-tfoot').innerHTML =
      '<tr class="proj-total">'
    + '<td colspan="5">Total Estimated Annual</td>'
    + '<td class="text-end">' + fmt(totalAnnual) + '</td>'
    + '</tr>';

   $('#ins-subs-table').DataTable({
      pageLength: 25,
      order:      [[5, 'desc']],
      language:   { search: '', searchPlaceholder: 'Filter...' },
      columnDefs: [{ targets: [4, 5], type: 'num' }]
   });
}


function renderMerchantsTable(data)
{
   if ($.fn.DataTable.isDataTable('#ins-merchants-table'))
      $('#ins-merchants-table').DataTable().destroy();

   // Populate category filter dropdown
   var sel  = document.getElementById('merchants-cat-filter');
   var prev = sel.value;
   while (sel.options.length > 1) sel.remove(1);
   var cats = {};
   data.forEach(function(d) { cats[d.category] = true; });
   Object.keys(cats).sort().forEach(function(cat)
   {
      var opt       = document.createElement('option');
      opt.value     = cat;
      opt.textContent = cat;
      sel.appendChild(opt);
   });
   // Restore previous selection if still valid
   sel.value = prev;

   var html = '';
   data.forEach(function(d)
   {
      html += '<tr>'
            + '<td>' + escHtml(d.narrative) + '</td>'
            + '<td>' + escHtml(d.category)  + '</td>'
            + '<td class="text-center">' + d.txCount + '</td>'
            + '<td class="text-end" data-order="' + d.totalDebit + '" style="font-weight:600;">' + fmt(d.totalDebit) + '</td>'
            + '<td class="text-end" data-order="' + d.avgPerTx   + '">' + fmt(d.avgPerTx)   + '</td>'
            + '</tr>';
   });
   document.getElementById('ins-merchants-tbody').innerHTML = html;

   $('#ins-merchants-table').DataTable({
      pageLength: 30,
      order:      [[3, 'desc']],
      language:   { search: '', searchPlaceholder: 'Filter...' },
      columnDefs: [{ targets: [3, 4], type: 'num' }]
   });

   // Re-apply category filter if one was set
   if (sel.value) filterMerchantsTable();
}

function filterMerchantsTable()
{
   if (!$.fn.DataTable.isDataTable('#ins-merchants-table')) return;
   var val = document.getElementById('merchants-cat-filter').value;
   var dt  = $('#ins-merchants-table').DataTable();
   if (val)
      dt.column(1).search('^' + val.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '$', true, false).draw();
   else
      dt.column(1).search('').draw();
}


function populateWhatIfDropdown(data)
{
   var sel = document.getElementById('wi-category');
   while (sel.options.length > 1) sel.remove(1);
   data.forEach(function(d)
   {
      var opt         = document.createElement('option');
      opt.value       = d.category;
      opt.textContent = d.category + '  (avg ' + fmt(d.avgMonthly) + '/mo)';
      sel.appendChild(opt);
   });
   // Reset controls
   document.getElementById('wi-slider').value       = 0;
   document.getElementById('wi-reduction').value    = 0;
   document.getElementById('wi-saving').textContent     = '$0.00';
   document.getElementById('wi-saving-2yr').textContent = '$0.00';
   document.getElementById('wi-avg-label').textContent  = '';
   if (insWhatIfChart) { insWhatIfChart.destroy(); insWhatIfChart = null; }
}

function onWhatIfCategoryChange()
{
   var cat = document.getElementById('wi-category').value;
   if (!cat) return;

   for (var i = 0; i < projData.length; i++)
   {
      if (projData[i].category === cat)
      {
         var maxSlider = Math.ceil(projData[i].avgMonthly / 10) * 10;
         document.getElementById('wi-slider').max         = maxSlider;
         document.getElementById('wi-slider').value       = 0;
         document.getElementById('wi-reduction').value    = 0;
         break;
      }
   }
   renderWhatIf();
}

function syncWhatIfSlider(slider)
{
   document.getElementById('wi-reduction').value = slider.value;
   renderWhatIf();
}

function syncWhatIfInput(input)
{
   document.getElementById('wi-slider').value = input.value;
   renderWhatIf();
}

function renderWhatIf()
{
   var cat       = document.getElementById('wi-category').value;
   var reduction = parseFloat(document.getElementById('wi-reduction').value) || 0;
   if (!cat) return;

   var catData = null;
   for (var i = 0; i < projData.length; i++)
   {
      if (projData[i].category === cat) { catData = projData[i]; break; }
   }
   if (!catData) return;

   var avgMonthly   = catData.avgMonthly;
   var reduced      = Math.max(0, avgMonthly - reduction);
   var annualSaving = reduction * 12;

   document.getElementById('wi-saving').textContent     = fmt(annualSaving);
   document.getElementById('wi-saving-2yr').textContent = fmt(annualSaving * 2);
   document.getElementById('wi-avg-label').textContent  =
      'Current average: ' + fmt(avgMonthly) + '/month  â  reduced to ' + fmt(reduced) + '/month';

   // Build 12 forward month labels from next calendar month
   var today  = new Date();
   var labels = [];
   for (var j = 1; j <= 12; j++)
   {
      var d = new Date(today.getFullYear(), today.getMonth() + j, 1);
      labels.push(MONTH_LABELS[d.getMonth()] + ' ' + d.getFullYear());
   }

   var currentLine = labels.map(function() { return avgMonthly; });
   var reducedLine = labels.map(function() { return reduced;     });

   renderWhatIfChart(labels, currentLine, reducedLine);
}

function renderWhatIfChart(labels, currentLine, reducedLine)
{
   if (insWhatIfChart) { insWhatIfChart.destroy(); insWhatIfChart = null; }

   var ctx = document.getElementById('insWhatIfChart').getContext('2d');
   insWhatIfChart = new Chart(ctx, {
      type: 'line',
      data: {
         labels: labels,
         datasets: [
            {
               label:           'Current trajectory',
               data:            currentLine,
               borderColor:     'rgba(239,68,68,0.85)',
               backgroundColor: 'transparent',
               borderWidth:     2,
               pointRadius:     3,
               tension:         0,
               order:           2
            },
            {
               label:           'With reduction',
               data:            reducedLine,
               borderColor:     'rgba(16,185,129,0.85)',
               backgroundColor: 'rgba(16,185,129,0.12)',
               fill:            '-1',
               borderWidth:     2,
               pointRadius:     3,
               tension:         0,
               order:           1
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
               ticks: { font: { size: 11 }, callback: function(v) { return '$' + v.toFixed(0); } },
               grid:  { color: 'rgba(0,0,0,0.05)' }
            }
         }
      }
   });
}


function loadSubCreep()
{
   fetch('ws/tx-insights/sub-creep', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(renderSubCreepChart)
      .catch(function(e) { console.error('sub-creep load failed', e); });
}

function renderSubCreepChart(data)
{
   if (insSubCreepChart) { insSubCreepChart.destroy(); insSubCreepChart = null; }

   if (!data.length)
   {
      document.getElementById('ins-sub-creep-wrap').innerHTML =
         '<div style="font-size:12px;color:#94a3b8;padding:20px 0;">No recurring subscriptions detected.</div>';
      return;
   }

   // Group by narrative; collect all distinct month keys for the X axis
   var groups    = {};
   var monthKeys = {};

   data.forEach(function(d)
   {
      var key = d.yr * 100 + d.m;
      monthKeys[key] = true;

      if (!groups[d.label])
         groups[d.label] = { points: {} };
      groups[d.label].points[key] = d.monthAvg;
   });

   // Build sorted X axis
   var allKeys = Object.keys(monthKeys).map(Number).sort(function(a, b) { return a - b; });
   var labels  = allKeys.map(function(k)
   {
      return MONTH_LABELS[(k % 100) - 1] + ' ' + Math.floor(k / 100);
   });

   // Build one dataset per subscription narrative
   var narratives = Object.keys(groups);
   var datasets   = narratives.map(function(narr, i)
   {
      var pts  = groups[narr].points;
      var vals = allKeys.map(function(k) { return pts[k] !== undefined ? pts[k] : null; });
      var lbl  = narr.length > 32 ? narr.substring(0, 30) + '\u2026' : narr;
      return {
         label:           lbl,
         data:            vals,
         borderColor:     PALETTE[i % PALETTE.length],
         backgroundColor: 'transparent',
         borderWidth:     2,
         pointRadius:     4,
         pointHoverRadius:6,
         spanGaps:        false,
         tension:         0
      };
   });

   var ctx = document.getElementById('insSubCreepChart').getContext('2d');
   insSubCreepChart = new Chart(ctx, {
      type: 'line',
      data: { labels: labels, datasets: datasets },
      options: {
         responsive: true,
         maintainAspectRatio: false,
         plugins: {
            legend:  { position: 'bottom', labels: { font: { size: 10 }, boxWidth: 12, padding: 6 } },
            tooltip: { callbacks: { label: function(c) { return c.dataset.label + ': ' + fmt(c.parsed.y); } } }
         },
         scales: {
            x: { ticks: { font: { size: 10 }, maxRotation: 45 }, grid: { display: false } },
            y: {
               ticks: { font: { size: 11 }, callback: function(v) { return '$' + v.toFixed(0); } },
               grid:  { color: 'rgba(0,0,0,0.05)' }
            }
         }
      }
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
