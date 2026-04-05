/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget.ws;

import com.brentmi.budget.AuditLogger;
import com.brentmi.budget.UserToken;
import jakarta.servlet.http.HttpServletRequest;
import org.json.JSONObject;

/**
 *
 * @author millingtonb
 */
public abstract class AllowDeny
{
   private String type;
   private String error;
   
   public AllowDeny(String type)
   {
      this.type = type;
   }
   
   public void log(String msg, HttpServletRequest request)
   {
      try
      {   
         String[] lines = msg.split("\n");
         for(int i = 0; i < lines.length; i++)
            if(! lines[i].isEmpty())
               AuditLogger.log(lines[i], request);
      }
      catch(Exception e)
      {
         setError("Failed to initiate logging - try logging in again.");
         System.out.println("Failed to initiate logging: line 44 AllowDeny.java");
      }
   }
   
   public boolean assertAllow(HttpServletRequest request, JSONObject o, String f)
   {
      return assertAllow(request, o, f, null);
   }
   
   public boolean assertAllow(HttpServletRequest request, JSONObject o, String f, String permissionType)
   {
      if(permissionType == null)
         permissionType = type;
      
      log("Checking user permissions for function: "+f, request);
      if(error != null)
         return false;
      
      UserToken ut = null; 
      if(request.getSession().getAttribute("userToken") != null)
         ut = (UserToken)request.getSession().getAttribute("userToken");
      
      if(ut == null)
      {
         setError("UserToken is null - try logging in again.");
         return false;
      }
      
//      if(! ut.hasAccess(permissionType))
//         return false;
      
      log("Permissions ok for function", request);
      return true;
   }
   
   public void setError(String error)
   {
      this.error = error;
   }
   
   public String getError()
   {
      JSONObject res = new JSONObject();
      res.put("status", "failed"); // default
      if(error == null)
         res.put("msg", "PERMISSION DENIED - check access rights."); // default
      else
         res.put("msg", error);
  
      return res.toString();
   }
}
