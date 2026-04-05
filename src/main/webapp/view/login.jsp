<%@ include file="header.jsp" %>
   <script type="text/javascript">
      document.getElementById('nav-title').innerHTML = document.getElementById('nav-title').innerHTML + '** Login time! **';
   </script>
   <%
     if(request.getAttribute("usermessage") != null)
     {
   %>
   <h2><%=request.getAttribute("usermessage") %></h2>
   <%  
     }
   %>   
   <form name="loginform" action="" method="POST">
      <table>
         <%
            String ldap = request.getServletContext().getInitParameter("LDAP-ENABLED");
            if(ldap != null && ldap.equalsIgnoreCase("false"))
            {   
             %>
               <tr>
                  <td>Username:&nbsp;</td><td><input type="text" size="20" name="user"></td>
               </tr>
               <tr>
                  <td>Password:&nbsp;</td><td><input type="password" size="20" name="pass"></td>
               </tr>
             <%
             }
             %>
         <tr>
            <td colspan="2"><button class="btn btn-secondary btn-sm" style="width: 115px; font-size: 12px; padding: 2px 12px;" type="submit" name="loginsubmit" value="loginsubmit">Login</button></td>
         </tr>
      </table>
   </form>
<%@ include file="footer.jsp" %>