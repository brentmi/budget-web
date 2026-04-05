/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import com.brentmi.budget.AuditLogger;
import com.brentmi.budget.UserToken;
import com.brentmi.budget.AccessLevels;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Enumeration;
import java.util.Iterator;
import java.util.Map;
import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 *
 * @author milingtonb
 */
public abstract class Control extends HttpServlet
{

   /**
    * Processes requests for both HTTP
    * <code>GET</code> and
    * <code>POST</code> methods.
    *
    * @param request servlet request
    * @param response servlet response
    * @throws ServletException if a servlet-specific error occurs
    * @throws IOException if an I/O error occurs
    * Added some new functions.
    */
   
   protected void processRequest(HttpServletRequest request, HttpServletResponse response)
           throws ServletException, IOException
   {
      boolean debug = Boolean.valueOf(request.getServletContext().getInitParameter("debug"));
      UserToken t = ((UserToken)request.getSession().getAttribute("userToken"));
      System.out.println("Control -> processRequest -> UserToken: null");
      
      
      response.setContentType("text/html;charset=UTF-8");
      PrintWriter out = response.getWriter();
      //out.write(localToString(request));
      try
      {
         RequestDispatcher rd = null;
         String nextPage = "view/login.jsp";
         request.setAttribute("usermessage", null);
         
         System.out.println("1 Control -> processRequest -> nextPage: " + nextPage);
         
         // added ldap support
         if(request.getParameter("localheaders") != null)
         {
            request.setAttribute("usermessage", toString(request));
            nextPage = "view/message.jsp";
         } 
         else if(request.getSession().getAttribute("userToken") == null)
         {
            if(debug)
            {  
               // test
               System.out.println("2 Control -> processRequest -> getSession.getAttribute.userToken == null");
               System.out.println("3 Control -> processRequest -> request.getParameter(user) = " + request.getParameter("user"));
               System.out.println("4 Control -> processRequest -> Request.toString() " + toString(request));
            }
            
            if(request.getParameter("user") != null && request.getParameter("user").equals("mcr"))
            {   
               System.out.println("Control -> processRequest -> MCR user is logging in.");
               
               if(request.getParameter("rq") != null)
               {
                 nextPage = request.getParameter("rq");
                 switch(nextPage)
                 {
                    case "input-clearscrambled":
                    case "input-siteswitch":
                       break;
                    default:
                       nextPage = "view/login.jsp";
                 }
                 
                 
                  UserToken token = new UserToken();
                  token.setAc(getDefaultAccessLevels());

                  request.setAttribute("mcr_user", "mcr@foxtel.com.au");
                  if(token.login(request, getWebappDbPlatform(request)))
                  {
                     request.getSession().setAttribute("defaultAccessLevels", getDefaultAccessLevels()); // Clunky but can't be assed doing it better.

                     System.out.println("MCR user setAttribute(userToken, token");
                     request.getSession().setAttribute("userToken", token);

                     AuditLogger.log("Login from user.", request);

                     System.out.println("MCR user Logged in OK, next page = " + nextPage);
                     nextPage = getNextPage(request, out);
                  }
               }
               // defaults back to view/login.jsp if none of the above match
            
            }
            else if(request.getParameter("loginsubmit") != null)
            {
               if(debug)
                  System.out.println("Control -> processRequest -> loginsubmit != null request new UserToken");
               
               UserToken token = new UserToken();
               
               if(debug)
                  System.out.println("Control -> processRequest -> token.setAc(getDefaultAccessLevels())");
               
               token.setAc(getDefaultAccessLevels());
               
               if(debug)
                  System.out.println("Control -> processRequest -> token.setAc.toString: " + token.getSessionId() + ", " + token.getUsername());
               
               if(debug)
                  System.out.println("Control -> processRequest -> token.login(request, getWebappDbPlatform(request)");
               
               if(token.login(request, getWebappDbPlatform(request)))
               {
                  if(debug)
                     System.out.println("Control -> processRequest -> setAttribute(defaultAccessLevels, getDefaultAccessLevels()");
                  
                  request.getSession().setAttribute("defaultAccessLevels", getDefaultAccessLevels()); // Clunky but can't be assed doing it better.
                  
                  if(debug)
                     System.out.println("Control -> processRequest -> setAttribute(userToken, token");
                  
                  request.getSession().setAttribute("userToken", token);
                  
                  AuditLogger.log("Control -> processRequest -> Login from user: " + token.getUsername(), request);
                  
                  if(debug)
                     System.out.println("Control -> processRequest -> Logged in OK, next page = " + nextPage);
                  
                  nextPage = getNextPage(request, out);
               }
               
               if(debug)
                  System.out.println("Control -> processRequest -> End IF loginsubmit != null: nextPage = " + nextPage);
            }
            System.out.println("Control -> processRequest -> End IF userToken == null");
         }
         else
         {
            try
            {   
               if(debug)
                  System.out.println("Control -> processRequest -> userToken is NOT NULL.");
               
               UserToken token = (UserToken)request.getSession().getAttribute("userToken");
               
               if(debug)
                  System.out.println("Control -> processRequest -> Validate token: " + token.getSessionId() + ", " + token.getUsername());
               
               if(token.validate(request))
               { 
                  if(debug)
                     System.out.println("Control -> processRequest -> Token is valid, get next page...");
                  
                  nextPage = getNextPage(request, out);
                  
                  if(debug)
                     System.out.println("Control -> processRequest -> Next page = " + nextPage);
               }
               else
                  throw new Exception(request.getAttribute("usermessage") == null ? "Token validation failed for unknown reason." : ""+request.getAttribute("usermessage"));
            }
            catch(Exception e)
            {
               System.out.println("Control -> processRequest -> userToken is NOT NULL catch Exception.");
               System.out.println("Control -> processRequest -> Exception -> " + e.getMessage());
               request.setAttribute("usermessage", e.getMessage());
               
               nextPage = "view/message.jsp";
               System.out.println("Control -> processRequest -> Exception -> nextPage: " + nextPage);
            }
         }
         
         if(debug)
            System.out.println("Control -> processRequest -> end-of-method, RequestDispatcher.nextPage = " + nextPage);
         
         if (!nextPage.startsWith("/"))
            nextPage = "/" + nextPage;

         rd = request.getRequestDispatcher(nextPage);
         rd.include(request, response);
      }
      catch(Exception e)
      {
         throw new RuntimeException(e.getMessage());
      }
      finally
      {         
         out.close();
      }
   }
   
