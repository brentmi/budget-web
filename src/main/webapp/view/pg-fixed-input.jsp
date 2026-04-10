<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "pg-fixed-input"); %>
<%@ include file="header.jsp" %>

<style>
   .section-heading {
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      color: #64748b;
      margin: 0 0 10px 0;
   }
   .fi-table th {
      background: #1e2738;
      color: #94a3b8;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      border: none;
      padding: 10px 12px;
   }
   .fi-table td {
      vertical-align: middle;
      padding: 8px 12px;
      border-color: #e9ecef;
   }
   .fi-table tbody tr:hover { background: #f8fafc; }
   .totals-bar {
      background: #1e2738;
      color: #e2e8f0;
      border-radius: 6px;
      padding: 14px 20px;
      display: flex;
      gap: 32px;
      align-items: center;
      flex-wrap: wrap;
   }
   .totals-bar .tot-item { text-align: center; }
   .totals-bar .tot-label { font-size: 10px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; color: #64748b; }
   .totals-bar .tot-value { font-size: 18px; font-weight: 700; color: #e2e8f0; }
   .badge-freq {
      font-size: 10px;
      font-weight: 600;
      padding: 3px 8px;
      border-radius: 3px;
   }
   .badge-Monthly   { background: #dbeafe; color: #1d4ed8; }
   .badge-Quarterly { background: #dcfce7; color: #166534; }
   .badge-Yearly    { background: #fef9c3; color: #854d0e; }
   .badge-Weekly    { background: #fce7f3; color: #9d174d; }
   .btn-row { display: flex; gap: 6px; }
   .fi-table tfoot td {
      font-weight: 700;
      background: #f1f5f9;
      border-top: 2px solid #cbd5e0;
      padding: 8px 12px;
   }
</style>

<h5 class="mb-1">Fixed Inputs</h5>
<p class="text-muted mb-4" style="font-size:13px;">Known and flexible recurring expenses used to calculate the yearly required spend.</p>

<!-- TOTALS BAR -->
<div class="totals-bar mb-4" id="totals-bar">
   <div class="tot-item">
      <div class="tot-label">Yearly Total</div>
      <div class="tot-value" id="tot-yearly">—</div>
   </div>
   <div class="tot-item">
      <div class="tot-label">Quarterly</div>
      <div class="tot-value" id="tot-quarterly">—</div>
   </div>
   <div class="tot-item">
      <div class="tot-label">Monthly</div>
      <div class="tot-value" id="tot-monthly">—</div>
   </div>
   <div class="tot-item">
      <div class="tot-label">Weekly</div>
      <div class="tot-value" id="tot-weekly">—</div>
   </div>
   <div class="tot-item">
      <div class="tot-label">Daily</div>
      <div class="tot-value" id="tot-daily">—</div>
   </div>
</div>

<!-- KNOWN FIXED -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="d-flex justify-content-between align-items-center mb-3">
         <p class="section-heading mb-0">Known Fixed Minimums</p>
         <button class="btn btn-sm btn-primary" onclick="openAddModal('known_fixed')">
            <i class="fa-solid fa-plus"></i> Add Item
         </button>
      </div>
      <table class="table fi-table" id="tbl-known">
         <thead>
            <tr>
               <th>Item</th>
               <th>Cost</th>
               <th>Frequency</th>
               <th>Monthly</th>
               <th>1 Year</th>
               <th>10 Years</th>
               <th>20 Years</th>
               <th style="width:80px"></th>
            </tr>
         </thead>
         <tbody id="rows-known_fixed">
            <tr><td colspan="8" class="text-center text-muted py-3">Loading...</td></tr>
         </tbody>
         <tfoot id="foot-known_fixed"></tfoot>
      </table>
   </div>
</div>

<!-- FLEXIBLE FIXED -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="d-flex justify-content-between align-items-center mb-3">
         <p class="section-heading mb-0">Flexible Fixed Minimums</p>
         <button class="btn btn-sm btn-primary" onclick="openAddModal('flexible_fixed')">
            <i class="fa-solid fa-plus"></i> Add Item
         </button>
      </div>
      <table class="table fi-table" id="tbl-flexible">
         <thead>
            <tr>
               <th>Item</th>
               <th>Cost</th>
               <th>Frequency</th>
               <th>Monthly</th>
               <th>1 Year</th>
               <th>10 Years</th>
               <th>20 Years</th>
               <th style="width:80px"></th>
            </tr>
         </thead>
         <tbody id="rows-flexible_fixed">
            <tr><td colspan="8" class="text-center text-muted py-3">Loading...</td></tr>
         </tbody>
         <tfoot id="foot-flexible_fixed"></tfoot>
      </table>
   </div>
</div>

<!-- SUBSCRIPTIONS -->
<div class="card shadow-sm mb-4">
   <div class="card-body">
      <div class="d-flex justify-content-between align-items-center mb-3">
         <p class="section-heading mb-0">Subscriptions</p>
         <button class="btn btn-sm btn-primary" onclick="openAddSubModal()">
            <i class="fa-solid fa-plus"></i> Add
         </button>
      </div>
      <table class="table fi-table mb-0">
         <thead>
            <tr>
               <th>Item</th>
               <th>Cost</th>
               <th>Frequency</th>
               <th>Monthly</th>
               <th>1 Year</th>
               <th>10 Years</th>
               <th>20 Years</th>
               <th style="width:80px"></th>
            </tr>
         </thead>
         <tbody id="rows-subscription">
            <tr><td colspan="8" class="text-center text-muted py-3">Loading...</td></tr>
         </tbody>
         <tfoot id="foot-subscription"></tfoot>
      </table>
   </div>
</div>

<!-- ADD / EDIT SUBSCRIPTION MODAL -->
<div class="modal fade" id="subModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
         <div class="modal-header">
            <h6 class="modal-title" id="subModalTitle">Add Subscription</h6>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
         </div>
         <div class="modal-body">
            <input type="hidden" id="sub-id" value="">
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Item Name</label>
               <input type="text" class="form-control form-control-sm" id="sub-name" placeholder="e.g. Netflix">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Cost ($)</label>
               <input type="number" class="form-control form-control-sm" id="sub-cost" min="0" step="0.01" placeholder="0.00">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Frequency</label>
               <select class="form-select form-select-sm" id="sub-frequency">
                  <option value="Monthly">Monthly</option>
                  <option value="Quarterly">Quarterly</option>
                  <option value="Yearly">Yearly</option>
                  <option value="Weekly">Weekly</option>
               </select>
            </div>
            <div id="sub-modal-error" class="text-danger" style="font-size:12px;display:none;"></div>
         </div>
         <div class="modal-footer">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary btn-sm" onclick="saveSubItem()">Save</button>
         </div>
      </div>
   </div>
</div>

<!-- DELETE SUBSCRIPTION MODAL -->
<div class="modal fade" id="subDeleteModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered modal-sm">
      <div class="modal-content">
         <div class="modal-body text-center py-4">
            <i class="fa-solid fa-triangle-exclamation text-warning" style="font-size:28px;"></i>
            <p class="mt-3 mb-1" style="font-size:14px;">Delete <strong id="sub-del-name"></strong>?</p>
         </div>
         <div class="modal-footer justify-content-center">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-danger btn-sm" onclick="confirmSubDelete()">Delete</button>
         </div>
      </div>
   </div>
</div>

<!-- ADD / EDIT MODAL -->
<div class="modal fade" id="itemModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
         <div class="modal-header">
            <h6 class="modal-title" id="itemModalTitle">Add Item</h6>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
         </div>
         <div class="modal-body">
            <input type="hidden" id="fi-id" value="">
            <input type="hidden" id="fi-section" value="">
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Item Name</label>
               <input type="text" class="form-control form-control-sm" id="fi-name" placeholder="e.g. Strata">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Cost ($)</label>
               <input type="number" class="form-control form-control-sm" id="fi-cost" min="0" step="0.01" placeholder="0.00">
            </div>
            <div class="mb-3">
               <label class="form-label" style="font-size:13px;">Frequency</label>
               <select class="form-select form-select-sm" id="fi-frequency">
                  <option value="Monthly">Monthly</option>
                  <option value="Quarterly">Quarterly</option>
                  <option value="Yearly">Yearly</option>
                  <option value="Weekly">Weekly</option>
               </select>
            </div>
            <div id="fi-modal-error" class="text-danger" style="font-size:12px;display:none;"></div>
         </div>
         <div class="modal-footer">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary btn-sm" onclick="saveItem()">Save</button>
         </div>
      </div>
   </div>
</div>

<!-- DELETE CONFIRM MODAL -->
<div class="modal fade" id="deleteModal" tabindex="-1" aria-hidden="true">
   <div class="modal-dialog modal-dialog-centered modal-sm">
      <div class="modal-content">
         <div class="modal-body text-center py-4">
            <i class="fa-solid fa-triangle-exclamation text-warning" style="font-size:28px;"></i>
            <p class="mt-3 mb-1" style="font-size:14px;">Delete <strong id="del-name"></strong>?</p>
            <p class="text-muted" style="font-size:12px;">This cannot be undone.</p>
         </div>
         <div class="modal-footer justify-content-center">
            <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-danger btn-sm" onclick="confirmDelete()">Delete</button>
         </div>
      </div>
   </div>
</div>

<script>
var fiItems      = [];
var subItems     = [];
var deleteId     = -1;
var subDeleteId  = -1;
var itemModal, deleteModal, subModal, subDeleteModal;

document.addEventListener('DOMContentLoaded', function()
{
   itemModal      = new bootstrap.Modal(document.getElementById('itemModal'));
   deleteModal    = new bootstrap.Modal(document.getElementById('deleteModal'));
   subModal       = new bootstrap.Modal(document.getElementById('subModal'));
   subDeleteModal = new bootstrap.Modal(document.getElementById('subDeleteModal'));
   loadItems();
   loadSubscriptions();
});

function freqMultiplier(freq)
{
   if (freq === 'Monthly')   return 12;
   if (freq === 'Quarterly') return 4;
   if (freq === 'Weekly')    return 52;
   return 1; // Yearly
}

function fmt(n)
{
   return '$' + n.toLocaleString('en-AU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function loadItems()
{
   fetch('ws/fixed-input', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         fiItems = data;
         renderSection('known_fixed');
         renderSection('flexible_fixed');
         renderTotals();
      })
      .catch(function(e)
      {
         document.getElementById('rows-known_fixed').innerHTML =
            '<tr><td colspan="8" class="text-danger text-center">Failed to load data.</td></tr>';
      });
}

function renderSection(section)
{
   var rows  = fiItems.filter(function(i) { return i.section === section; });
   var tbody = document.getElementById('rows-' + section);
   var tfoot = document.getElementById('foot-' + section);
   if (rows.length === 0)
   {
      tbody.innerHTML = '<tr><td colspan="8" class="text-center text-muted py-3">No items. Click Add Item to begin.</td></tr>';
      tfoot.innerHTML = '';
      return;
   }
   var html        = '';
   var totYearly   = 0;
   rows.forEach(function(item)
   {
      var yearly  = item.item_cost * freqMultiplier(item.frequency);
      var monthly = yearly / 12;
      var y10     = yearly * 10;
      var y20     = yearly * 20;
      var opacity = item.is_active ? '' : 'opacity:0.45;';
      if (item.is_active) totYearly += yearly;
      html += '<tr style="' + opacity + '">' +
         '<td>' + escHtml(item.item_name) + '</td>' +
         '<td>' + fmt(item.item_cost) + '</td>' +
         '<td><span class="badge-freq badge-' + item.frequency + '">' + item.frequency + '</span></td>' +
         '<td>' + fmt(monthly) + '</td>' +
         '<td>' + fmt(yearly) + '</td>' +
         '<td>' + fmt(y10) + '</td>' +
         '<td>' + fmt(y20) + '</td>' +
         '<td><div class="btn-row">' +
            '<button class="btn btn-xs btn-outline-secondary" style="padding:2px 7px;font-size:11px;" onclick="openEditModal(' + item.id + ')">' +
               '<i class="fa-solid fa-pencil"></i>' +
            '</button>' +
            '<button class="btn btn-xs btn-outline-danger" style="padding:2px 7px;font-size:11px;" onclick="openDeleteModal(' + item.id + ',\'' + escHtml(item.item_name) + '\')">' +
               '<i class="fa-solid fa-trash"></i>' +
            '</button>' +
         '</div></td>' +
      '</tr>';
   });
   tbody.innerHTML = html;
   tfoot.innerHTML = '<tr>' +
      '<td>Subtotal</td>' +
      '<td></td>' +
      '<td></td>' +
      '<td>' + fmt(totYearly / 12) + '</td>' +
      '<td>' + fmt(totYearly) + '</td>' +
      '<td>' + fmt(totYearly * 10) + '</td>' +
      '<td>' + fmt(totYearly * 20) + '</td>' +
      '<td></td>' +
   '</tr>';
}

function renderTotals()
{
   var yearlyTotal = fiItems
      .filter(function(i) { return i.is_active; })
      .reduce(function(sum, i) { return sum + i.item_cost * freqMultiplier(i.frequency); }, 0);

   document.getElementById('tot-yearly').textContent    = fmt(yearlyTotal);
   document.getElementById('tot-quarterly').textContent = fmt(yearlyTotal / 4);
   document.getElementById('tot-monthly').textContent   = fmt(yearlyTotal / 12);
   document.getElementById('tot-weekly').textContent    = fmt(yearlyTotal / 52);
   document.getElementById('tot-daily').textContent     = fmt(yearlyTotal / 365);
}

function openAddModal(section)
{
   document.getElementById('fi-id').value        = '';
   document.getElementById('fi-section').value   = section;
   document.getElementById('fi-name').value      = '';
   document.getElementById('fi-cost').value      = '';
   document.getElementById('fi-frequency').value = 'Monthly';
   document.getElementById('itemModalTitle').textContent = 'Add Item';
   document.getElementById('fi-modal-error').style.display = 'none';
   itemModal.show();
}

function openEditModal(id)
{
   var item = fiItems.find(function(i) { return i.id === id; });
   if (!item) return;
   document.getElementById('fi-id').value        = item.id;
   document.getElementById('fi-section').value   = item.section;
   document.getElementById('fi-name').value      = item.item_name;
   document.getElementById('fi-cost').value      = item.item_cost;
   document.getElementById('fi-frequency').value = item.frequency;
   document.getElementById('itemModalTitle').textContent = 'Edit Item';
   document.getElementById('fi-modal-error').style.display = 'none';
   itemModal.show();
}

function saveItem()
{
   var id   = document.getElementById('fi-id').value;
   var name = document.getElementById('fi-name').value.trim();
   var cost = parseFloat(document.getElementById('fi-cost').value);
   var freq = document.getElementById('fi-frequency').value;
   var sec  = document.getElementById('fi-section').value;
   var errEl = document.getElementById('fi-modal-error');

   if (!name)
   {
      errEl.textContent = 'Item name is required.';
      errEl.style.display = 'block';
      return;
   }
   if (isNaN(cost) || cost < 0)
   {
      errEl.textContent = 'Enter a valid cost.';
      errEl.style.display = 'block';
      return;
   }
   errEl.style.display = 'none';

   var payload = { item_name: name, item_cost: cost, frequency: freq, section: sec };
   var url, method;
   if (id)
   {
      payload.is_active  = 1;
      payload.sort_order = 0;
      url    = 'ws/fixed-input/' + id;
      method = 'PUT';
   }
   else
   {
      url    = 'ws/fixed-input';
      method = 'POST';
   }

   fetch(url, {
      method: method,
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok')
      {
         itemModal.hide();
         loadItems();
      }
      else
      {
         errEl.textContent = res.msg || 'Save failed.';
         errEl.style.display = 'block';
      }
   })
   .catch(function()
   {
      errEl.textContent = 'Network error. Please try again.';
      errEl.style.display = 'block';
   });
}

function openDeleteModal(id, name)
{
   deleteId = id;
   document.getElementById('del-name').textContent = name;
   deleteModal.show();
}

function confirmDelete()
{
   if (deleteId < 0) return;
   fetch('ws/fixed-input/' + deleteId, {
      method: 'DELETE',
      credentials: 'same-origin'
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      deleteModal.hide();
      loadItems();
   })
   .catch(function() { deleteModal.hide(); });
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

// --- Subscriptions ---

function loadSubscriptions()
{
   fetch('ws/fixed-input', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         subItems = data.filter(function(i) { return i.section === 'flexible_subs'; });
         renderSubscriptions();
      })
      .catch(function()
      {
         document.getElementById('rows-subscription').innerHTML =
            '<tr><td colspan="8" class="text-danger text-center">Failed to load.</td></tr>';
      });
}

function renderSubscriptions()
{
   var tbody = document.getElementById('rows-subscription');
   var tfoot = document.getElementById('foot-subscription');
   if (subItems.length === 0)
   {
      tbody.innerHTML = '<tr><td colspan="8" class="text-center text-muted py-3">No items. Click Add to begin.</td></tr>';
      tfoot.innerHTML = '';
      return;
   }
   var html      = '';
   var totYearly = 0;
   subItems.forEach(function(item)
   {
      var yearly  = item.item_cost * freqMultiplier(item.frequency);
      var monthly = yearly / 12;
      var y10     = yearly * 10;
      var y20     = yearly * 20;
      var opacity = item.is_active ? '' : 'opacity:0.45;';
      if (item.is_active) totYearly += yearly;
      html += '<tr style="' + opacity + '">' +
         '<td>' + escHtml(item.item_name) + '</td>' +
         '<td>' + fmt(item.item_cost) + '</td>' +
         '<td><span class="badge-freq badge-' + item.frequency + '">' + item.frequency + '</span></td>' +
         '<td>' + fmt(monthly) + '</td>' +
         '<td>' + fmt(yearly) + '</td>' +
         '<td>' + fmt(y10) + '</td>' +
         '<td>' + fmt(y20) + '</td>' +
         '<td><div class="btn-row">' +
            '<button class="btn btn-xs btn-outline-secondary" style="padding:2px 7px;font-size:11px;" onclick="openEditSubModal(' + item.id + ')">' +
               '<i class="fa-solid fa-pencil"></i>' +
            '</button>' +
            '<button class="btn btn-xs btn-outline-danger" style="padding:2px 7px;font-size:11px;" onclick="openSubDeleteModal(' + item.id + ',\'' + escHtml(item.item_name) + '\')">' +
               '<i class="fa-solid fa-trash"></i>' +
            '</button>' +
         '</div></td>' +
      '</tr>';
   });
   tbody.innerHTML = html;
   tfoot.innerHTML = '<tr>' +
      '<td>Subtotal</td>' +
      '<td></td>' +
      '<td></td>' +
      '<td>' + fmt(totYearly / 12) + '</td>' +
      '<td>' + fmt(totYearly) + '</td>' +
      '<td>' + fmt(totYearly * 10) + '</td>' +
      '<td>' + fmt(totYearly * 20) + '</td>' +
      '<td></td>' +
   '</tr>';
}

function openAddSubModal()
{
   document.getElementById('sub-id').value        = '';
   document.getElementById('sub-name').value      = '';
   document.getElementById('sub-cost').value      = '';
   document.getElementById('sub-frequency').value = 'Monthly';
   document.getElementById('subModalTitle').textContent = 'Add Subscription';
   document.getElementById('sub-modal-error').style.display = 'none';
   subModal.show();
}

function openEditSubModal(id)
{
   var item = subItems.find(function(i) { return i.id === id; });
   if (!item) return;
   document.getElementById('sub-id').value        = item.id;
   document.getElementById('sub-name').value      = item.item_name;
   document.getElementById('sub-cost').value      = item.item_cost;
   document.getElementById('sub-frequency').value = item.frequency;
   document.getElementById('subModalTitle').textContent = 'Edit Subscription';
   document.getElementById('sub-modal-error').style.display = 'none';
   subModal.show();
}

function saveSubItem()
{
   var id    = document.getElementById('sub-id').value;
   var name  = document.getElementById('sub-name').value.trim();
   var cost  = parseFloat(document.getElementById('sub-cost').value);
   var freq  = document.getElementById('sub-frequency').value;
   var errEl = document.getElementById('sub-modal-error');

   if (!name)
   {
      errEl.textContent = 'Item name is required.';
      errEl.style.display = 'block';
      return;
   }
   if (isNaN(cost) || cost < 0)
   {
      errEl.textContent = 'Enter a valid cost.';
      errEl.style.display = 'block';
      return;
   }
   errEl.style.display = 'none';

   var payload = { section: 'flexible_subs', item_name: name, item_cost: cost, frequency: freq, sort_order: 0, is_active: 1 };
   var url    = id ? 'ws/fixed-input/' + id : 'ws/fixed-input';
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
      if (res.status === 'ok') { subModal.hide(); loadSubscriptions(); }
      else { errEl.textContent = res.msg || 'Save failed.'; errEl.style.display = 'block'; }
   })
   .catch(function() { errEl.textContent = 'Network error.'; errEl.style.display = 'block'; });
}

function openSubDeleteModal(id, name)
{
   subDeleteId = id;
   document.getElementById('sub-del-name').textContent = name;
   subDeleteModal.show();
}

function confirmSubDelete()
{
   if (subDeleteId < 0) return;
   fetch('ws/fixed-input/' + subDeleteId, { method: 'DELETE', credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function() { subDeleteModal.hide(); loadSubscriptions(); })
      .catch(function() { subDeleteModal.hide(); });
}
</script>

<%@ include file="footer.jsp" %>
