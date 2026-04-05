/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import java.util.ArrayList;

/**
 *
 * @author milingtonb
 */
public class UserToken
{
   String sessionId;
   boolean loggedIn;
   private AccessLevels ac;
   private int userId;
   private String username;

   public String getUsername() 
   {
      return username;
   }

   public void setUsername(String username) 
   {
      this.username = username;
   }

   public AccessLevels getAc()
   {
      return ac;
   }

   public void setAc(AccessLevels ac)
   {
      this.ac = ac;
   }

   public int getUserId()
   {
      return userId;
   }

   public void setUserId(int userId)
   {
      this.userId = userId;
   }
   
   
   public boolean hasAccess(String type)
   {
      return ac.isSet(type);
   }        
   
   public boolean isLoggedIn()
   {
      return loggedIn;
   }

   public void setLoggedIn(boolean loggedIn)
   {
      this.loggedIn = loggedIn;
   }

   public String getSessionId()
   {
      return sessionId;
   }

   public void setSessionId(String sessionId)
   {
      this.sessionId = sessionId;
   }

   public boolean validate(HttpServletRequest request)
           throws ServletException, IOException
   {
      try
      {
         String id = ((HttpServletRequest)request).getSession().getId();

         if(! this.sessionId.equals(id))
         {   
            request.setAttribute("usermessage", "Your session has expired.");
            return false;
         }
         
         if(! this.isLoggedIn())
         {   
            request.setAttribute("usermessage", "You don't appear to be logged in.");
            return false;
         }
      }
      finally
      {         

      }
      return true;
   }
   
   public boolean login(HttpServletRequest request, String platform)
           throws ServletException, IOException
   {
      try
      {   
         UserLogin ul = new UserLogin();
         if(ul.authenticate(request, platform))
         {
            ac.setPermission(ul.getPermissionSet());
            if(! ac.isSet("ENABLED"))
               throw new Exception("Unable to dispaly content as this account is set to DISABLED.");
            
            // controlled from web.xml
            //request.getSession().setMaxInactiveInterval(3600);
            sessionId = request.getSession().getId();
            userId = ul.getUserId();
            username = ul.getUsername();
            loggedIn = true;
            
            return true;
         }
      }
      catch(Exception e)
      {
         request.setAttribute("usermessage", e.getMessage());
      }
      return false;
   }
}
