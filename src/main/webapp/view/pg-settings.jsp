<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "pg-settings"); %>
<%@ include file="header.jsp" %>

<style>
   .settings-section { margin-bottom: 28px; }
   .settings-section h6 { font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase;
                           color: #64748b; margin-bottom: 10px; }
   .cat-table td, .cat-table th { font-size: 12px; padding: 5px 8px; vertical-align: middle; }
   .cat-table th { background: #f8fafc; color: #64748b; font-weight: 600; border-bottom: 1px solid #dee2e6; }
   .cat-type-badge { font-size: 10px; font-weight: 600; padding: 2px 6px; border-radius: 3px; }
   .badge-debit  { background: #fff0f0; color: #dc2626; }
   .badge-credit { background: #f0fdf4; color: #16a34a; }
   .hidden-row td { color: #94a3b8; }
   .cat-name-input { font-size: 12px; padding: 2px 6px; border: 1px solid #dee2e6; border-radius: 3px; width: 130px; }
</style>

<h5 class="mb-3">Settings</h5>

<!-- ── Entry Categories ────────────────────────────────────── -->
<div class="settings-section">
   <div class="card shadow-sm">
      <div class="card-body p-3">
         <h6><i class="fa-solid fa-tags me-1"></i>Entry Categories</h6>

         <table class="table table-sm mb-2 cat-table">
            <thead>
               <tr>
                  <th>Type</th>
                  <th>Name</th>
                  <th></th>
               </tr>
            </thead>
            <tbody id="cat-tbody">
               <tr><td colspan="3" class="text-muted text-center py-2">Loading...</td></tr>
            </tbody>
         </table>

         <!-- Add row -->
         <div class="d-flex gap-2 align-items-center mt-1">
            <select id="add-cat-type" class="form-select form-select-sm" style="width:100px;font-size:12px;">
               <option value="DEBIT">Debit</option>
               <option value="CREDIT">Credit</option>
            </select>
            <input id="add-cat-name" type="text" class="cat-name-input" placeholder="category name">
            <button class="btn btn-sm btn-outline-primary" style="font-size:12px;" onclick="addCategory()">
               <i class="fa-solid fa-plus"></i> Add
            </button>
            <span id="cat-msg" style="font-size:12px;"></span>
         </div>
      </div>
   </div>
</div>

<script>
var catRenameVals = {};

function loadCategories()
{
   fetch('ws/entry-categories/all', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(rows) { renderCategories(rows); })
      .catch(function() { showCatMsg('Failed to load categories.', 'danger'); });
}

function renderCategories(rows)
{
   var tbody = document.getElementById('cat-tbody');
   if (!rows.length)
   {
      tbody.innerHTML = '<tr><td colspan="3" class="text-muted text-center py-2">No categories.</td></tr>';
      return;
   }

   var html = '';
   rows.forEach(function(r)
   {
      var hidden    = r.is_active === 0;
      var typeLabel = r.entry_type === 'DEBIT'
         ? '<span class="cat-type-badge badge-debit">Debit</span>'
         : '<span class="cat-type-badge badge-credit">Credit</span>';

      var nameCell = '<input type="text" class="cat-name-input" id="cat-name-' + r.id + '" value="' + escHtml(r.name) + '"' + (hidden ? ' disabled' : '') + '>'
                   + ' <button class="btn btn-sm btn-outline-secondary ms-1" style="font-size:11px;padding:2px 7px;" onclick="renameCategory(' + r.id + ')" ' + (hidden ? 'disabled' : '') + '>Rename</button>';

      var visBtn = hidden
         ? '<button class="btn btn-sm btn-outline-success" style="font-size:11px;padding:2px 7px;" onclick="setVisibility(' + r.id + ',1)">Unhide</button>'
         : '<button class="btn btn-sm btn-outline-secondary" style="font-size:11px;padding:2px 7px;" onclick="setVisibility(' + r.id + ',0)">Hide</button>';

      html += '<tr class="' + (hidden ? 'hidden-row' : '') + '">'
            + '<td>' + typeLabel + '</td>'
            + '<td>' + nameCell + '</td>'
            + '<td>' + visBtn + '</td>'
            + '</tr>';
   });
   tbody.innerHTML = html;
}

function renameCategory(id)
{
   var input   = document.getElementById('cat-name-' + id);
   var newName = input.value.trim();
   if (!newName) { showCatMsg('Name cannot be empty.', 'danger'); return; }

   fetch('ws/entry-categories/' + id + '/rename',
   {
      method:      'PUT',
      credentials: 'same-origin',
      headers:     { 'Content-Type': 'application/json' },
      body:        JSON.stringify({ name: newName })
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok')
         showCatMsg('Renamed. ' + res.entries_updated + ' entr' + (res.entries_updated === 1 ? 'y' : 'ies') + ' updated.', 'success');
      else
         showCatMsg(res.msg || 'Rename failed.', 'danger');
      loadCategories();
   })
   .catch(function() { showCatMsg('Rename failed.', 'danger'); });
}

function setVisibility(id, isActive)
{
   fetch('ws/entry-categories/' + id + '/visibility',
   {
      method:      'PUT',
      credentials: 'same-origin',
      headers:     { 'Content-Type': 'application/json' },
      body:        JSON.stringify({ is_active: isActive })
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok')
         showCatMsg(isActive ? 'Category unhidden.' : 'Category hidden.', 'success');
      else
         showCatMsg(res.msg || 'Update failed.', 'danger');
      loadCategories();
   })
   .catch(function() { showCatMsg('Update failed.', 'danger'); });
}

function addCategory()
{
   var type = document.getElementById('add-cat-type').value;
   var name = document.getElementById('add-cat-name').value.trim();
   if (!name) { showCatMsg('Name cannot be empty.', 'danger'); return; }

   fetch('ws/entry-categories',
   {
      method:      'POST',
      credentials: 'same-origin',
      headers:     { 'Content-Type': 'application/json' },
      body:        JSON.stringify({ entry_type: type, name: name })
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status === 'ok')
      {
         document.getElementById('add-cat-name').value = '';
         showCatMsg('Category added.', 'success');
         loadCategories();
      }
      else
      {
         showCatMsg(res.msg || 'Add failed.', 'danger');
      }
   })
   .catch(function() { showCatMsg('Add failed.', 'danger'); });
}

function showCatMsg(msg, type)
{
   var el = document.getElementById('cat-msg');
   el.textContent = msg;
   el.className   = 'text-' + type;
   setTimeout(function() { el.textContent = ''; }, 3000);
}

function escHtml(s)
{
   return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

document.addEventListener('DOMContentLoaded', loadCategories);
</script>

<%@ include file="footer.jsp" %>
