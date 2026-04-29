<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "pg-worksheet"); %>
<%@ include file="header.jsp" %>

<style>
   .ws-section-heading {
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      color: #64748b;
      margin: 0 0 10px 0;
   }
   .ws-table th {
      background: #1e2738;
      color: #94a3b8;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      border: none;
      padding: 10px 12px;
   }
   .ws-table td {
      vertical-align: middle;
      padding: 8px 12px;
      border-color: #e9ecef;
   }
   .ws-table tbody tr:hover { background: #f8fafc; }
   .total-row td {
      font-weight: 700;
      background: #f1f5f9;
      border-top: 2px solid #cbd5e0 !important;
   }
   .interest-card {
      background: #1e2738;
      color: #e2e8f0;
      border-radius: 6px;
      padding: 16px 20px;
   }
   .interest-card .int-label { font-size: 10px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; color: #64748b; }
   .interest-card .int-value { font-size: 18px; font-weight: 700; color: #e2e8f0; margin-top: 2px; }
   .tax-rate-note { font-size: 11px; color: #94a3b8; margin-top: 4px; }
   .int-table th {
      background: #1e2738;
      color: #94a3b8;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      border: none;
      padding: 10px 12px;
   }
   .int-table td {
      vertical-align: middle;
      padding: 8px 12px;
      border-color: #e9ecef;
      font-size: 13px;
   }
   .int-table .total-row td {
      background: #f1f5f9;
      font-weight: 700;
      border-top: 2px solid #cbd5e0 !important;
   }
   .refund-pos { color: #166534; font-weight: 700; }
   .refund-neg { color: #991b1b; font-weight: 700; }
</style>

<h5 class="mb-1">Worksheet</h5>
<p class="text-muted mb-4" style="font-size:13px;">Reference data for monthly CC estimates, subscriptions, and interest income tracking.</p>

<div class="row g-4">

   <!-- LEFT: CC Estimates + Subscriptions -->
   <div class="col-lg-6">

      <!-- Payment Forecast -->
      <div class="card shadow-sm mb-4">
         <div class="card-body">
            <p class="ws-section-heading mb-3">Payment Forecast</p>
            <table class="table ws-table mb-0">
               <thead>
                  <tr>
                     <th>Next Pmt</th>
                     <th>Stmt Days</th>
                     <th>Per Day</th>
                     <th>Remaining</th>
                     <th>Last Unallocated</th>
                  </tr>
               </thead>
               <tbody>
                  <tr>
                     <td id="next-pmt" style="font-size:13px;">&#x2014;</td>
                     <td id="days-until-stmt">&#x2014;</td>
                     <td id="per-day-spend">&#x2014;</td>
                     <td id="remaining-budget">&#x2014;</td>
                     <td>
                        <input type="number" id="last-alloc-input" class="form-control form-control-sm"
                               style="width:110px;display:inline-block;" value="0.00" min="0" step="0.01">
                        <button class="btn btn-xs btn-outline-primary" style="padding:2px 7px;font-size:11px;margin-left:4px;"
                                onclick="saveLastUnallocated()" title="Save">
                           <i class="fa-solid fa-floppy-disk"></i>
                        </button>
                     </td>
                  </tr>
               </tbody>
            </table>
            <div style="font-size:11px;color:#94a3b8;margin-top:8px;">
               Statement date: 26th of each month &nbsp;&middot;&nbsp; Remaining = Stmt Days &times; Per Day
            </div>
         </div>
      </div>

      <!-- CC Estimates -->
      <div class="card shadow-sm mb-4">
         <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-3">
               <p class="ws-section-heading mb-0">Monthly CC Estimates</p>
               <div class="d-flex gap-2">
                  <button class="btn btn-sm btn-outline-secondary" onclick="resetCcEstimates()">
                     <i class="fa-solid fa-rotate-left"></i> Reset
                  </button>
                  <button class="btn btn-sm btn-primary" onclick="openAddModal('cc_estimate')">
                     <i class="fa-solid fa-plus"></i> Add
                  </button>
               </div>
            </div>
            <table class="table ws-table mb-0">
               <thead><tr><th>Item</th><th>Amount</th><th style="width:70px"></th></tr></thead>
               <tbody id="rows-cc_estimate">
                  <tr><td colspan="3" class="text-center text-muted py-3">Loading...</td></tr>
               </tbody>
               <tfoot>
                  <tr class="total-row">
                     <td>Total</td>
                     <td id="cc-total">â</td>
                     <td></td>
                  </tr>
               </tfoot>
            </table>
         </div>
      </div>

   </div><!-- /col-left -->

   <!-- RIGHT: Interest Tracking -->
   <div class="col-lg-6">
      <div class="card shadow-sm mb-4">
         <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-3">
               <p class="ws-section-heading mb-0">Interest Income - Current Year</p>
               <div class="d-flex align-items-center gap-2">
                  <label style="font-size:12px; color:#64748b; margin:0;">Year:</label>
                  <select class="form-select form-select-sm" id="interest-year-sel" style="width:120px;" onchange="loadInterest()"></select>
                  <button class="btn btn-sm btn-primary" onclick="openAddIntModal()">
                     <i class="fa-solid fa-plus"></i> Add
                  </button>
               </div>
            </div>

            <!-- Summary cards -->
            <div class="row g-2 mb-3">
               <div class="col-4">
                  <div class="interest-card">
                     <div class="int-label">Net Total</div>
                     <div class="int-value" id="int-net-total">â</div>
                     <div class="tax-rate-note">after tax (47%)</div>
                  </div>
               </div>
               <div class="col-4">
                  <div class="interest-card">
                     <div class="int-label">Gross approx.</div>
                     <div class="int-value" id="int-gross-total">â</div>
                     <div class="tax-rate-note">net / 0.53</div>
                  </div>
               </div>
               <div class="col-4">
                  <div class="interest-card">
                     <div class="int-label">Tax Paid (47%)</div>
                     <div class="int-value" id="int-tax-paid">â</div>
                     <div class="tax-rate-note">gross â net</div>
                  </div>
               </div>
            </div>

            <!-- ATO refund estimate -->
            <div class="mb-3 p-3 rounded" style="background:#f1f5f9;">
               <div class="d-flex justify-content-between align-items-center">
                  <div>
                     <div style="font-size:12px;font-weight:600;color:#64748b;">ATO Refund Estimate (at 37%)</div>
                     <div style="font-size:11px;color:#94a3b8;">Tax paid at 47% vs actual 37% bracket â excess refunded</div>
                  </div>
                  <div id="ato-refund" style="font-size:20px;font-weight:700;">â</div>
               </div>
            </div>

            <!-- Monthly rows -->
            <table class="table int-table mb-0">
               <thead>
                  <tr>
                     <th>Month</th>
                     <th>Net ($)</th>
                     <th>Gross (est.)</th>
                     <th>Tax (47%)</th>
                     <th style="width:70px"></th>
                  </tr>
               </thead>
               <tbody id="rows-interest">
                  <tr><td colspan="5" class="text-center text-muted py-3">Loading...</td></tr>
               </tbody>
            </table>
         </div>
      </div>
   </div><!-- /col-right -->

</div><!-- /row -->

<!-- ADD / EDIT WORKSHEET ITEM MODAL -->
<div class="modal fade" id="wsModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
         <div class="modal-header">
            <h6 class="modal-title" id="wsModalTitle">Add Item</h6>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
         </div>
         <div class="modal-body">
            <input type="hidden" id="ws-id" value="">
            <input type="hidden" id="ws-section" value="">
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;" id="ws-name-label">Item Name</label>
               <input type="text" class="form-control form-control-sm" id="ws-name">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Amount ($)</label>
               <input type="number" class="form-control form-control-sm" id="ws-amount" min="0" step="0.01">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Notes (optional)</label>
               <input type="text" class="form-control form-control-sm" id="ws-notes" placeholder="">
            </div>
            <div class="mb-3">
               <div class="form-check form-switch">
                  <input class="form-check-input" type="checkbox" role="switch" id="ws-is-active" style="cursor:pointer;width:2.5em;height:1.25em;">
                  <label class="form-check-label" style="font-size:13px;" for="ws-is-active">Is Active</label>
               </div>
            </div>
            <div id="ws-modal-error" class="text-danger" style="font-size:12px;display:none;"></div>
         </div>
         <div class="modal-footer">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-outline-warning btn-sm" id="ws-set-default-btn" style="display:none;" onclick="saveWsItem(true)">Set Default</button>
            <button type="button" class="btn btn-primary btn-sm" onclick="saveWsItem(false)">Save</button>
         </div>
      </div>
   </div>
</div>

<!-- ADD / EDIT INTEREST RECORD MODAL -->
<div class="modal fade" id="intModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
         <div class="modal-header">
            <h6 class="modal-title" id="intModalTitle">Interest Record</h6>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
         </div>
         <div class="modal-body">
            <input type="hidden" id="int-id" value="">
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Date</label>
               <input type="date" class="form-control form-control-sm" id="int-date">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Net Amount ($)</label>
               <input type="number" class="form-control form-control-sm" id="int-amount" min="0" step="0.01">
            </div>
            <div class="mb-2" style="background:#f8fafc;border-radius:4px;padding:10px;">
               <div style="font-size:12px;color:#64748b;">Gross (net / 0.53): <strong id="int-calc-gross">â</strong></div>
               <div style="font-size:12px;color:#64748b;">Tax paid (47%): <strong id="int-calc-tax">â</strong></div>
            </div>
            <div id="int-modal-error" class="text-danger" style="font-size:12px;display:none;"></div>
         </div>
         <div class="modal-footer">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary btn-sm" onclick="saveInterest()">Save</button>
         </div>
      </div>
   </div>
</div>

<!-- DELETE CONFIRM MODAL -->
<div class="modal fade" id="wsDeleteModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered modal-sm">
      <div class="modal-content">
         <div class="modal-body text-center py-4">
            <i class="fa-solid fa-triangle-exclamation text-warning" style="font-size:28px;"></i>
            <p class="mt-3 mb-1" style="font-size:14px;">Delete <strong id="ws-del-name"></strong>?</p>
         </div>
         <div class="modal-footer justify-content-center">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-danger btn-sm" onclick="confirmWsDelete()">Delete</button>
         </div>
      </div>
   </div>
</div>

<script>
var wsItems      = [];
var intRecords   = [];
var wsDeleteId   = -1;
var wsDeleteType = '';
var wsModal, intModal, wsDeleteModal, intModalObj;
var availableYears = [];

var MONTHS = ['January','February','March','April','May','June',
              'July','August','September','October','November','December'];

document.addEventListener('DOMContentLoaded', function()
{
   wsModal      = new bootstrap.Modal(document.getElementById('wsModal'));
   intModalObj  = new bootstrap.Modal(document.getElementById('intModal'));
   wsDeleteModal = new bootstrap.Modal(document.getElementById('wsDeleteModal'));

   document.getElementById('int-amount').addEventListener('input', updateIntCalc);

   loadWorksheetItems();
   loadYears();
});

function loadYears()
{
   fetch('ws/years', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(years)
      {
         availableYears = years;
         var sel = document.getElementById('interest-year-sel');
         sel.innerHTML = '';
         years.forEach(function(y)
         {
            var opt = document.createElement('option');
            opt.value = y.year_label;
            opt.textContent = y.year_label;
            sel.appendChild(opt);
         });
         // Default to current financial year (July–June), fall back to most recent
         if (years.length > 0)
         {
            var now      = new Date();
            var mo       = now.getMonth(); // 0=Jan … 11=Dec
            var yr       = now.getFullYear();
            var fyStart  = mo >= 6 ? yr : yr - 1;
            var fyLabel  = fyStart + '-' + (fyStart + 1);
            var matched  = years.find(function(y) { return y.year_label === fyLabel; });
            sel.value    = matched ? fyLabel : years[years.length - 1].year_label;
         }
         loadInterest();
         loadNextCcPayment();
      })
      .catch(function() { loadInterest(); });
}

function loadWorksheetItems()
{
   fetch('ws/worksheet', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         wsItems = data;
         renderCcEstimates();
         renderPerDayEstimate();
      })
      .catch(function()
      {
         document.getElementById('rows-cc_estimate').innerHTML =
            '<tr><td colspan="3" class="text-danger text-center">Failed to load.</td></tr>';
      });
}

var ccBalanceItem     = null;
var lastAllocItem     = null;
var computedMiscSpend = 0;

function renderCcEstimates()
{
   var items = wsItems.filter(function(i) { return i.section === 'cc_estimate'; });
   ccBalanceItem = wsItems.find(function(i) { return i.section === 'cc_balance'; }) || null;
   lastAllocItem = wsItems.find(function(i) { return i.section === 'last_alloc'; }) || null;
   var lastAllocInput = document.getElementById('last-alloc-input');
   if (lastAllocInput) lastAllocInput.value = lastAllocItem ? lastAllocItem.amount.toFixed(2) : '0.00';

   var tbody = document.getElementById('rows-cc_estimate');
   var total = 0;
   var html  = '';

   // Balance row always first, inline input, save button only
   var balAmount = ccBalanceItem ? ccBalanceItem.amount : 0;
   total += balAmount;
   html += '<tr style="background:#f8fafc;">' +
      '<td style="font-weight:600;">Current CC Balance</td>' +
      '<td><input type="number" id="cc-balance-input" class="form-control form-control-sm" ' +
          'style="width:110px;display:inline-block;" value="' + balAmount.toFixed(2) + '" min="0" step="0.01"></td>' +
      '<td><button class="btn btn-xs btn-outline-primary" style="padding:2px 7px;font-size:11px;" ' +
          'onclick="saveCcBalance()" title="Save balance">' +
          '<i class="fa-solid fa-floppy-disk"></i>' +
      '</button></td>' +
   '</tr>';

   // Computed Misc Spending — read-only, derived from per-day target x days remaining
   total += computedMiscSpend;
   html += '<tr style="background:#f8fafc;">' +
      '<td style="font-weight:600;">Computed Estimate Spend</td>' +
      '<td id="cc-computed-misc">' + fmt(computedMiscSpend) + '</td>' +
      '<td></td>' +
   '</tr>';

   items.forEach(function(item)
   {
      if (item.is_active) total += item.amount;
      var amtColor = item.is_active ? '' : 'color:#94a3b8;';
      html += '<tr>' +
         '<td>' + escHtml(item.item_name) +
            (item.notes ? '<br><span style="font-size:11px;color:#94a3b8;">' + escHtml(item.notes) + '</span>' : '') +
         '</td>' +
         '<td id="cc-amt-' + item.id + '" style="' + amtColor + '">' + fmt(item.amount) + '</td>' +
         '<td><div style="display:flex;gap:6px;align-items:center;">' +
            '<div class="form-check form-switch mb-0" title="Include in total">' +
               '<input class="form-check-input" type="checkbox" role="switch" ' +
                  (item.is_active ? 'checked' : '') + ' ' +
                  'onchange="toggleCcItem(' + item.id + ', this)" ' +
                  'style="cursor:pointer;width:2.5em;height:1.25em;">' +
            '</div>' +
            '<button class="btn btn-xs btn-outline-secondary" style="padding:2px 7px;font-size:11px;" onclick="openEditWsModal(' + item.id + ')">' +
               '<i class="fa-solid fa-pencil"></i>' +
            '</button>' +
            '<button class="btn btn-xs btn-outline-danger" style="padding:2px 7px;font-size:11px;" onclick="openWsDeleteModal(' + item.id + ',\'' + escHtml(item.item_name) + '\',\'ws\')">' +
               '<i class="fa-solid fa-trash"></i>' +
            '</button>' +
         '</div></td>' +
      '</tr>';
   });

   tbody.innerHTML = html;
   document.getElementById('cc-total').textContent = fmt(total);
}

function renderPerDayEstimate()
{
   var now    = new Date();
   var today  = new Date(now.getFullYear(), now.getMonth(), now.getDate());
   var target = now.getDate() < 26
      ? new Date(now.getFullYear(), now.getMonth(),     26)
      : new Date(now.getFullYear(), now.getMonth() + 1, 26);

   var days = Math.round((target - today) / (1000 * 60 * 60 * 24));
   document.getElementById('days-until-stmt').textContent = days;

   fetch('ws/settings/target_per_day_spend', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         var perDay = (data.value !== null && data.value !== undefined)
            ? parseFloat(data.value)
            : 0;
         var remaining = days * perDay;
         document.getElementById('per-day-spend').textContent    = fmt(perDay);
         document.getElementById('remaining-budget').textContent = fmt(remaining);
         computedMiscSpend = remaining;

         // Patch the computed misc row and recompute the footer total without re-rendering
         var miscCell = document.getElementById('cc-computed-misc');
         if (miscCell) miscCell.textContent = fmt(computedMiscSpend);

         var ccTotal = ccBalanceItem ? ccBalanceItem.amount : 0;
         ccTotal += computedMiscSpend;
         wsItems.filter(function(i) { return i.section === 'cc_estimate'; })
                .forEach(function(i) { if (i.is_active) ccTotal += i.amount; });
         document.getElementById('cc-total').textContent = fmt(ccTotal);
      })
      .catch(function()
      {
         document.getElementById('per-day-spend').textContent    = 'â';
         document.getElementById('remaining-budget').textContent = 'â';
      });
}

function toggleCcItem(id, cb)
{
   var item = wsItems.find(function(i) { return i.id === id; });
   if (!item) return;

   item.is_active = cb.checked ? 1 : 0;

   var amtEl = document.getElementById('cc-amt-' + id);
   if (amtEl) amtEl.style.color = item.is_active ? '' : '#94a3b8';

   var total = ccBalanceItem ? ccBalanceItem.amount : 0;
   total += computedMiscSpend;
   wsItems.filter(function(i) { return i.section === 'cc_estimate'; })
          .forEach(function(i) { if (i.is_active) total += i.amount; });
   document.getElementById('cc-total').textContent = fmt(total);

   var payload = { section: item.section, item_name: item.item_name, amount: item.amount,
                   notes: item.notes, sort_order: item.sort_order || 0, is_active: item.is_active };
   fetch('ws/worksheet/' + id, {
      method: 'PUT',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
   }).catch(function() {});
}

function resetCcEstimates()
{
   if (!window.confirm('Reset all CC Estimate items to their default names, amounts and active state?'))
      return;

   fetch('ws/worksheet/reset-cc-defaults', {
      method: 'POST',
      credentials: 'same-origin'
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok') loadWorksheetItems();
   })
   .catch(function() {});
}

function saveCcBalance()
{
   var input  = document.getElementById('cc-balance-input');
   var amount = parseFloat(input.value);
   if (isNaN(amount) || amount < 0) return;

   var payload = { section: 'cc_balance', item_name: 'Current CC Balance', amount: amount, notes: '', sort_order: 0, is_active: 1 };
   var url    = ccBalanceItem ? 'ws/worksheet/' + ccBalanceItem.id : 'ws/worksheet';
   var method = ccBalanceItem ? 'PUT' : 'POST';

   fetch(url, {
      method: method,
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
   })
   .then(function(r) { return r.json(); })
   .then(function(res) { if (res.status === 'ok') loadWorksheetItems(); })
   .catch(function() {});
}

function saveLastUnallocated()
{
   var input  = document.getElementById('last-alloc-input');
   var amount = parseFloat(input.value);
   if (isNaN(amount) || amount < 0) return;

   var payload = { section: 'last_alloc', item_name: 'Last Unallocated', amount: amount, notes: '', sort_order: 0, is_active: 1 };
   var url     = lastAllocItem ? 'ws/worksheet/' + lastAllocItem.id : 'ws/worksheet';
   var method  = lastAllocItem ? 'PUT' : 'POST';

   fetch(url, {
      method: method,
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
   })
   .then(function(r) { return r.json(); })
   .then(function(res) { if (res.status === 'ok') loadWorksheetItems(); })
   .catch(function() {});
}

function loadNextCcPayment()
{
   var now      = new Date();
   var day      = now.getDate();
   var calMonth = now.getMonth() + 1;   // 1-12
   var calYear  = now.getFullYear();

   // If past the 26th, look at next month's payment
   if (day > 26)
   {
      calMonth++;
      if (calMonth > 12) { calMonth = 1; calYear++; }
   }

   // Map calendar month to FY month number (FY starts July = month 1)
   var fyMonth     = calMonth >= 7 ? calMonth - 6 : calMonth + 6;
   var fyStartYear = calMonth >= 7 ? calYear : calYear - 1;
   var fyLabel     = fyStartYear + '-' + (fyStartYear + 1);

   var year = availableYears.find(function(y) { return y.year_label === fyLabel; });
   if (!year)
   {
      document.getElementById('next-pmt').textContent = fmt(0);
      return;
   }

   fetch('ws/months?year_id=' + year.id, { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(months)
      {
         var month = months.find(function(m) { return m.month_number === fyMonth; });
         if (!month)
         {
            document.getElementById('next-pmt').textContent = fmt(0);
            return;
         }
         return fetch('ws/entries?month_id=' + month.id, { credentials: 'same-origin' })
            .then(function(r) { return r.json(); })
            .then(function(entries)
            {
               var pmtEntries = entries.filter(function(e)
               {
                  return e.category === 'cc_payment' && e.entry_type === 'DEBIT';
               });
               var total    = pmtEntries.reduce(function(s, e) { return s + e.amount; }, 0);
               var isActual = pmtEntries.some(function(e) { return e.is_actual === 1; });
               var cell     = document.getElementById('next-pmt');
               cell.textContent = fmt(total);
               cell.style.color = isActual ? '#dc2626' : '';
            });
      })
      .catch(function()
      {
         document.getElementById('next-pmt').textContent = fmt(0);
      });
}

function renderWsSection(section, tbodyId, totalId)
{
   var items = wsItems.filter(function(i) { return i.section === section; });
   var tbody = document.getElementById(tbodyId);
   var total = 0;
   if (items.length === 0)
   {
      tbody.innerHTML = '<tr><td colspan="3" class="text-center text-muted py-3">No items.</td></tr>';
      document.getElementById(totalId).textContent = fmt(0);
      return;
   }
   var html = '';
   items.forEach(function(item)
   {
      if (item.is_active) total += item.amount;
      var opacity = item.is_active ? '' : 'opacity:0.45;';
      html += '<tr style="' + opacity + '">' +
         '<td>' + escHtml(item.item_name) +
            (item.notes ? '<br><span style="font-size:11px;color:#94a3b8;">' + escHtml(item.notes) + '</span>' : '') +
         '</td>' +
         '<td>' + fmt(item.amount) + '</td>' +
         '<td><div style="display:flex;gap:4px;">' +
            '<button class="btn btn-xs btn-outline-secondary" style="padding:2px 7px;font-size:11px;" onclick="openEditWsModal(' + item.id + ')">' +
               '<i class="fa-solid fa-pencil"></i>' +
            '</button>' +
            '<button class="btn btn-xs btn-outline-danger" style="padding:2px 7px;font-size:11px;" onclick="openWsDeleteModal(' + item.id + ',\'' + escHtml(item.item_name) + '\',\'ws\')">' +
               '<i class="fa-solid fa-trash"></i>' +
            '</button>' +
         '</div></td>' +
      '</tr>';
   });
   tbody.innerHTML = html;
   document.getElementById(totalId).textContent = fmt(total);
}

function loadInterest()
{
   var year = document.getElementById('interest-year-sel').value;
   if (!year) return;
   fetch('ws/interest?year=' + encodeURIComponent(year), { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         intRecords = data;
         renderInterest(year);
      })
      .catch(function()
      {
         document.getElementById('rows-interest').innerHTML =
            '<tr><td colspan="5" class="text-danger text-center">Failed to load.</td></tr>';
      });
}

function renderInterest(year)
{
   var tbody    = document.getElementById('rows-interest');
   var netTotal = 0;

   if (intRecords.length === 0)
   {
      tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted py-3">No records for ' + escHtml(year) + '.</td></tr>';
      updateInterestSummary(0);
      return;
   }

   var html = '';
   intRecords.forEach(function(rec)
   {
      netTotal += rec.net_amount;
      var gross = rec.net_amount / 0.53;
      var tax   = gross - rec.net_amount;
      var d     = new Date(rec.record_date);
      var label = MONTHS[d.getMonth()] + ' ' + d.getFullYear();
      html += '<tr>' +
         '<td>' + escHtml(label) + '</td>' +
         '<td>' + fmt(rec.net_amount) + '</td>' +
         '<td>' + fmt(gross) + '</td>' +
         '<td>' + fmt(tax) + '</td>' +
         '<td><div style="display:flex;gap:4px;">' +
            '<button class="btn btn-xs btn-outline-secondary" style="padding:2px 7px;font-size:11px;" onclick="openEditIntModal(' + rec.id + ')">' +
               '<i class="fa-solid fa-pencil"></i>' +
            '</button>' +
            '<button class="btn btn-xs btn-outline-danger" style="padding:2px 7px;font-size:11px;" onclick="openWsDeleteModal(' + rec.id + ',\'' + escHtml(label) + '\',\'int\')">' +
               '<i class="fa-solid fa-trash"></i>' +
            '</button>' +
         '</div></td>' +
      '</tr>';
   });
   tbody.innerHTML = html;
   updateInterestSummary(netTotal);
}

function updateInterestSummary(netTotal)
{
   var gross   = netTotal / 0.53;
   var taxPaid = gross - netTotal;
   // ATO refund estimate: tax paid at 47% vs 37% bracket
   var taxAt37 = gross * 0.37;
   var refund  = taxPaid - taxAt37;

   document.getElementById('int-net-total').textContent  = fmt(netTotal);
   document.getElementById('int-gross-total').textContent = fmt(gross);
   document.getElementById('int-tax-paid').textContent   = fmt(taxPaid);

   var refundEl = document.getElementById('ato-refund');
   refundEl.textContent = fmt(Math.abs(refund));
   refundEl.className = refund >= 0 ? 'refund-pos' : 'refund-neg';
   if (refund >= 0) refundEl.textContent = '+' + refundEl.textContent;
}

// --- Worksheet item modals ---

function openAddModal(section)
{
   document.getElementById('ws-id').value      = '';
   document.getElementById('ws-section').value = section;
   document.getElementById('ws-name').value    = '';
   document.getElementById('ws-amount').value  = '';
   document.getElementById('ws-notes').value   = '';
   document.getElementById('wsModalTitle').textContent = section === 'subscription' ? 'Add Subscription' : 'Add CC Estimate';
   document.getElementById('ws-name-label').textContent = section === 'subscription' ? 'Service Name' : 'Item Name';
   document.getElementById('ws-is-active').checked = true;
   document.getElementById('ws-modal-error').style.display = 'none';
   document.getElementById('ws-set-default-btn').style.display = 'none';
   wsModal.show();
}

function openEditWsModal(id)
{
   var item = wsItems.find(function(i) { return i.id === id; });
   if (!item) return;
   document.getElementById('ws-id').value      = item.id;
   document.getElementById('ws-section').value = item.section;
   document.getElementById('ws-name').value    = item.item_name;
   document.getElementById('ws-amount').value  = item.amount;
   document.getElementById('ws-notes').value   = item.notes;
   document.getElementById('wsModalTitle').textContent = 'Edit Item';
   document.getElementById('ws-name-label').textContent = item.section === 'subscription' ? 'Service Name' : 'Item Name';
   document.getElementById('ws-is-active').checked = item.is_active === 1;
   document.getElementById('ws-modal-error').style.display = 'none';
   document.getElementById('ws-set-default-btn').style.display = item.section === 'cc_estimate' ? '' : 'none';
   wsModal.show();
}

function saveWsItem(setDefault)
{
   var id      = document.getElementById('ws-id').value;
   var section = document.getElementById('ws-section').value;
   var name    = document.getElementById('ws-name').value.trim();
   var amount  = parseFloat(document.getElementById('ws-amount').value);
   var notes   = document.getElementById('ws-notes').value.trim();
   var errEl   = document.getElementById('ws-modal-error');

   if (!name)
   {
      errEl.textContent = 'Name is required.';
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

   var isActive = document.getElementById('ws-is-active').checked ? 1 : 0;
   var payload = { section: section, item_name: name, amount: amount, notes: notes, sort_order: 0, is_active: isActive,
                   set_as_default: setDefault ? true : false };
   var url    = id ? 'ws/worksheet/' + id : 'ws/worksheet';
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
      if (res.status === 'ok') { wsModal.hide(); loadWorksheetItems(); }
      else { errEl.textContent = res.msg || 'Save failed.'; errEl.style.display = 'block'; }
   })
   .catch(function() { errEl.textContent = 'Network error.'; errEl.style.display = 'block'; });
}

// --- Interest record modals ---

function openAddIntModal()
{
   document.getElementById('int-id').value     = '';
   document.getElementById('int-date').value   = '';
   document.getElementById('int-amount').value = '';
   document.getElementById('int-calc-gross').textContent = 'â';
   document.getElementById('int-calc-tax').textContent   = 'â';
   document.getElementById('intModalTitle').textContent  = 'Add Interest Record';
   document.getElementById('int-modal-error').style.display = 'none';
   intModalObj.show();
}

function openEditIntModal(id)
{
   var rec = intRecords.find(function(r) { return r.id === id; });
   if (!rec) return;
   document.getElementById('int-id').value     = rec.id;
   document.getElementById('int-date').value   = rec.record_date;
   document.getElementById('int-amount').value = rec.net_amount;
   updateIntCalc();
   document.getElementById('intModalTitle').textContent = 'Edit Interest Record';
   document.getElementById('int-modal-error').style.display = 'none';
   intModalObj.show();
}

function updateIntCalc()
{
   var net = parseFloat(document.getElementById('int-amount').value);
   if (!isNaN(net) && net > 0)
   {
      var gross = net / 0.53;
      document.getElementById('int-calc-gross').textContent = fmt(gross);
      document.getElementById('int-calc-tax').textContent   = fmt(gross - net);
   }
   else
   {
      document.getElementById('int-calc-gross').textContent = 'â';
      document.getElementById('int-calc-tax').textContent   = 'â';
   }
}

function saveInterest()
{
   var id     = document.getElementById('int-id').value;
   var date   = document.getElementById('int-date').value;
   var amount = parseFloat(document.getElementById('int-amount').value);
   var year   = document.getElementById('interest-year-sel').value;
   var errEl  = document.getElementById('int-modal-error');

   if (!date)
   {
      errEl.textContent = 'Date is required.';
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

   var payload = { record_date: date, net_amount: amount, year_label: year };
   var url    = id ? 'ws/interest/' + id : 'ws/interest';
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
      if (res.status === 'ok') { intModalObj.hide(); loadInterest(); }
      else { errEl.textContent = res.msg || 'Save failed.'; errEl.style.display = 'block'; }
   })
   .catch(function() { errEl.textContent = 'Network error.'; errEl.style.display = 'block'; });
}

// --- Delete ---

var wsDelMode = '';

function openWsDeleteModal(id, name, mode)
{
   wsDeleteId  = id;
   wsDelMode   = mode;
   document.getElementById('ws-del-name').textContent = name;
   wsDeleteModal.show();
}

function confirmWsDelete()
{
   if (wsDeleteId < 0) return;
   var url = wsDelMode === 'int' ? 'ws/interest/' + wsDeleteId : 'ws/worksheet/' + wsDeleteId;
   fetch(url, { method: 'DELETE', credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function()
      {
         wsDeleteModal.hide();
         if (wsDelMode === 'int') loadInterest();
         else loadWorksheetItems();
      })
      .catch(function() { wsDeleteModal.hide(); });
}

// --- Utilities ---

function fmt(n)
{
   return '$' + Number(n).toLocaleString('en-AU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function escHtml(str)
{
   return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
}
</script>

<%@ include file="footer.jsp" %>
