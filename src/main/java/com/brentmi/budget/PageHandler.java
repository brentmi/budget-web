/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import java.io.PrintWriter;
import java.util.Iterator;
import java.util.Map;
import jakarta.servlet.http.HttpServletRequest;
import org.apache.commons.codec.binary.Base64;
import org.apache.commons.codec.binary.StringUtils;
import com.brentmi.budget.UserToken;

/**
 *
 * @author milingtonb
 */
public class PageHandler
{
   public String handle(HttpServletRequest request, PrintWriter out) throws Exception
   {
      //out.write(requestToString(request));
      boolean debug = Boolean.valueOf(request.getServletContext().getInitParameter("debug"));
      
      UserToken t = ((UserToken)request.getSession().getAttribute("userToken"));
      if(t != null)
      {   
         System.out.println("PageHandler -> UserToken: Session");
      }
      else
         System.out.println("PageHandler -> UserToken: null");
      
      
      
      if(request.getParameter("loginsubmit") != null || request.getParameter("redirect") != null)
      {
         if(debug)
         {
            if(request.getParameter("loginsubmit") != null)
               System.out.println("NOT NULL => Got loginsubmit: " + requestToString(request));
            else
               System.out.println("NOT NULL => Got redirect: " + requestToString(request));
         }
         
         return "view/void.jsp"; // Pressed F5 or strait after logging in.
      }
      
      if(request.getParameter("logout") != null)
      {   
         request.getSession().setAttribute("userToken", null);
         request.getSession().invalidate();
         
         if(debug)
            System.out.println("Logout request -> return view/login.jsp ==> " + requestToString(request));
         
         if(t != null)
            return "view/login.jsp";
         
         
      }
  
    
      
      // Edit / display pages
      if(request.getParameter("rq") != null)
      {   
         request.setAttribute("menuItem", request.getParameter("rq"));
         String next = "view/"+request.getParameter("rq")+".jsp";
         if(request.getParameterMap().size() > 1)
         {
            next += "?";
            Map<String, String[]> map = request.getParameterMap();
            Iterator<String> it = map.keySet().iterator();
            while(it.hasNext())
            {
               String name = it.next();
               if(name.equals("rq"))
                  continue;
               
               next += name + "=";
               if(map.get(name).length > 0)
                  next += map.get(name)[0];
               else
                  next += "unknown";
            }
         }
         return next;
         //return "view/"+request.getParameter("rq")+".jsp";
      }
      
      request.setAttribute("usermessage", "An unknown error has occurred!<p></p>" + requestToString(request));
      return "view/message.jsp";
   }
   
   public String requestToString(HttpServletRequest request)
   {
      boolean isException = false;
      StringBuilder b = new StringBuilder();
      Map<String, String[]> map = request.getParameterMap();
      
      b.append("ParamMap has the following attributes:<br>");
      Iterator<String> it = map.keySet().iterator();
      while(it.hasNext())
      {
         String name = it.next();
         String[] values = map.get(name);
         if(name.equals("Exception"))
         {
            try
            {   
               b.delete(0, b.length());
               b.append(name).append(": ");
               for(int i = 0; i < values.length; i++)
                  b.append(StringUtils.newStringUtf8(Base64.decodeBase64(values[i]))).append("<br />");
            }
            catch(Exception e)
            {
               b.delete(0, b.length());
               b.append(name).append(": ").append(e.getMessage());
            }
            
            break;
         }
         
         b.append("KeyName=").append(name).append(" [String]: ");
         for(int i = 0; i < values.length; i++)
            b.append("val[").append(i).append("]=").append(values[i]);
     
         b.append("<br>");
         if(request.getAttribute("usermessage") != null)
            b.append("UserMessage: ").append(request.getAttribute("usermessage"));
      }
      return b.toString();
   }        
}
