<%@page import="org.apache.commons.codec.binary.Base64"%>
<%@ page isErrorPage = "true" %>
<%
   String msg = "Unknown";
   if(exception != null && exception.getMessage() != null)
      msg = exception.getMessage();
   else if(request.getAttribute("usermessage") != null)
      msg = (String)request.getAttribute("usermessage");
%>
<html>
   
   <script>document.location = '/budgetapi?Exception=<%=Base64.encodeBase64URLSafeString(msg.getBytes()) %>';</script>
</html>
