<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "pg-monthly"); %>
<%@ include file="header.jsp" %>

<style>
   /* Year / Month selector */
   .yr-btn { font-size: 12px; font-weight: 600; padding: 5px 14px; border-radius: 4px; cursor: pointer; border: 1px solid #dee2e6; background: #fff; color: #64748b; }
   .yr-btn.active { background: #1e2738; color: #e2e8f0; border-color: #1e2738; }

   .month-tabs { display: flex; flex-wrap: wrap; gap: 3px; margin-bottom: 0; }
   .month-tab  { font-size: 12px; font-weight: 600; padding: 6px 13px; border-radius: 4px 4px 0 0;
                  cursor: pointer; border: 1px solid transparent; border-bottom: none; color: #64748b; }
   .month-tab.active    { background: #fff; border-color: #dee2e6; color: #1e2738; }
   .month-tab:hover:not(.active) { background: #f1f5f9; }
   .month-tab.reconciled::after { content: ' \2713'; font-size: 10px; color: #16a34a; }

   /* Entry tables */
   .entry-th { background: #1e2738; color: #94a3b8; font-size: 11px; font-weight: 600;
               letter-spacing: 0.05em; text-transform: uppercase; border: none; padding: 8px 10px; }
   .entry-td { vertical-align: middle; padding: 7px 10px; border-color: #e9ecef; font-size: 13px; }
   .entry-row:hover { background: #f8fafc; }

   .section-lbl { font-size: 11px; font-weight: 700; letter-spacing: 0.07em; text-transform: uppercase;
                   color: #64748b; margin: 16px 0 6px; }

   /* Balance ribbon */
   .balance-ribbon { display: flex; gap: 20px; align-items: center; flex-wrap: wrap;
                      background: #1e2738; border-radius: 6px; padding: 12px 18px; margin-bottom: 16px; }
   .br-item .br-label { font-size: 10px; font-weight: 700; letter-spacing: 0.07em; text-transform: uppercase; color: #64748b; }
   .br-item .br-value { font-size: 17px; font-weight: 700; color: #e2e8f0; margin-top: 2px; }

   /* Right summary panel */
   .summary-panel { background: #f8fafc; border: 1px solid #e9ecef; border-radius: 6px; padding: 16px; }
   .sp-row { display: flex; justify-content: space-between; align-items: baseline;
              font-size: 12px; padding: 5px 0; border-bottom: 1px solid #f1f5f9; }
   .sp-row:last-child { border-bottom: none; }
   .sp-row .sp-lbl { color: #64748b; }
   .sp-row .sp-val { font-weight: 600; color: #1e2738; }
   .sp-section-hdr { font-size: 10px; font-weight: 700; letter-spacing: 0.07em; text-transform: uppercase;
                      color: #94a3b8; margin: 12px 0 4px; }
   .gain-pos { color: #16a34a !important; }
   .gain-neg { color: #dc2626 !important; }

   .cat-badge { display: inline-block; font-size: 10px; font-weight: 600; padding: 2px 7px;
                 border-radius: 3px; background: #f1f5f9; color: #64748b; }
   .actual-dot { display: inline-block; width: 7px; height: 7px; border-radius: 50%; margin-right: 4px; }
   .actual-dot.yes { background: #16a34a; }
   .actual-dot.no  { background: #94a3b8; }
</style>

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
   <h5 class="mb-0">Monthly Budget</h5>
   <div class="d-flex gap-2 align-items-center" id="year-selector"></div>
</div>

<div class="month-tabs mb-0" id="month-tabs"></div>

<div class="card shadow-sm" style="border-top-left-radius:0;" id="month-content">
   <div class="card-body">
      <div class="row g-3">

         <!-- LEFT: entries -->
         <div class="col-lg-8">

            <!-- Balance ribbon -->
            <div class="balance-ribbon" id="balance-ribbon">
               <div class="br-item"><div class="br-label">Opening</div><div class="br-value" id="br-open">--</div></div>
               <div class="br-item"><div class="br-label">Debits</div><div class="br-value" id="br-debits" style="color:#f87171;">--</div></div>
               <div class="br-item"><div class="br-label">Credits</div><div class="br-value" id="br-credits" style="color:#4ade80;">--</div></div>
               <div class="br-item"><div class="br-label">Net</div><div class="br-value" id="br-net">--</div></div>
               <div class="br-item"><div class="br-label">Closing</div><div class="br-value" id="br-close">--</div></div>
               <div class="ms-auto d-flex gap-2 align-items-center">
                  <span id="reconcile-badge"></span>
                  <button class="btn btn-sm btn-outline-secondary" style="font-size:11px;" onclick="toggleReconcile()">
                     <i class="fa-solid fa-check"></i> <span id="reconcile-btn-lbl">Mark Reconciled</span>
                  </button>
               </div>
            </div>

            <!-- DEBITS -->
            <div class="section-lbl"><i class="fa-solid fa-arrow-up text-danger me-1"></i>Debits (Money Out)</div>
            <table class="table mb-2">
               <thead>
                  <tr>
                     <th class="entry-th">Description</th>
                     <th class="entry-th">Category</th>
                     <th class="entry-th">Amount</th>
                     <th class="entry-th" style="width:30px;" title="Actual / Estimate"><i class="fa-solid fa-circle-dot"></i></th>
                     <th class="entry-th" style="width:70px;"></th>
                  </tr>
               </thead>
               <tbody id="rows-debit">
                  <tr><td colspan="5" class="text-muted text-center py-3" style="font-size:12px;">No debit entries.</td></tr>
               </tbody>
               <tfoot>
                  <tr style="background:#fff8f8;">
                     <td colspan="2" class="entry-td" style="font-weight:600;font-size:12px;">Total Debits</td>
                     <td class="entry-td" style="font-weight:700;color:#dc2626;" id="debit-total">$0.00</td>
                     <td colspan="2"></td>
                  </tr>
               </tfoot>
            </table>
            <button class="btn btn-sm btn-outline-danger mb-4" style="font-size:12px;" onclick="openAddEntry('DEBIT')">
               <i class="fa-solid fa-plus"></i> Add Debit
            </button>

            <!-- CREDITS -->
            <div class="section-lbl"><i class="fa-solid fa-arrow-down text-success me-1"></i>Credits (Money In)</div>
            <table class="table mb-2">
               <thead>
                  <tr>
                     <th class="entry-th">Description</th>
                     <th class="entry-th">Category</th>
                     <th class="entry-th">Amount</th>
                     <th class="entry-th" style="width:30px;" title="Actual / Estimate"><i class="fa-solid fa-circle-dot"></i></th>
                     <th class="entry-th" style="width:70px;"></th>
                  </tr>
               </thead>
               <tbody id="rows-credit">
                  <tr><td colspan="5" class="text-muted text-center py-3" style="font-size:12px;">No credit entries.</td></tr>
               </tbody>
               <tfoot>
                  <tr style="background:#f0fdf4;">
                     <td colspan="2" class="entry-td" style="font-weight:600;font-size:12px;">Total Credits</td>
                     <td class="entry-td" style="font-weight:700;color:#16a34a;" id="credit-total">$0.00</td>
                     <td colspan="2"></td>
                  </tr>
               </tfoot>
            </table>
            <button class="btn btn-sm btn-outline-success mb-2" style="font-size:12px;" onclick="openAddEntry('CREDIT')">
               <i class="fa-solid fa-plus"></i> Add Credit
            </button>

         </div><!-- /col-left -->

         <!-- RIGHT: summary panel -->
         <div class="col-lg-4">
            <div class="summary-panel">
               <div style="font-size:12px;font-weight:700;color:#1e2738;margin-bottom:8px;">Year to Date Summary</div>

               <div class="sp-section-hdr">Balance</div>
               <div class="sp-row"><span class="sp-lbl">Year opening</span><span class="sp-val" id="sp-yr-open">--</span></div>
               <div class="sp-row"><span class="sp-lbl">Projected year close</span><span class="sp-val" id="sp-yr-close">--</span></div>
               <div class="sp-row"><span class="sp-lbl">Actual gain / loss</span><span class="sp-val" id="sp-yr-gain">--</span></div>

               <div class="sp-section-hdr">Target</div>
               <div class="sp-row"><span class="sp-lbl">Target gain</span><span class="sp-val" id="sp-target">--</span></div>
               <div class="sp-row"><span class="sp-lbl">On target +/−</span><span class="sp-val" id="sp-on-target">--</span></div>

               <div class="sp-section-hdr">Spending</div>
               <div class="sp-row"><span class="sp-lbl">Fixed required</span><span class="sp-val" id="sp-fixed">--</span></div>
               <div class="sp-row"><span class="sp-lbl">Total spend (yr)</span><span class="sp-val" id="sp-total-spend">--</span></div>
               <div class="sp-row"><span class="sp-lbl">Discretionary (yr)</span><span class="sp-val" id="sp-disc-yr">--</span></div>
               <div class="sp-row"><span class="sp-lbl">Disc. per month</span><span class="sp-val" id="sp-disc-mo">--</span></div>
               <div class="sp-row"><span class="sp-lbl">Disc. per day</span><span class="sp-val" id="sp-disc-day">--</span></div>

               <div class="sp-section-hdr">Interest</div>
               <div class="sp-row"><span class="sp-lbl">Interest accrued</span><span class="sp-val" id="sp-interest">--</span></div>
               <div class="sp-row"><span class="sp-lbl">ATO refund est.</span><span class="sp-val" id="sp-refund">--</span></div>
            </div>
         </div>

      </div><!-- /row -->
   </div>
</div>

<!-- ADD / EDIT ENTRY MODAL -->
<div class="modal fade" id="entryModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
         <div class="modal-header">
            <h6 class="modal-title" id="entryModalTitle">Add Entry</h6>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
         </div>
         <div class="modal-body">
            <input type="hidden" id="ent-id" value="">
            <input type="hidden" id="ent-type" value="">
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Description</label>
               <input type="text" class="form-control form-control-sm" id="ent-desc" placeholder="e.g. CC payment, Wages">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Category</label>
               <select class="form-select form-select-sm" id="ent-cat"></select>
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Amount ($)</label>
               <input type="number" class="form-control form-control-sm" id="ent-amount" min="0" step="0.01" placeholder="0.00">
            </div>
            <div class="mb-2">
               <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="ent-actual">
                  <label class="form-check-label" style="font-size:13px;" for="ent-actual">Actual (uncheck = estimate)</label>
               </div>
            </div>
            <div id="ent-error" class="text-danger" style="font-size:12px;display:none;"></div>
         </div>
         <div class="modal-footer">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary btn-sm" onclick="saveEntry()">Save</button>
         </div>
      </div>
   </div>
</div>

<!-- DELETE CONFIRM -->
<div class="modal fade" id="entDeleteModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered modal-sm">
      <div class="modal-content">
         <div class="modal-body text-center py-4">
            <i class="fa-solid fa-triangle-exclamation text-warning" style="font-size:28px;"></i>
            <p class="mt-3 mb-1" style="font-size:14px;">Delete <strong id="ent-del-desc"></strong>?</p>
         </div>
         <div class="modal-footer justify-content-center">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-danger btn-sm" onclick="confirmDeleteEntry()">Delete</button>
         </div>
      </div>
   </div>
</div>

<script>
var years        = [];
var months       = [];
var entries      = [];
var fixedYearly  = 0;
var allYearMonths   = {};
var allYearEntries  = {};
var interestRecords = [];

var activeYearId  = -1;
var activeMonthNo = 1;
var activeMonthId = -1;

var MONTH_NAMES = ['July','August','September','October','November','December',
                   'January','February','March','April','May','June'];

var DEBIT_CATS  = ['cc_payment','mortgage','misc','other'];
var CREDIT_CATS = ['wages','rent','interest','dividend','ato_refund','other'];

var entryModal, entDeleteModal;
var deleteEntryId = -1;

document.addEventListener('DOMContentLoaded', function()
{
   entryModal     = new bootstrap.Modal(document.getElementById('entryModal'));
   entDeleteModal = new bootstrap.Modal(document.getElementById('entDeleteModal'));

   var params     = new URLSearchParams(window.location.search);
   var initYear   = params.get('year_id') ? parseInt(params.get('year_id')) : -1;
   var initMonth  = params.get('month')   ? parseInt(params.get('month'))   : 1;

   loadFixed().then(function() { loadYears(initYear, initMonth); });
});

function loadFixed()
{
   return fetch('ws/fixed-input', { credentials: 'same-origin' })
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

function loadYears(initYear, initMonth)
{
   fetch('ws/years', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         years = data;
         renderYearSelector();
         if (years.length === 0) return;
         var startYearId = (initYear > 0 && years.find(function(y) { return y.id === initYear; }))
            ? initYear : years[0].id;
         selectYear(startYearId, initMonth || 1);
      });
}

function renderYearSelector()
{
   var sel = document.getElementById('year-selector');
   sel.innerHTML = '';
   years.forEach(function(y)
   {
      var btn = document.createElement('button');
      btn.className = 'yr-btn' + (y.id === activeYearId ? ' active' : '');
      btn.textContent = y.year_label;
      btn.onclick = (function(yid) { return function() { selectYear(yid, 1); }; })(y.id);
      sel.appendChild(btn);
   });
}

function selectYear(yearId, monthNo)
{
   activeYearId  = yearId;
   activeMonthNo = monthNo || 1;
   renderYearSelector();

   if (allYearMonths[yearId])
   {
      months = allYearMonths[yearId];
      renderMonthTabs();
      selectMonth(activeMonthNo);
      return;
   }

   fetch('ws/months?year_id=' + yearId, { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         allYearMonths[yearId] = data;
         months = data;
         renderMonthTabs();

         var fetches = months.map(function(m)
         {
            return fetch('ws/entries?month_id=' + m.id, { credentials: 'same-origin' })
               .then(function(r) { return r.json(); })
               .then(function(ents) { allYearEntries[m.id] = ents; });
         });

         var yearLabel = years.find(function(y) { return y.id === yearId; }).year_label;
         var intFetch  = fetch('ws/interest?year=' + encodeURIComponent(yearLabel), { credentials: 'same-origin' })
            .then(function(r) { return r.json(); })
            .then(function(recs) { interestRecords = recs; });

         return Promise.all(fetches.concat([intFetch]));
      })
      .then(function() { selectMonth(activeMonthNo); });
}

function renderMonthTabs()
{
   var bar = document.getElementById('month-tabs');
   bar.innerHTML = '';
   months.forEach(function(m)
   {
      var tab = document.createElement('div');
      tab.className = 'month-tab' + (m.month_number === activeMonthNo ? ' active' : '') +
                      (m.is_reconciled ? ' reconciled' : '');
      tab.textContent = MONTH_NAMES[m.month_number - 1];
      tab.onclick = (function(mn) { return function() { selectMonth(mn); }; })(m.month_number);
      bar.appendChild(tab);
   });
}

function selectMonth(monthNo)
{
   activeMonthNo = monthNo;
   var month = months.find(function(m) { return m.month_number === monthNo; });
   if (!month) return;
   activeMonthId = month.id;
   renderMonthTabs();

   if (allYearEntries[month.id])
   {
      entries = allYearEntries[month.id];
      renderEntries();
      updateSummaryPanel();
      return;
   }

   fetch('ws/entries?month_id=' + month.id, { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         allYearEntries[month.id] = data;
         entries = data;
         renderEntries();
         updateSummaryPanel();
      });
}

function renderEntries()
{
   var debits  = entries.filter(function(e) { return e.entry_type === 'DEBIT'; });
   var credits = entries.filter(function(e) { return e.entry_type === 'CREDIT'; });

   document.getElementById('rows-debit').innerHTML  = renderEntryRows(debits);
   document.getElementById('rows-credit').innerHTML = renderEntryRows(credits);

   var debitTotal  = debits.reduce(function(s, e)  { return s + e.amount; }, 0);
   var creditTotal = credits.reduce(function(s, e) { return s + e.amount; }, 0);
   document.getElementById('debit-total').textContent  = fmt(debitTotal);
   document.getElementById('credit-total').textContent = fmt(creditTotal);

   updateBalanceRibbon(debitTotal, creditTotal);
   updateReconcileBadge();
}

function renderEntryRows(list)
{
   if (list.length === 0)
      return '<tr><td colspan="5" class="text-muted text-center py-3" style="font-size:12px;">None yet.</td></tr>';

   return list.map(function(e)
   {
      return '<tr class="entry-row">' +
         '<td class="entry-td">' + escHtml(e.description) + '</td>' +
         '<td class="entry-td"><span class="cat-badge">' + escHtml(e.category) + '</span></td>' +
         '<td class="entry-td">' + fmt(e.amount) + '</td>' +
         '<td class="entry-td" title="' + (e.is_actual ? 'Actual' : 'Estimate') + '">' +
            '<span class="actual-dot ' + (e.is_actual ? 'yes' : 'no') + '"></span>' +
         '</td>' +
         '<td class="entry-td"><div style="display:flex;gap:4px;">' +
            '<button class="btn btn-xs btn-outline-secondary" style="padding:2px 6px;font-size:11px;" onclick="openEditEntry(' + e.id + ')">' +
               '<i class="fa-solid fa-pencil"></i>' +
            '</button>' +
            '<button class="btn btn-xs btn-outline-danger" style="padding:2px 6px;font-size:11px;" onclick="openDeleteEntry(' + e.id + ',\'' + escHtml(e.description) + '\')">' +
               '<i class="fa-solid fa-trash"></i>' +
            '</button>' +
         '</div></td>' +
      '</tr>';
   }).join('');
}

function updateBalanceRibbon(debitTotal, creditTotal)
{
   var year    = years.find(function(y) { return y.id === activeYearId; });
   var opening = calcMonthOpening(activeMonthNo, year);
   var net     = creditTotal - debitTotal;
   var closing = opening - debitTotal + creditTotal;

   document.getElementById('br-open').textContent    = fmt(opening);
   document.getElementById('br-debits').textContent  = fmt(debitTotal);
   document.getElementById('br-credits').textContent = fmt(creditTotal);

   var netEl = document.getElementById('br-net');
   netEl.textContent = (net >= 0 ? '+' : '') + fmt(net);
   netEl.style.color = net >= 0 ? '#4ade80' : '#f87171';

   document.getElementById('br-close').textContent = fmt(closing);
}

function calcMonthOpening(monthNo, year)
{
   var balance = year ? year.opening_balance : 0;
   for (var mn = 1; mn < monthNo; mn++)
   {
      var m    = months.find(function(x) { return x.month_number === mn; });
      if (!m) continue;
      var ents = allYearEntries[m.id] || [];
      var d    = ents.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      var c    = ents.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      balance  = balance - d + c;
   }
   return balance;
}

function updateReconcileBadge()
{
   var month = months.find(function(m) { return m.month_number === activeMonthNo; });
   if (!month) return;
   var badge = document.getElementById('reconcile-badge');
   var lbl   = document.getElementById('reconcile-btn-lbl');
   if (month.is_reconciled)
   {
      badge.innerHTML = '<span style="font-size:11px;background:#dcfce7;color:#166534;padding:2px 8px;border-radius:3px;font-weight:700;">Reconciled</span>';
      lbl.textContent = 'Unmark';
   }
   else
   {
      badge.innerHTML = '<span style="font-size:11px;background:#f1f5f9;color:#94a3b8;padding:2px 8px;border-radius:3px;font-weight:700;">Open</span>';
      lbl.textContent = 'Mark Reconciled';
   }
}

function toggleReconcile()
{
   var month = months.find(function(m) { return m.month_number === activeMonthNo; });
   if (!month) return;
   var newVal = month.is_reconciled ? 0 : 1;

   fetch('ws/months/' + month.id, {
      method: 'PUT',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ is_reconciled: newVal, notes: month.notes || '' })
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok')
      {
         month.is_reconciled = newVal;
         updateReconcileBadge();
         renderMonthTabs();
      }
   });
}

function updateSummaryPanel()
{
   var year = years.find(function(y) { return y.id === activeYearId; });
   if (!year) return;

   var balance    = year.opening_balance;
   var totalDebit = 0;
   months.forEach(function(m)
   {
      var ents = allYearEntries[m.id] || [];
      var d = ents.filter(function(e) { return e.entry_type === 'DEBIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      var c = ents.filter(function(e) { return e.entry_type === 'CREDIT'; }).reduce(function(s,e) { return s+e.amount; }, 0);
      balance    += (c - d);
      totalDebit += d;
   });

   var gain   = balance - year.opening_balance;
   var disc   = Math.max(0, totalDebit - fixedYearly);
   var onTgt  = gain - year.target_gain;

   var netInt   = interestRecords.reduce(function(s, r) { return s + r.net_amount; }, 0);
   var grossInt = netInt / 0.53;
   var taxPaid  = grossInt - netInt;
   var refund   = taxPaid - (grossInt * 0.37);

   document.getElementById('sp-yr-open').textContent     = fmt(year.opening_balance);
   document.getElementById('sp-yr-close').textContent    = fmt(balance);
   document.getElementById('sp-target').textContent      = fmt(year.target_gain);
   document.getElementById('sp-fixed').textContent       = fmt(fixedYearly);
   document.getElementById('sp-total-spend').textContent = fmt(totalDebit);
   document.getElementById('sp-disc-yr').textContent     = fmt(disc);
   document.getElementById('sp-disc-mo').textContent     = fmt(disc / 12);
   document.getElementById('sp-disc-day').textContent    = fmt(disc / 365);
   document.getElementById('sp-interest').textContent    = fmt(netInt);
   document.getElementById('sp-refund').textContent      = fmt(Math.abs(refund));

   var gainEl = document.getElementById('sp-yr-gain');
   gainEl.textContent = (gain >= 0 ? '+' : '') + fmt(gain);
   gainEl.className = 'sp-val ' + (gain >= 0 ? 'gain-pos' : 'gain-neg');

   var tgtEl = document.getElementById('sp-on-target');
   tgtEl.textContent = (onTgt >= 0 ? '+' : '') + fmt(onTgt);
   tgtEl.className = 'sp-val ' + (onTgt >= 0 ? 'gain-pos' : 'gain-neg');
}

// --- Entry modals ---

function openAddEntry(type)
{
   document.getElementById('ent-id').value          = '';
   document.getElementById('ent-type').value        = type;
   document.getElementById('ent-desc').value        = '';
   document.getElementById('ent-amount').value      = '';
   document.getElementById('ent-actual').checked    = false;
   document.getElementById('entryModalTitle').textContent = 'Add ' + (type === 'DEBIT' ? 'Debit' : 'Credit');
   document.getElementById('ent-error').style.display    = 'none';
   populateCatSelect(type, '');
   entryModal.show();
}

function openEditEntry(id)
{
   var e = entries.find(function(x) { return x.id === id; });
   if (!e) return;
   document.getElementById('ent-id').value          = e.id;
   document.getElementById('ent-type').value        = e.entry_type;
   document.getElementById('ent-desc').value        = e.description;
   document.getElementById('ent-amount').value      = e.amount;
   document.getElementById('ent-actual').checked    = e.is_actual === 1;
   document.getElementById('entryModalTitle').textContent = 'Edit ' + (e.entry_type === 'DEBIT' ? 'Debit' : 'Credit');
   document.getElementById('ent-error').style.display    = 'none';
   populateCatSelect(e.entry_type, e.category);
   entryModal.show();
}

function populateCatSelect(type, selected)
{
   var cats = type === 'DEBIT' ? DEBIT_CATS : CREDIT_CATS;
   var sel  = document.getElementById('ent-cat');
   sel.innerHTML = cats.map(function(c)
   {
      return '<option value="' + c + '"' + (c === selected ? ' selected' : '') + '>' + c + '</option>';
   }).join('');
}

function saveEntry()
{
   var id     = document.getElementById('ent-id').value;
   var type   = document.getElementById('ent-type').value;
   var desc   = document.getElementById('ent-desc').value.trim();
   var cat    = document.getElementById('ent-cat').value;
   var amount = parseFloat(document.getElementById('ent-amount').value);
   var actual = document.getElementById('ent-actual').checked ? 1 : 0;
   var errEl  = document.getElementById('ent-error');

   if (!desc)
   {
      errEl.textContent = 'Description is required.';
      errEl.style.display = 'block';
      return;
   }
   if (isNaN(amount) || amount < 0)
   {
      errEl.textContent = 'Enter a valid amount.';
      errEl.style.display = 'block';
      return;
   }
   errEl.style.display = 'none';

   var payload = { entry_type: type, category: cat, description: desc,
                   amount: amount, is_actual: actual, sort_order: 0, month_id: activeMonthId };
   var url    = id ? 'ws/entries/' + id : 'ws/entries';
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
      if (res.status === 'ok') { entryModal.hide(); reloadMonthEntries(); }
      else { errEl.textContent = res.msg || 'Save failed.'; errEl.style.display = 'block'; }
   })
   .catch(function() { errEl.textContent = 'Network error.'; errEl.style.display = 'block'; });
}

function openDeleteEntry(id, desc)
{
   deleteEntryId = id;
   document.getElementById('ent-del-desc').textContent = desc;
   entDeleteModal.show();
}

function confirmDeleteEntry()
{
   if (deleteEntryId < 0) return;
   fetch('ws/entries/' + deleteEntryId, { method: 'DELETE', credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function() { entDeleteModal.hide(); reloadMonthEntries(); })
      .catch(function() { entDeleteModal.hide(); });
}

function reloadMonthEntries()
{
   delete allYearEntries[activeMonthId];
   fetch('ws/entries?month_id=' + activeMonthId, { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         allYearEntries[activeMonthId] = data;
         entries = data;
         renderEntries();
         updateSummaryPanel();
      });
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
