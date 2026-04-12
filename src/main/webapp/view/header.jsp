<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.brentmi.budget.UserToken"%>
<%@page import="com.brentmi.budget.RuntimeEnv"%>
<%
   UserToken ut = null; 
   if(request.getSession().getAttribute("userToken") != null)
      ut = (UserToken)request.getSession().getAttribute("userToken");
   
   String menuItem = "";
   if(request.getAttribute("menuItem") != null)
      menuItem = (String)request.getAttribute("menuItem");
      
   String platform = RuntimeEnv.getPlatform();
%>
<!DOCTYPE html>
<html>
   <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <meta name="description" content="">
      <meta name="author" content="">
      <title>BUDGET API</title>

      <link rel="shortcut icon" href="https://www.foxtel.com.au/content/dam/foxtel/icons/favicon.ico">
      
      <link href="view/css/bootstrap.min.css" rel="stylesheet">
      <link href="view/css/dataTables.bootstrap5.min.css" rel="stylesheet">
      
      <link href="view/css/simple-sidebar.css" rel="stylesheet">
      <link href="view/font-awesome-6.7.2/css/all.min.css" rel="stylesheet">
      <link rel="stylesheet" type="text/css" href="view/css/channelplan-dev-blue.css">
      <link href="view/css/html-gadgets.css" rel="stylesheet">

      <%
         String notice = "<span class=\"badge text-bg-danger local-lable\"> PRODUCTION</span>";

         if(platform.equals("pts"))
            notice = "<span class=\"badge text-bg-warning local-lable\"> PTS</span>";
         else if(platform.contains("_dev"))
            notice = "<span class=\"badge text-bg-success local-lable\"> DEVELOPMENT</span>";

      %>
      <script src="view/js/btcps-scheduler-input-validation.js?X4477"></script>
      <script src="view/js/jquery-3.7.1.min.js"></script>
      <script src="view/js/jquery.dataTables.min.js"></script>
      <script src="view/js/bootstrap.bundle.min.js"></script>
      <script src="view/js/dataTables.bootstrap5.min.js"></script>
      
      <script type="text/javascript" src="view/js/ajax.js"></script>
      <script type="text/javascript" src="view/js/btcps.js"></script>
 
      <script src="view/js/moment.js" type="text/javascript"></script>

      <link href="view/css/diff2html.min.css" rel="stylesheet">
      <script src="view/js/diff2html.min.js" type="text/javascript"></script>
      
      
      <script type="text/javascript">
         function locationChange(url)
         {
            window.location = url + '?redirect=true';
         }
         
         function Onload() 
         {
       
         }

         if (window.addEventListener)
            window.addEventListener("load", Onload, false);
         else if (window.attachEvent)
            window.attachEvent("onload", Onload);
         else 
            window.onload = Onload;
         
         function closeServiceMessageModal()
         {
            var span = document.getElementsByClassName("close")[0];
            document.getElementById('serviceMessageModal').style.display = 'none';
         }

