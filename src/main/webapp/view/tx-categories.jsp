<%@ page contentType="text/html" pageEncoding="UTF-8" errorPage="error.jsp" isELIgnored="true" %>
<%@ page import="com.brentmi.budget.UserToken" %>
<% request.setAttribute("menuItem", "tx-categories"); %>
<%@ include file="header.jsp" %>

<style>
   .cat-table th, .cat-table td { font-size: 12px; vertical-align: middle; }
   .cat-row { cursor: pointer; }
   .cat-row:hover { background: #f8fafc; }
   .cat-row.open  { background: #f1f5f9; }
   .accordion-row td { padding: 0 !important; border-top: none; }
   .accordion-panel { background: #f8fafc; border-left: 3px solid #3b82f6; padding: 16px 20px; }
   .narr-table th, .narr-table td { font-size: 12px; }
   .badge-high { background: #dcfce7; color: #166534; font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 3px; }
   .badge-med  { background: #fef9c3; color: #854d0e; font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 3px; }
   .badge-low  { background: #fee2e2; color: #991b1b; font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 3px; }
   .inline-input { border: 1px solid #cbd5e1; border-radius: 4px; padding: 3px 7px; font-size: 12px; }
   .btn-xs { font-size: 11px; padding: 2px 8px; }
   .retro-note { font-size: 11px; color: #64748b; margin-top: 4px; }
</style>

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
   <h5 class="mb-0">Categories</h5>
   <button class="btn btn-sm btn-primary" onclick="showAddCategory()">
      <i class="fa-solid fa-plus me-1"></i>Add Category
   </button>
</div>

<!-- Add category inline form (hidden by default) -->
<div id="add-cat-form" class="card shadow-sm mb-3" style="display:none;">
   <div class="card-body" style="padding:14px 18px;">
      <div class="d-flex gap-3 align-items-end flex-wrap">
         <div>
            <label style="font-size:11px;font-weight:600;color:#64748b;display:block;margin-bottom:3px;">Name</label>
            <input type="text" id="new-cat-name" class="inline-input" style="width:200px;" placeholder="Category name">
         </div>
         <div>
            <label style="font-size:11px;font-weight:600;color:#64748b;display:block;margin-bottom:3px;">Note</label>
            <input type="text" id="new-cat-note" class="inline-input" style="width:300px;" placeholder="Optional note">
         </div>
         <div class="d-flex gap-2">
            <button class="btn btn-sm btn-success btn-xs" onclick="saveNewCategory()">Save</button>
            <button class="btn btn-sm btn-secondary btn-xs" onclick="hideAddCategory()">Cancel</button>
         </div>
      </div>
      <div id="add-cat-error" class="text-danger mt-2" style="font-size:12px;display:none;"></div>
   </div>
</div>

<!-- Categories table -->
<div class="card shadow-sm">
   <div class="card-body p-0">
      <table class="table table-sm cat-table mb-0" id="cat-table">
         <thead style="background:#f8fafc;">
            <tr>
               <th style="width:220px;">Name</th>
               <th>Note</th>
               <th style="width:100px;"></th>
            </tr>
         </thead>
         <tbody id="cat-tbody">
            <tr><td colspan="3" style="font-size:12px;color:#94a3b8;padding:16px;">Loading...</td></tr>
         </tbody>
      </table>
   </div>
</div>

<script>
var allCategories  = [];   // [{ id, name, note }]
var openAccordionId = null; // currently expanded category id

document.addEventListener('DOMContentLoaded', loadCategories);

// Load categories
function loadCategories()
{
   fetch('ws/tx-categories', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(data)
      {
         allCategories = data;
         renderCategoryTable();
      })
      .catch(function(e) { console.error('loadCategories failed', e); });
}

function renderCategoryTable()
{
   var tbody = document.getElementById('cat-tbody');
   if (!allCategories.length)
   {
      tbody.innerHTML = '<tr><td colspan="3" style="font-size:12px;color:#94a3b8;padding:16px;">No categories found.</td></tr>';
      openAccordionId = null;
      return;
   }

   var html = '';
   allCategories.forEach(function(cat)
   {
      var isOpen = openAccordionId === cat.id;
      html += '<tr class="cat-row' + (isOpen ? ' open' : '') + '" id="cat-row-' + cat.id + '" data-id="' + cat.id + '" onclick="toggleAccordion(' + cat.id + ')">'
            + '<td id="cat-name-cell-' + cat.id + '">' + escHtml(cat.name) + '</td>'
            + '<td id="cat-note-cell-' + cat.id + '">' + escHtml(cat.note || '') + '</td>'
            + '<td onclick="event.stopPropagation();">'
            +    '<button class="btn btn-sm btn-outline-secondary btn-xs me-1" onclick="startEditCategory(' + cat.id + ')">Edit</button>'
            + '</td>'
            + '</tr>'
            + '<tr class="accordion-row" id="accordion-row-' + cat.id + '" style="display:' + (isOpen ? 'table-row' : 'none') + ';">'
            + '<td colspan="3"><div class="accordion-panel" id="accordion-panel-' + cat.id + '">Loading...</div></td>'
            + '</tr>';
   });
   tbody.innerHTML = html;

   // Re-open accordion if one was open
   if (openAccordionId !== null)
      loadNarratives(openAccordionId);
}

// Accordion toggle
function toggleAccordion(catId)
{
   // If the row is in edit mode, don't toggle
   if (document.getElementById('cat-edit-row-' + catId))
      return;

   if (openAccordionId === catId)
   {
      // Close
      document.getElementById('accordion-row-' + catId).style.display = 'none';
      document.getElementById('cat-row-' + catId).classList.remove('open');
      openAccordionId = null;
      return;
   }

   // Close any previously open accordion
   if (openAccordionId !== null)
   {
      var prev = document.getElementById('accordion-row-' + openAccordionId);
      if (prev) prev.style.display = 'none';
      var prevRow = document.getElementById('cat-row-' + openAccordionId);
      if (prevRow) prevRow.classList.remove('open');
   }

   openAccordionId = catId;
   document.getElementById('accordion-row-' + catId).style.display = 'table-row';
   document.getElementById('cat-row-' + catId).classList.add('open');
   loadNarratives(catId);
}

// Edit category inline
function startEditCategory(catId)
{
   var cat = allCategories.find(function(c) { return c.id === catId; });
   if (!cat) return;

   document.getElementById('cat-name-cell-' + catId).innerHTML =
      '<input type="text" id="edit-cat-name-' + catId + '" class="inline-input" style="width:180px;" value="' + escAttr(cat.name) + '">';
   document.getElementById('cat-note-cell-' + catId).innerHTML =
      '<input type="text" id="edit-cat-note-' + catId + '" class="inline-input" style="width:100%;" value="' + escAttr(cat.note || '') + '">';

   var actionCell = document.querySelector('#cat-row-' + catId + ' td:last-child');
   actionCell.innerHTML =
      '<button class="btn btn-sm btn-success btn-xs me-1" onclick="event.stopPropagation();saveCategory(' + catId + ')">Save</button>'
      + '<button class="btn btn-sm btn-secondary btn-xs" onclick="event.stopPropagation();cancelEditCategory(' + catId + ')">Cancel</button>';
}

function cancelEditCategory(catId)
{
   renderCategoryTable();
}

function saveCategory(catId)
{
   var name = document.getElementById('edit-cat-name-' + catId).value.trim();
   var note = document.getElementById('edit-cat-note-' + catId).value.trim();
   if (!name) { alert('Category name cannot be empty.'); return; }

   fetch('ws/tx-categories/' + catId, {
      method: 'PUT',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: name, note: note })
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status !== 'ok') { alert('Save failed: ' + (res.msg || 'unknown error')); return; }
      var cat = allCategories.find(function(c) { return c.id === catId; });
      if (cat) { cat.name = name; cat.note = note; }
      renderCategoryTable();
   })
   .catch(function(e) { console.error('saveCategory failed', e); });
}

// Add category
function showAddCategory()
{
   document.getElementById('add-cat-form').style.display = 'block';
   document.getElementById('new-cat-name').focus();
}

function hideAddCategory()
{
   document.getElementById('add-cat-form').style.display = 'none';
   document.getElementById('new-cat-name').value = '';
   document.getElementById('new-cat-note').value = '';
   document.getElementById('add-cat-error').style.display = 'none';
}

function saveNewCategory()
{
   var name = document.getElementById('new-cat-name').value.trim();
   var note = document.getElementById('new-cat-note').value.trim();
   var errEl = document.getElementById('add-cat-error');
   errEl.style.display = 'none';

   if (!name) { errEl.textContent = 'Name is required.'; errEl.style.display = 'block'; return; }

   fetch('ws/tx-categories', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: name, note: note })
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status !== 'ok') { errEl.textContent = res.msg || 'Save failed.'; errEl.style.display = 'block'; return; }
      hideAddCategory();
      loadCategories();
   })
   .catch(function(e) { console.error('saveNewCategory failed', e); });
}

// Narratives
function loadNarratives(catId)
{
   var panel = document.getElementById('accordion-panel-' + catId);
   if (!panel) return;
   panel.innerHTML = '<span style="font-size:12px;color:#94a3b8;">Loading...</span>';

   fetch('ws/tx-categories/' + catId + '/narratives', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(rows) { renderNarrativePanel(catId, rows); })
      .catch(function(e) { console.error('loadNarratives failed', e); });
}

function renderNarrativePanel(catId, rows)
{
   var panel = document.getElementById('accordion-panel-' + catId);
   if (!panel) return;

   var html = '<div class="d-flex justify-content-between align-items-center mb-2">'
            + '<span style="font-size:11px;font-weight:700;letter-spacing:0.06em;text-transform:uppercase;color:#64748b;">Narrative Rules</span>'
            + '<button class="btn btn-sm btn-outline-primary btn-xs" onclick="showAddNarrative(' + catId + ')">+ Add Rule</button>'
            + '</div>';

   if (!rows.length)
   {
      html += '<div style="font-size:12px;color:#94a3b8;">No rules defined.</div>';
   }
   else
   {
      html += '<table class="table table-sm narr-table mb-0">'
            + '<thead><tr>'
            + '<th style="width:200px;">Category</th>'
            + '<th>Pattern</th>'
            + '<th style="width:100px;">Match Type</th>'
            + '<th style="width:90px;">Confidence</th>'
            + '<th style="width:80px;"></th>'
            + '</tr></thead>'
            + '<tbody id="narr-tbody-' + catId + '">';

      rows.forEach(function(n)
      {
         html += buildNarrativeRow(n, false);
      });
      html += '</tbody></table>';
   }

   // Add-narrative form placeholder
   html += '<div id="add-narr-form-' + catId + '" style="display:none;margin-top:12px;">'
         + buildAddNarrativeForm(catId)
         + '</div>';

   panel.innerHTML = html;
}

function buildNarrativeRow(n, editMode)
{
   if (editMode)
   {
      var catOptions = buildCategoryOptions(n.id, n.trx_category_id);
      return '<tr id="narr-row-' + n.id + '">'
           + '<td>' + catOptions + '</td>'
           + '<td><input type="text" id="narr-pattern-' + n.id + '" class="inline-input" style="width:100%;" value="' + escAttr(n.pattern) + '"></td>'
           + '<td>' + buildMatchTypeSelect('narr-match-' + n.id, n.match_type) + '</td>'
           + '<td>' + buildConfidenceSelect('narr-conf-' + n.id, n.confidence) + '</td>'
           + '<td>'
           +    '<button class="btn btn-sm btn-success btn-xs me-1" onclick="saveNarrative(' + n.id + ', ' + n.trx_category_id + ')">Save</button>'
           +    '<button class="btn btn-sm btn-secondary btn-xs" onclick="cancelEditNarrative(' + n.id + ', ' + n.trx_category_id + ')">Cancel</button>'
           + '</td>'
           + '</tr>';
   }

   var confClass = n.confidence === 'high' ? 'badge-high' : n.confidence === 'medium' ? 'badge-med' : 'badge-low';
   return '<tr id="narr-row-' + n.id + '">'
        + '<td>' + escHtml(n.category_name) + '</td>'
        + '<td style="font-family:monospace;">' + escHtml(n.pattern) + '</td>'
        + '<td>' + escHtml(n.match_type) + '</td>'
        + '<td><span class="' + confClass + '">' + escHtml(n.confidence) + '</span></td>'
        + '<td><button class="btn btn-sm btn-outline-secondary btn-xs" onclick="startEditNarrative(' + n.id + ', ' + n.trx_category_id + ')">Edit</button></td>'
        + '</tr>';
}

function buildCategoryOptions(narrativeId, selectedId)
{
   var html = '<select id="narr-catid-' + narrativeId + '" class="form-select form-select-sm" style="font-size:12px;width:180px;">';
   allCategories.forEach(function(cat)
   {
      html += '<option value="' + cat.id + '"' + (cat.id === selectedId ? ' selected' : '') + '>' + escHtml(cat.name) + '</option>';
   });
   html += '</select>';
   return html;
}

function buildMatchTypeSelect(id, selected)
{
   return '<select id="' + id + '" class="form-select form-select-sm" style="font-size:12px;width:120px;">'
        + '<option value="contains"'    + (selected === 'contains'    ? ' selected' : '') + '>contains</option>'
        + '<option value="starts_with"' + (selected === 'starts_with' ? ' selected' : '') + '>starts_with</option>'
        + '</select>';
}

function buildConfidenceSelect(id, selected)
{
   return '<select id="' + id + '" class="form-select form-select-sm" style="font-size:12px;width:90px;">'
        + '<option value="high"  ' + (selected === 'high'   ? ' selected' : '') + '>high</option>'
        + '<option value="medium"' + (selected === 'medium' ? ' selected' : '') + '>medium</option>'
        + '<option value="low"  '  + (selected === 'low'    ? ' selected' : '') + '>low</option>'
        + '</select>';
}

function buildAddNarrativeForm(catId)
{
   var catOptions = '<select id="add-narr-cat-' + catId + '" class="form-select form-select-sm" style="font-size:12px;width:180px;">';
   allCategories.forEach(function(cat)
   {
      catOptions += '<option value="' + cat.id + '"' + (cat.id === catId ? ' selected' : '') + '>' + escHtml(cat.name) + '</option>';
   });
   catOptions += '</select>';

   return '<div style="border-top:1px solid #e2e8f0;padding-top:10px;">'
        + '<span style="font-size:11px;font-weight:700;letter-spacing:0.06em;text-transform:uppercase;color:#64748b;display:block;margin-bottom:8px;">New Rule</span>'
        + '<div class="d-flex gap-2 align-items-end flex-wrap">'
        + '<div><label style="font-size:11px;color:#64748b;display:block;margin-bottom:2px;">Category</label>' + catOptions + '</div>'
        + '<div style="flex:1;min-width:140px;"><label style="font-size:11px;color:#64748b;display:block;margin-bottom:2px;">Pattern</label>'
        +    '<input type="text" id="add-narr-pattern-' + catId + '" class="inline-input" style="width:100%;" placeholder="e.g. NETFLIX"></div>'
        + '<div><label style="font-size:11px;color:#64748b;display:block;margin-bottom:2px;">Match Type</label>'
        +    buildMatchTypeSelect('add-narr-match-' + catId, 'contains') + '</div>'
        + '<div><label style="font-size:11px;color:#64748b;display:block;margin-bottom:2px;">Confidence</label>'
        +    buildConfidenceSelect('add-narr-conf-' + catId, 'high') + '</div>'
        + '<div class="d-flex gap-2">'
        +    '<button class="btn btn-sm btn-success btn-xs" onclick="saveNewNarrative(' + catId + ')">Save</button>'
        +    '<button class="btn btn-sm btn-secondary btn-xs" onclick="hideAddNarrative(' + catId + ')">Cancel</button>'
        + '</div></div>'
        + '<div id="add-narr-error-' + catId + '" class="text-danger mt-2" style="font-size:12px;display:none;"></div>'
        + '</div>';
}

function showAddNarrative(catId)
{
   document.getElementById('add-narr-form-' + catId).style.display = 'block';
}

function hideAddNarrative(catId)
{
   document.getElementById('add-narr-form-' + catId).style.display = 'none';
}

function saveNewNarrative(catId)
{
   var catSelect  = document.getElementById('add-narr-cat-' + catId);
   var pattern    = document.getElementById('add-narr-pattern-' + catId).value.trim();
   var matchType  = document.getElementById('add-narr-match-' + catId).value;
   var confidence = document.getElementById('add-narr-conf-' + catId).value;
   var errEl      = document.getElementById('add-narr-error-' + catId);
   errEl.style.display = 'none';

   if (!pattern) { errEl.textContent = 'Pattern is required.'; errEl.style.display = 'block'; return; }

   var selectedCatId = parseInt(catSelect.value, 10);

   fetch('ws/tx-categories/narrative', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ trx_category_id: selectedCatId, pattern: pattern, confidence: confidence, match_type: matchType })
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status !== 'ok') { errEl.textContent = res.msg || 'Save failed.'; errEl.style.display = 'block'; return; }
      loadNarratives(catId);
   })
   .catch(function(e) { console.error('saveNewNarrative failed', e); });
}

