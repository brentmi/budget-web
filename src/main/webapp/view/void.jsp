<%@ include file="header.jsp" %>
<script>
   if(window.location.search.indexOf('vendorId') !== -1)
      history.replaceState(null, '', window.location.pathname + '?redirect=true');
</script>
<p></p>
<h3>Login OK.</h3>
   <p></p>
<h3>Please select an option from the left hand menu to continue.</h3>
<%@ include file="footer.jsp" %>