</script>
      <style>
         /* ── environment badge ─────────────────────────────────── */
         .local-lable {
            min-width: 110px !important;
            display: inline-block !important;
            font-size: 11px !important;
            font-weight: 700 !important;
            letter-spacing: 0.06em !important;
            padding: 6px 12px !important;
            margin-right: 20px;
            border-radius: 3px !important;
            color: #fff !important;
         }
         .text-bg-success.local-lable { background-color: #198754 !important; }
         .text-bg-warning.local-lable { background-color: #b8860b !important; }
         .text-bg-danger.local-lable  { background-color: #a63228 !important; }

         /* ── navbar dark theme ─────────────────────────────────── */
         .navbar.navbar-dark {
            background: #1a1f2e !important;
            border: none !important;
            border-radius: 0 !important;
            box-shadow: 0 1px 4px rgba(0,0,0,0.4) !important;
            margin-bottom: 0 !important;
            padding: 0 12px !important;
            min-height: 50px !important;
            display: -webkit-flex !important;
            display: flex !important;
            -webkit-align-items: center !important;
            align-items: center !important;
            flex-wrap: nowrap !important;
         }
         .fixed-brand {
            display: -webkit-flex !important;
            display: flex !important;
            -webkit-align-items: center !important;
            align-items: center !important;
            gap: 4px !important;
            flex-shrink: 0 !important;
            width: 240px;
         }
         .navbar.navbar-dark .navbar-brand { color: #f0f4f8 !important; font-weight: 600 !important; }
         .navbar.navbar-dark .navbar-brand:hover { color: #fff !important; background: none !important; }
         .navbar.navbar-dark .navbar-toggler { border-color: transparent !important; background: none !important; padding: 6px 8px !important; }
         .navbar.navbar-dark .navbar-toggler:hover,
         .navbar.navbar-dark .navbar-toggler:focus { background: rgba(255,255,255,0.08) !important; box-shadow: none !important; }
         .navbar.navbar-dark .navbar-toggler .fa-solid { color: #94a3b8; font-size: 16px; }
         .navbar.navbar-dark .navbar-toggler:hover .fa-solid { color: #fff; }

         /* ── table font override ───────────────────────────────── */
         td, th, td *, th * {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
            font-size: 14px !important;
         }

         /* ── page background & full-page layout ────────────────── */
         :root {
            --bs-body-color: #333;
            --bs-body-font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            --bs-body-font-size: 14px;
            --bs-body-bg: #f0f2f5;
         }
         html, body { height: auto !important; }
         body { background-color: #f0f2f5 !important; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important; font-size: 14px !important; color: #333 !important; }
         #wrapper { position: relative !important; min-height: calc(100vh - 60px) !important; overflow-x: hidden !important; overflow-y: visible !important; }
         #page-content-wrapper { background: #f0f2f5; padding: 24px !important; overflow: visible !important; min-height: calc(100vh - 60px) !important; box-sizing: border-box !important; }

         /* ── sidebar panel ─────────────────────────────────────── */
         #sidebar-wrapper { background: #1e2738 !important; height: auto !important; min-height: 100% !important; }

         /* ── sidebar nav rows ──────────────────────────────────── */
         .sidebar-nav li { text-indent: 0 !important; line-height: 1 !important; }

         .sidebar-nav li.sidebar-section-label {
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            color: #3d4f6b;
            padding: 14px 16px 4px;
            line-height: 1;
            cursor: default;
            pointer-events: none;
         }

         .sidebar-nav li > a {
            display: -webkit-flex !important;
            display: flex !important;
            -webkit-align-items: center;
            align-items: center;
            gap: 10px;
            padding: 10px 16px !important;
            color: #94a3b8 !important;
            text-decoration: none !important;
            white-space: nowrap;
            overflow: hidden;
            border-left: 3px solid transparent !important;
            -webkit-transition: background 0.15s, color 0.15s, border-color 0.15s;
            transition: background 0.15s, color 0.15s, border-color 0.15s;
            background: none !important;
         }
         .sidebar-nav li > a:hover {
            background: rgba(255,255,255,0.05) !important;
            color: #e2e8f0 !important;
            border-left-color: rgba(229,62,62,0.4) !important;
         }
         .sidebar-nav li > a:focus,
         .sidebar-nav li > a:active { text-decoration: none !important; outline: none; }

         .sidebar-nav li.active > a {
            background: rgba(229,62,62,0.12) !important;
            color: #fc8181 !important;
            border-left-color: #e53e3e !important;
         }

         .nav-icon {
            font-size: 14px;
            width: 18px;
            text-align: center;
            -webkit-flex-shrink: 0;
            flex-shrink: 0;
         }

         /* ── sub-menus ─────────────────────────────────────────── */
         .sidebar-nav ul {
            background: rgba(0,0,0,0.18) !important;
            padding: 0;
            margin: 0;
         }
         .sidebar-nav ul li > a {
            padding: 8px 16px 8px 44px !important;
            font-size: 13px !important;
            color: #64748b !important;
            border-left: 3px solid transparent !important;
         }
         .sidebar-nav ul li > a:hover {
            background: rgba(255,255,255,0.04) !important;
            color: #cbd5e0 !important;
            border-left-color: rgba(229,62,62,0.3) !important;
         }
         .sidebar-nav ul li.active > a {
            background: rgba(229,62,62,0.10) !important;
            color: #fc8181 !important;
            border-left-color: #e53e3e !important;
         }
      </style>
   </head>
   <body>
      <nav class="navbar navbar-dark no-margin">
         <!-- Brand and toggle get grouped for better mobile display -->
         <div class="fixed-brand">
            <button type="button" class="navbar-toggler" id="menu-toggle">
               <i class="fa-solid fa-bars" aria-hidden="true"></i>
            </button>
            <button type="button" class="navbar-toggler" id="menu-toggle-2">
               <i class="fa-solid fa-indent" aria-hidden="true"></i>
            </button>
            <a class="navbar-brand" href="#" style="font-size: 15px; letter-spacing: 0.04em;">SoftboxAI Budget</a>
         </div>
         <div id="nav-title" class="navbar-brand" style="padding-left: 0px; flex: 1; display: flex; align-items: center; font-size: 15px; letter-spacing: 0.04em;"><%=notice %></div>
      </nav>
      <div id="wrapper" class="">
         <!-- Sidebar -->
         <form name="menuform" action="v1" method="POST">
         <div id="sidebar-wrapper" style="height: calc">
            <ul class="sidebar-nav" id="menu">
               <li>
                  <a href="/budgetapi?logout=1"><i class="fa-solid fa-right-from-bracket nav-icon"></i> Logout</a>
               </li>
               <%
                  if(ut != null)
                  {
    
               %>
                        <li class="sidebar-section-label">Budget Manage</li>
                     <li>
                        <a href="#"><i class="fa-solid fa-tv nav-icon"></i> Budget View</a>
                        <ul>
                           <li <%=menuItem.equals("pg-dashboard")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-dashboard"><i class="fa-solid fa-pencil nav-icon"></i> Dashboard</a>
                           </li>
                           <li <%=menuItem.equals("pg-summary")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-summary"><i class="fa-solid fa-pencil nav-icon"></i> Summary</a>
                           </li>
                           <li <%=menuItem.equals("pg-worksheet")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-worksheet"><i class="fa-solid fa-pencil nav-icon"></i> Worksheet</a>
                           </li>
                           <li <%=menuItem.equals("pg-monthly")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-monthly"><i class="fa-solid fa-pencil nav-icon"></i> Monthly</a>
                           </li>
                           <li <%=menuItem.equals("pg-yearly")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-yearly"><i class="fa-solid fa-pencil nav-icon"></i> Yearly</a>
                           </li>
                           <li <%=menuItem.equals("pg-archive")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-archive"><i class="fa-solid fa-pencil nav-icon"></i> Archives</a>
                           </li>
                           <li <%=menuItem.equals("pg-fixed-input")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-fixed-input"><i class="fa-solid fa-pencil nav-icon"></i> Fixed Inputs</a>
                           </li>
                           <li <%=menuItem.equals("pg-super")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-super"><i class="fa-solid fa-pencil nav-icon"></i> Superannuation</a>
                           </li>
                           <li <%=menuItem.equals("pg-categories")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-categories"><i class="fa-solid fa-pencil nav-icon"></i> Categories</a>
                           </li>
                           <li <%=menuItem.equals("pg-settings")?"class=\"active\"":"" %>>
                              <a href="/budgetapi?rq=pg-settings"><i class="fa-solid fa-pencil nav-icon"></i> Settings</a>
                           </li>
                           
                        </ul>
                     </li>
                        
                        <li class="sidebar-section-label">Auditing</li>
                        <li>
                           <a href="#"><i class="fa-solid fa-sitemap nav-icon"></i> Audit Logs</a>
                           <ul>
                              <li <%=menuItem.equals("auditlog")?"class=\"active\"":"" %>>
                                 <a href="/budgetapi?rq=auditlog"><i class="fa-regular fa-file-lines nav-icon"></i> History Log</a>
                              </li>
                           </ul>
                        </li>
               <%
                  }
               %>
            </ul>
         </div><!-- /#sidebar-wrapper -->
      </form>
         <!-- Page Content -->
         <div id="page-content-wrapper" >
            <div class="container-fluid xyz">
               <div class="row">
                  <div class="col-lg-12">
                     <div id="serviceMessageModal" class="modal" style="padding-top: 200px;"></div>