// Edit narrative
var narrativeCache = {};  // catId -> [rows] so we can find original values for cancel

function startEditNarrative(narrativeId, catId)
{
   // Find the narrative data from the current table row
   // Re-fetch to get current data reliably
   fetch('ws/tx-categories/' + catId + '/narratives', { credentials: 'same-origin' })
      .then(function(r) { return r.json(); })
      .then(function(rows)
      {
         narrativeCache[catId] = rows;
         var n = rows.find(function(r) { return r.id === narrativeId; });
         if (!n) return;
         var row = document.getElementById('narr-row-' + narrativeId);
         if (row) row.outerHTML = buildNarrativeRow(n, true);
      })
      .catch(function(e) { console.error('startEditNarrative failed', e); });
}

function cancelEditNarrative(narrativeId, catId)
{
   var rows = narrativeCache[catId] || [];
   var n    = rows.find(function(r) { return r.id === narrativeId; });
   if (!n) { loadNarratives(catId); return; }
   var row = document.getElementById('narr-row-' + narrativeId);
   if (row) row.outerHTML = buildNarrativeRow(n, false);
}

function saveNarrative(narrativeId, catId)
{
   var catSel     = document.getElementById('narr-catid-' + narrativeId);
   var pattern    = document.getElementById('narr-pattern-' + narrativeId).value.trim();
   var matchType  = document.getElementById('narr-match-' + narrativeId).value;
   var confidence = document.getElementById('narr-conf-' + narrativeId).value;

   if (!pattern) { alert('Pattern cannot be empty.'); return; }

   var newCatId = parseInt(catSel.value, 10);

   fetch('ws/tx-categories/narrative/' + narrativeId, {
      method: 'PUT',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ trx_category_id: newCatId, pattern: pattern, confidence: confidence, match_type: matchType })
   })
   .then(function(r) { return r.json(); })
   .then(function(res)
   {
      if (res.status !== 'ok') { alert('Save failed: ' + (res.msg || 'unknown error')); return; }
      if (res.retro_updated > 0)
         console.log('Retrospectively reclassified ' + res.retro_updated + ' transaction(s).');
      // If category changed, open the destination category's accordion
      if (newCatId !== catId)
         openAccordionId = newCatId;
      renderCategoryTable();
      loadNarratives(openAccordionId);
   })
   .catch(function(e) { console.error('saveNarrative failed', e); });
}

// Utilities
function escHtml(s)
{
   return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
}

function escAttr(s)
{
   return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/'/g, '&#39;')
      .replace(/</g, '&lt;').replace(/>/g, '&gt;');
}
</script>

<%@ include file="footer.jsp" %>
