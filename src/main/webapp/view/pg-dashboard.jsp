<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "pg-dashboard"); %>
<%@ include file="header.jsp" %>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>

<style>
   .dash-card { background: #1e2738; border-radius: 6px; padding: 16px 18px; color: #e2e8f0; height: 100%; }
   .dash-label { font-size: 10px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; color: #64748b; }
   .dash-value { font-size: 22px; font-weight: 700; margin-top: 4px; }
   .dash-sub   { font-size: 11px; color: #64748b; margin-top: 3px; }
   .gain-pos   { color: #4ade80; }
   .gain-neg   { color: #f87171; }
   .neutral    { color: #e2e8f0; }

   .progress-bar-wrap { background: #2d3748; border-radius: 4px; height: 8px; margin-top: 8px; overflow: hidden; }
   .progress-bar-fill { height: 100%; border-radius: 4px; transition: width 0.5s; }

   .section-title { font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: #64748b; margin-bottom: 10px; }

   #balance-chart-wrapper { position: relative; height: 200px; }

   .quick-link { display: flex; align-items: center; gap: 10px; padding: 10px 14px; border-radius: 6px;
                  background: #f8fafc; border: 1px solid #e9ecef; font-size: 13px; color: #1e2738;
                  text-decoration: none; font-weight: 500; transition: background 0.15s; }
   .quick-link:hover { background: #f1f5f9; color: #1e2738; text-decoration: none; }
   .quick-link i { color: #64748b; width: 16px; text-align: center; }
</style>

<div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
   <h5 class="mb-0">Dashboard</h5>
   <span style="font-size:12px;color:#94a3b8;" id="dash-year-label"></span>
</div>

<!-- Top stat cards -->
<div class="row g-3 mb-4" id="stat-cards">
   <div class="col-6 col-md-3">
      <div class="dash-card">
         <div class="dash-label">Current Balance</div>
         <div class="dash-value neutral" id="d-balance">—</div>
         <div class="dash-sub" id="d-balance-month">loading...</div>
      </div>
   </div>
   <div class="col-6 col-md-3">
      <div class="dash-card">
         <div class="dash-label">YTD Gain / Loss</div>
         <div class="dash-value" id="d-gain">—</div>
         <div class="dash-sub">
            <span id="d-target-lbl">target: —</span>
            <div class="progress-bar-wrap">
               <div class="progress-bar-fill" id="d-target-bar" style="width:0%;background:#3b82f6;"></div>
            </div>
         </div>
      </div>
   </div>
   <div class="col-6 col-md-3">
      <div class="dash-card">
         <div class="dash-label">Daily Discretionary</div>
         <div class="dash-value neutral" id="d-daily">—</div>
         <div class="dash-sub">based on YTD spend</div>
      </div>
   </div>
   <div class="col-6 col-md-3">
      <div class="dash-card">
         <div class="dash-label">Superannuation</div>
         <div class="dash-value neutral" id="d-super">—</div>
         <div class="dash-sub" id="d-super-date">—</div>
      </div>
   </div>
</div>

<div class="row g-3 mb-4">

   <!-- Balance trend chart -->
   <div class="col-lg-8">
      <div class="card shadow-sm h-100">
         <div class="card-body">
            <div class="section-title">Balance Trend — Current Year</div>
            <div id="balance-chart-wrapper"><canvas id="balanceChart"></canvas></div>
         </div>
      </div>
   </div>

   <!-- Quick links + spending snapshot -->
   <div class="col-lg-4">
      <div class="card shadow-sm mb-3">
         <div class="card-body">
            <div class="section-title">Quick Links</div>
            <div class="d-flex flex-column gap-2">
               <a href="/budgetapi?rq=pg-monthly" class="quick-link"><i class="fa-solid fa-calendar-day"></i> Monthly Entry</a>
               <a href="/budgetapi?rq=pg-yearly" class="quick-link"><i class="fa-solid fa-calendar"></i> Yearly Overview</a>
               <a href="/budgetapi?rq=pg-super" class="quick-link"><i class="fa-solid fa-chart-line"></i> Superannuation</a>
               <a href="/budgetapi?rq=pg-worksheet" class="quick-link"><i class="fa-solid fa-file-lines"></i> Worksheet</a>
               <a href="/budgetapi?rq=pg-fixed-input" class="quick-link"><i class="fa-solid fa-thumbtack"></i> Fixed Inputs</a>
            </div>
         </div>
      </div>

      <div class="card shadow-sm">
         <div class="card-body">
            <div class="section-title">Spending Snapshot</div>
            <div style="display:flex;flex-direction:column;gap:8px;" id="spend-snapshot">
               <div style="font-size:12px;color:#94a3b8;">Loading...</div>
            </div>
         </div>
      </div>
   </div>

</div>

<!-- Second row: current month summary + next steps -->
<div class="row g-3">
   <div class="col-lg-6">
      <div class="card shadow-sm">
         <div class="card-body">
            <div class="section-title">Current Month</div>
            <div id="current-month-detail" style="font-size:13px;color:#94a3b8;">Loading...</div>
         </div>
      </div>
   </div>
   <div class="col-lg-6">
      <div class="card shadow-sm">
         <div class="card-body">
            <div class="section-title">Open Months</div>
            <div id="open-months-list" style="font-size:13px;color:#94a3b8;">Loading...</div>
         </div>
      </div>
   </div>
</div>

<script>
var MONTH_NAMES = ['July','August','September','October','November','December',
                   'January','February','March','April','May','June'];

var balanceChart = null;

document.addEventListener('DOMContentLoaded', function()
{
   loadDashboard();
});

function loadDashboard()
{
   // Load years, super, and fixed input in parallel
   Promise.all([
      fetch('ws/years',       { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/super',       { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
      fetch('ws/fixed-input', { credentials: 'same-origin' }).then(function(r) { return r.json(); })
   ])
   .then(function(results)
   {
      var years   = results[0];
      var superData = results[1];
      var fixedItems = results[2];

      if (years.length === 0) return;
      var currentYear = years[0];

      document.getElementById('dash-year-label').textContent = currentYear.year_label;

      // Super stat
      if (superData.length > 0)
      {
         var latest = superData[superData.length - 1];
         document.getElementById('d-super').textContent      = fmt(latest.balance_amount);
         document.getElementById('d-super-date').textContent = fmtDate(latest.balance_date);
      }

      // Fixed yearly total
      var fixedYearly = fixedItems
         .filter(function(i) { return i.is_active; })
         .reduce(function(sum, i)
         {
            var mult = i.frequency === 'Monthly' ? 12 : i.frequency === 'Quarterly' ? 4 : i.frequency === 'Weekly' ? 52 : 1;
            return sum + i.item_cost * mult;
         }, 0);

      // Load months + entries for current year
      return fetch('ws/months?year_id=' + currentYear.id, { credentials: 'same-origin' })
         .then(function(r) { return r.json(); })
         .then(function(months)
         {
            var entryFetches = months.map(function(m)
            {
               return fetch('ws/entries?month_id=' + m.id, { credentials: 'same-origin' })
                  .then(function(r) { return r.json(); })
                  .then(function(ents) { return { month: m, entries: ents }; });
            });
            return Promise.all(entryFetches);
         })
         .then(function(monthData)
         {
            renderDashboard(currentYear, monthData, fixedYearly);
         });
   })
   .catch(function(e)
   {
      console.error('Dashboard load failed', e);
   });
}

function renderDashboard(year, monthData, fixedYearly)
{
   // Compute running balances
   var balance      = year.opening_balance;
   var totalDebit   = 0;
   var chartLabels  = ['Start'];
   var chartValues  = [year.opening_balance];
   var currentMonthNo = getCurrentFYMonth(); // 1-12

   monthData.forEach(function(md, idx)
   {
      var debits  = md.entries.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      var credits = md.entries.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      totalDebit += debits;
      balance    = balance - debits + credits;

      // Only include months up to current for chart
      if (md.month.month_number <= currentMonthNo)
      {
         chartLabels.push(MONTH_NAMES[idx]);
         chartValues.push(balance);
      }
   });

   var gain  = balance - year.opening_balance;
   var disc  = Math.max(0, totalDebit - fixedYearly);

   // Stats
   document.getElementById('d-balance').textContent      = fmt(balance);
   document.getElementById('d-balance-month').textContent = 'after ' + MONTH_NAMES[currentMonthNo - 1];

   var gainEl = document.getElementById('d-gain');
   gainEl.textContent = (gain >= 0 ? '+' : '') + fmt(gain);
   gainEl.className = 'dash-value ' + (gain >= 0 ? 'gain-pos' : 'gain-neg');

   // Target progress bar
   var targetPct = year.target_gain > 0 ? Math.min(100, Math.max(0, (gain / year.target_gain) * 100)) : 0;
   document.getElementById('d-target-lbl').textContent = 'target: ' + fmt(year.target_gain);
   document.getElementById('d-target-bar').style.width = targetPct.toFixed(0) + '%';
   document.getElementById('d-target-bar').style.background = gain >= year.target_gain ? '#4ade80' : '#3b82f6';

   document.getElementById('d-daily').textContent = fmt(disc / 365);

   // Spending snapshot
   var snapshotHtml =
      spRow('Fixed required', fmt(fixedYearly)) +
      spRow('Total spent (YTD)', fmt(totalDebit)) +
      spRow('Discretionary (YTD)', fmt(disc)) +
      spRow('Disc. / month', fmt(disc / 12)) +
      spRow('Disc. / day', fmt(disc / 365));
   document.getElementById('spend-snapshot').innerHTML = snapshotHtml;

   // Current month detail
   var cmData = monthData.find(function(md) { return md.month.month_number === currentMonthNo; });
   if (cmData)
   {
      var cmDebits  = cmData.entries.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      var cmCredits = cmData.entries.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      var cmNet     = cmCredits - cmDebits;
      var cmEntries = cmData.entries.length;
      document.getElementById('current-month-detail').innerHTML =
         '<strong>' + MONTH_NAMES[currentMonthNo - 1] + '</strong>' +
         '<div style="margin-top:8px;">' +
         spRow('Debits',  '<span class="text-danger">' + fmt(cmDebits) + '</span>') +
         spRow('Credits', '<span class="text-success">' + fmt(cmCredits) + '</span>') +
         spRow('Net',     '<span class="' + (cmNet >= 0 ? 'text-success' : 'text-danger') + '">' + (cmNet >= 0 ? '+' : '') + fmt(cmNet) + '</span>') +
         spRow('Entries', cmEntries + ' line item' + (cmEntries !== 1 ? 's' : '')) +
         spRow('Status',  cmData.month.is_reconciled ?
            '<span style="background:#dcfce7;color:#166534;padding:1px 7px;border-radius:3px;font-size:11px;font-weight:700;">Reconciled</span>' :
            '<span style="background:#f1f5f9;color:#94a3b8;padding:1px 7px;border-radius:3px;font-size:11px;font-weight:700;">Open</span>') +
         '</div>' +
         '<a href="/budgetapi?rq=pg-monthly" class="btn btn-sm btn-outline-primary mt-3" style="font-size:12px;">Open Monthly Entry</a>';
   }

   // Open months list
   var openMonths = monthData.filter(function(md) { return !md.month.is_reconciled && md.month.month_number <= currentMonthNo; });
   if (openMonths.length === 0)
   {
      document.getElementById('open-months-list').innerHTML =
         '<span style="color:#16a34a;font-size:13px;"><i class="fa-solid fa-check me-1"></i>All months to date are reconciled.</span>';
   }
   else
   {
      var html = '<div style="display:flex;flex-direction:column;gap:6px;">';
      openMonths.forEach(function(md)
      {
         var debits  = md.entries.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
         var credits = md.entries.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
         html += '<a href="/budgetapi?rq=pg-monthly&month=' + md.month.month_number + '" ' +
            'style="display:flex;justify-content:space-between;align-items:center;padding:8px 12px;background:#fff8f8;border:1px solid #fee2e2;border-radius:4px;text-decoration:none;color:#1e2738;">' +
            '<span style="font-weight:600;">' + MONTH_NAMES[md.month.month_number - 1] + '</span>' +
            '<span style="font-size:12px;color:#64748b;">' + md.entries.length + ' entries &bull; net ' +
               '<span class="' + ((credits-debits) >= 0 ? 'text-success' : 'text-danger') + '">' +
               (credits-debits >= 0 ? '+' : '') + fmt(credits-debits) + '</span></span>' +
            '</a>';
      });
      html += '</div>';
      document.getElementById('open-months-list').innerHTML = html;
   }

   // Chart
   renderBalanceChart(chartLabels, chartValues);
}

function renderBalanceChart(labels, values)
{
   if (balanceChart) { balanceChart.destroy(); balanceChart = null; }
   var ctx = document.getElementById('balanceChart').getContext('2d');
   balanceChart = new Chart(ctx, {
      type: 'line',
      data: {
         labels: labels,
         datasets: [{
            data: values,
            borderColor: '#3b82f6',
            backgroundColor: 'rgba(59,130,246,0.08)',
            borderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 6,
            tension: 0.2,
            fill: true
         }]
      },
      options: {
         responsive: true,
         maintainAspectRatio: false,
         plugins: {
            legend: { display: false },
            tooltip: { callbacks: { label: function(c) { return fmt(c.parsed.y); } } }
         },
         scales: {
            x: { ticks: { font: { size: 11 } }, grid: { display: false } },
            y: {
               ticks: { font: { size: 11 }, callback: function(v) { return '$' + (v/1000).toFixed(0) + 'k'; } },
               grid: { color: 'rgba(0,0,0,0.05)' }
            }
         }
      }
   });
}

function getCurrentFYMonth()
{
   // FY month 1=July ... 12=June
   var m = new Date().getMonth(); // 0=Jan
   return m >= 6 ? m - 5 : m + 7; // Jul=1, Aug=2 ... Jun=12
}

function spRow(label, value)
{
   return '<div style="display:flex;justify-content:space-between;font-size:12px;padding:4px 0;border-bottom:1px solid #f1f5f9;">' +
      '<span style="color:#64748b;">' + label + '</span>' +
      '<span style="font-weight:600;color:#1e2738;">' + value + '</span>' +
      '</div>';
}

function fmt(n)
{
   return '$' + Number(n).toLocaleString('en-AU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtDate(str)
{
   var d = new Date(str + 'T00:00:00');
   return d.getDate() + ' ' + ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.getMonth()] + ' ' + d.getFullYear();
}
</script>

<%@ include file="footer.jsp" %>
