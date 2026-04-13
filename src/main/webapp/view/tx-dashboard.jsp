<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "tx-dashboard"); %>
<%@ include file="header.jsp" %>

<style>
   .tx-stat-card  { background: #1e2738; border-radius: 6px; padding: 16px 18px; color: #e2e8f0; height: 100%; }
   .tx-stat-label { font-size: 10px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; color: #64748b; }
   .tx-stat-value { font-size: 22px; font-weight: 700; margin-top: 4px; color: #e2e8f0; }
   .tx-stat-sub   { font-size: 11px; color: #64748b; margin-top: 3px; }
   .gain-pos      { color: #4ade80; }
   .gain-neg      { color: #f87171; }
   .section-title { font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: #64748b; margin-bottom: 10px; }
   .chart-wrap    { position: relative; height: 260px; }
   .data-row      { display: flex; justify-content: space-between; align-items: center;
                    font-size: 12px; padding: 5px 0; border-bottom: 1px solid #f1f5f9; }
   .data-row:last-child { border-bottom: none; }
</style>

<div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
   <h5 class="mb-0">Transaction Dashboard</h5>
   <a href="/budgetapi?rq=tx-explore" style="font-size:12px;" class="btn btn-sm btn-outline-secondary">
      <i class="fa-solid fa-magnifying-glass me-1"></i>Explorer
   </a>
</div>

<!-- ── Stat cards ─────────────────────────────────────────────────────── -->
<div class="row g-3 mb-4">
   <div class="col-6 col-md-3">
      <div class="tx-stat-card">
         <div class="tx-stat-label">Total Spend</div>
         <div class="tx-stat-value" id="tx-total-debit">—</div>
         <div class="tx-stat-sub"  id="tx-year-sub">loading...</div>
      </div>
   </div>
   <div class="col-6 col-md-3">
      <div class="tx-stat-card">
         <div class="tx-stat-label">vs Last Year</div>
         <div class="tx-stat-value" id="tx-vs-last">—</div>
         <div class="tx-stat-sub"  id="tx-vs-last-sub">—</div>
      </div>
   </div>
   <div class="col-6 col-md-3">
      <div class="tx-stat-card">
         <div class="tx-stat-label">Transactions</div>
         <div class="tx-stat-value" id="tx-count">—</div>
         <div class="tx-stat-sub"  id="tx-count-sub">this year</div>
      </div>
   </div>
   <div class="col-6 col-md-3">
      <div class="tx-stat-card">
         <div class="tx-stat-label">Top Category</div>
         <div class="tx-stat-value" id="tx-top-cat" style="font-size:15px;line-height:1.3;">—</div>
         <div class="tx-stat-sub"  id="tx-top-cat-sub">—</div>
      </div>
   </div>
</div>

<!-- ── Charts ─────────────────────────────────────────────────────────── -->
<div class="row g-3 mb-4">
   <div class="col-lg-7">
      <div class="card shadow-sm h-100">
         <div class="card-body">
            <div class="section-title">Monthly Spend — <span id="tx-monthly-year">...</span></div>
            <div class="chart-wrap"><canvas id="txMonthlyChart"></canvas></div>
         </div>
      </div>
   </div>
   <div class="col-lg-5">
      <div class="card shadow-sm h-100">
         <div class="card-body">
            <div class="section-title">Spend by Category</div>
            <div class="chart-wrap"><canvas id="txCategoryChart"></canvas></div>
         </div>
      </div>
   </div>
</div>

<!-- ── Summary tables ─────────────────────────────────────────────────── -->
<div class="row g-3">
   <div class="col-lg-6">
      <div class="card shadow-sm">
         <div class="card-body">
            <div class="section-title">Monthly Breakdown</div>
            <div id="tx-monthly-table"><div style="font-size:12px;color:#94a3b8;">Loading...</div></div>
         </div>
      </div>
   </div>
   <div class="col-lg-6">
      <div class="card shadow-sm">
         <div class="card-body">
            <div class="section-title">Category Totals</div>
            <div id="tx-category-table"><div style="font-size:12px;color:#94a3b8;">Loading...</div></div>
         </div>
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

var txMonthlyChart  = null;
var txCategoryChart = null;

document.addEventListener('DOMContentLoaded', loadTxDashboard);

function loadTxDashboard()
{
   fetch('ws/tx-data/years', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(years)
      {
         if (!years.length)
         {
            document.getElementById('tx-year-sub').textContent = 'No transaction data found.';
            return;
         }
         var year = years[0];
         document.getElementById('tx-monthly-year').textContent = year;

         return Promise.all([
            fetch('ws/tx-data/overview',           { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
            fetch('ws/tx-data/monthly/' + year,    { credentials: 'same-origin' }).then(function(r) { return r.json(); }),
            fetch('ws/tx-data/categories/' + year, { credentials: 'same-origin' }).then(function(r) { return r.json(); })
         ]).then(function(results)
         {
            renderStatCards(results[0], results[2]);
            renderMonthlyChart(results[1]);
            renderCategoryChart(results[2]);
            renderMonthlyTable(results[1]);
            renderCategoryTable(results[2]);
         });
      })
      .catch(function(e) { console.error('tx-dashboard load failed', e); });
}

function renderStatCards(overview, categories)
{
   // Total spend + vs last year
   if (overview.length > 0)
   {
      var cur = overview[0];
      document.getElementById('tx-total-debit').textContent = fmt(cur.totalDebit);
      document.getElementById('tx-year-sub').textContent    = cur.year + ' total spend';
      document.getElementById('tx-count').textContent       = cur.rowCount;
      document.getElementById('tx-count-sub').textContent   = cur.year + ' transactions';

      if (overview.length > 1)
      {
         var prev = overview[1];
         var diff = cur.totalDebit - prev.totalDebit;
         var pct  = prev.totalDebit > 0 ? (diff / prev.totalDebit * 100) : 0;
         var el   = document.getElementById('tx-vs-last');
         el.textContent = (diff >= 0 ? '+' : '') + fmt(diff);
         el.className   = 'tx-stat-value ' + (diff >= 0 ? 'gain-neg' : 'gain-pos'); // more spend = red
         document.getElementById('tx-vs-last-sub').textContent =
            (pct >= 0 ? '+' : '') + pct.toFixed(1) + '% vs ' + prev.year;
      }
      else
      {
         document.getElementById('tx-vs-last-sub').textContent = 'no prior year data';
      }
   }

   // Top category
   if (categories.length > 0)
   {
      var top = categories[0];
      document.getElementById('tx-top-cat').textContent     = top.category;
      document.getElementById('tx-top-cat-sub').textContent = fmt(top.totalDebit) + ' · ' + top.rowCount + ' tx';
   }
}

function renderMonthlyChart(monthly)
{
   if (txMonthlyChart) { txMonthlyChart.destroy(); txMonthlyChart = null; }
   if (!monthly.length) return;

   var labels  = monthly.map(function(m) { return MONTH_LABELS[m.month - 1]; });
   var debits  = monthly.map(function(m) { return m.totalDebit; });
   var credits = monthly.map(function(m) { return m.totalCredit; });

   var ctx = document.getElementById('txMonthlyChart').getContext('2d');
   txMonthlyChart = new Chart(ctx, {
      type: 'bar',
      data: {
         labels: labels,
         datasets: [
            {
               label:           'Debit',
               data:            debits,
               backgroundColor: 'rgba(239,68,68,0.75)',
               borderRadius:    3
            },
            {
               label:           'Credit',
               data:            credits,
               backgroundColor: 'rgba(16,185,129,0.75)',
               borderRadius:    3
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

function renderCategoryChart(categories)
{
   if (txCategoryChart) { txCategoryChart.destroy(); txCategoryChart = null; }
   if (!categories.length) return;

   var top    = categories.slice(0, 10);
   var other  = categories.slice(10).reduce(function(s, c) { return s + c.totalDebit; }, 0);
   var labels = top.map(function(c) { return c.category; });
   var values = top.map(function(c) { return c.totalDebit; });
   var colors = top.map(function(_, i) { return PALETTE[i % PALETTE.length]; });

   if (other > 0.005)
   {
      labels.push('Other');
      values.push(Math.round(other * 100) / 100);
      colors.push('#94a3b8');
   }

   var ctx = document.getElementById('txCategoryChart').getContext('2d');
   txCategoryChart = new Chart(ctx, {
      type: 'doughnut',
      data: {
         labels: labels,
         datasets: [{
            data:            values,
            backgroundColor: colors,
            borderWidth:     2,
            borderColor:     '#fff'
         }]
      },
      options: {
         responsive: true,
         maintainAspectRatio: false,
         plugins: {
            legend:  { position: 'right', labels: { font: { size: 10 }, boxWidth: 12, padding: 6 } },
            tooltip: { callbacks: { label: function(c) { return c.label + ': ' + fmt(c.parsed); } } }
         }
      }
   });
}

function renderMonthlyTable(monthly)
{
   if (!monthly.length)
   {
      document.getElementById('tx-monthly-table').innerHTML =
         '<div style="font-size:12px;color:#94a3b8;">No data.</div>';
      return;
   }

   var html = '';
   monthly.forEach(function(m)
   {
      html += '<div class="data-row">'
            + '<span style="color:#64748b;font-weight:600;min-width:30px;">' + MONTH_LABELS[m.month - 1] + '</span>'
            + '<span style="color:#ef4444;">' + fmt(m.totalDebit) + '</span>'
            + '<span style="color:#10b981;">' + fmt(m.totalCredit) + '</span>'
            + '<span style="color:#94a3b8;font-size:11px;">' + m.rowCount + ' tx</span>'
            + '</div>';
   });
   document.getElementById('tx-monthly-table').innerHTML = html;
}

function renderCategoryTable(categories)
{
   if (!categories.length)
   {
      document.getElementById('tx-category-table').innerHTML =
         '<div style="font-size:12px;color:#94a3b8;">No data.</div>';
      return;
   }

   var total = categories.reduce(function(s, c) { return s + c.totalDebit; }, 0);
   var html  = '';
   categories.forEach(function(c, i)
   {
      var pct = total > 0 ? (c.totalDebit / total * 100) : 0;
      html += '<div class="data-row">'
            + '<span style="width:10px;height:10px;border-radius:2px;display:inline-block;flex-shrink:0;margin-right:7px;background:' + PALETTE[i % PALETTE.length] + ';"></span>'
            + '<span style="flex:1;color:#1e2738;">'           + escHtml(c.category)  + '</span>'
            + '<span style="font-weight:600;color:#1e2738;white-space:nowrap;margin-left:8px;">' + fmt(c.totalDebit) + '</span>'
            + '<span style="color:#94a3b8;font-size:11px;width:34px;text-align:right;">'         + pct.toFixed(0) + '%</span>'
            + '</div>';
   });
   document.getElementById('tx-category-table').innerHTML = html;
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
