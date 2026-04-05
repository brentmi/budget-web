/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import com.brentmi.budget.Datasource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import jakarta.servlet.http.HttpServletRequest;
import com.brentmi.budget.RuntimeEnv;

/**
 *
 * @author milingtonb
 */
public class UserLogin
{
   private int permissionSet;
   private int userId;
   private String username;
 
   public String getUsername() {
      return username;
   }

   public void setUsername(String username) {
      this.username = username;
   }

   public int getUserId()
   {
      return userId;
   }

   public void setUserId(int userId)
   {
      this.userId = userId;
   }
   
   public int getPermissionSet()
   {
      return permissionSet;
   }

   public boolean authenticate(HttpServletRequest request, String platform) throws Exception
   {
      boolean debug = Boolean.valueOf(request.getServletContext().getInitParameter("debug"));
      String release = RuntimeEnv.getPlatform();
      Connection c = Datasource.getConnection(platform);
      try
      {
         String user = "";
         
         if(request.getAttribute("mcr_user") != null)
            user = ""+request.getAttribute("mcr_user");
         else if(release.contains("_dev"))// || release.equals("pts"))// && (ldapHeader == null && ldapUser == null))
            user = JwtDecoder.getUser(DevJwt.getJwt());
         else 
         {
            if(request.getHeader("x-amzn-oidc-accesstoken") == null)
               throw new Exception("No supported oktaAuthentication found");
               
            user = JwtDecoder.getUser(request.getHeader("x-amzn-oidc-accesstoken"));
         }
         
         PreparedStatement st = c.prepareStatement("SELECT o.id, o.permission_set, o.username FROM operator o WHERE upper(o.username) = ?");
         st.setString(1, user.toUpperCase());

         ResultSet rs = st.executeQuery();
         if(rs.next())
         {
            userId = rs.getInt(1);
            permissionSet = rs.getInt(2);
            username = rs.getString(3);
     
            return true;
         }
         else
         {
            throw new Exception("Login failed. Username or password is incorrect or user doesn't exist.");
         }
      }  
      catch(Exception e)
      {
         throw new Exception("Datasource/Connection: " + e);
      }
      finally
      {
         if(c != null)
            c.close();
      }
   }
   
   
}
