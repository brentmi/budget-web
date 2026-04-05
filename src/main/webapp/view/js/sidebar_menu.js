$("#menu-toggle").click(function (e) 
{
   e.preventDefault();
   $("#wrapper").toggleClass("toggled");
});
$("#menu-toggle-2").click(function (e)
{
   e.preventDefault();
   var wrapper = $("#wrapper");
   if (wrapper.hasClass("toggled"))
   {
      // Coming from fully hidden: switch to icon-only mode
      wrapper.removeClass("toggled").addClass("toggled-2");
   }
   else
   {
      wrapper.toggleClass("toggled-2");
   }
   $('#menu ul').hide();
});

function initMenu() 
{
   $('#menu ul').hide();
   $('#menu ul').children('.current').parent().show();
   //$('#menu ul:first').show();

   $('#menu li a').click
   (
      function () 
      {
         var checkElement = $(this).next();
         if ((checkElement.is('ul')) && (checkElement.is(':visible'))) 
         {
            // Comment our this line to prevent an expanded menu
            // from rolling up if the active element resides in it.
            $('#menu ul:visible').slideUp('normal');
            return false;
         }
         
         if ((checkElement.is('ul')) && (!checkElement.is(':visible'))) 
         {
            $('#menu ul:visible').slideUp('normal');
            checkElement.slideDown('normal');
            return false;
         }
      }
   );

   // This section will expand the currently selected
   // element based on it having the 'active' class set.
   // This needs to be done server side eg;
   // String page = request.getAttribute("something") to determine
   // what page is being called. Then apply the "active"
   // class to the menue for the return eg;
   // <li <%=page.equals("mypage")?"class=\"active\"":"" %>>
   $('#menu li').each(function (i, val)
   {
      if ($(val).hasClass("active"))
      {
         var e = $(val).parent('ul');
         e.slideDown('normal');
         return false;
      }
   });
}
$(document).ready(function () 
{
   initMenu();
});