   public String getWebappDbPlatform(HttpServletRequest request)
   {
      return request.getServletContext().getInitParameter("webappDbPlatform");
   }
   
   public abstract String getNextPage(HttpServletRequest request, PrintWriter out) throws Exception;
   
   public abstract AccessLevels getDefaultAccessLevels();
   
      public String toString(HttpServletRequest request)
   {
      StringBuilder b = new StringBuilder();
      Map<String, String[]> map = request.getParameterMap();
      
      b.append("ParamMap has the following attributes:<br>");
      Iterator<String> it = map.keySet().iterator();
      while(it.hasNext())
      {
         String name = it.next();
         String[] values = map.get(name);
         b.append("KeyName=").append(name).append(" [String]: ");
         for(int i = 0; i < values.length; i++)
            b.append("val[").append(i).append("]=").append(values[i]);
     
         b.append("<br>");
      }
      
      b.append("Header...<br>");
      Enumeration e = request.getHeaderNames();
      while (e.hasMoreElements())
      {
         String name = (String)e.nextElement();
         b.append(name).append(" --> ").append(request.getHeader(name)).append("<br>");
      }
      return b.toString();
   } 
   
   // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
   /**
    * Handles the HTTP
    * <code>GET</code> method.
    *
    * @param request servlet request
    * @param response servlet response
    * @throws ServletException if a servlet-specific error occurs
    * @throws IOException if an I/O error occurs
    */
   @Override
   protected void doGet(HttpServletRequest request, HttpServletResponse response)
           throws ServletException, IOException
   {
      processRequest(request, response);
   }

   /**
    * Handles the HTTP
    * <code>POST</code> method.
    *
    * @param request servlet request
    * @param response servlet response
    * @throws ServletException if a servlet-specific error occurs
    * @throws IOException if an I/O error occurs
    */
   @Override
   protected void doPost(HttpServletRequest request, HttpServletResponse response)
           throws ServletException, IOException
   {
      processRequest(request, response);
   }

   /**
    * Returns a short description of the servlet.
    *
    * @return a String containing servlet description
    */
   @Override
   public String getServletInfo()
   {
      return "Short description";
   }// </editor-fold>
}
