/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import com.brentmi.budget.UserToken;
import com.brentmi.budget.Datasource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;

/**
 *
 * @author millingtonb
 */
public class AuditLogger
{
   public static void log(String msg, HttpServletRequest request) throws ServletException
   {
      UserToken t = ((UserToken)request.getSession().getAttribute("userToken"));
      log("INFO", t.getUserId(), msg, request);
   }
   
   public static void log(String level, String msg, HttpServletRequest request) throws ServletException
   {
      UserToken t = ((UserToken)request.getSession().getAttribute("userToken"));
      log(level, t.getUserId(), msg, request);
   }
   
   public static void log(String type, int userId, String msg, HttpServletRequest request) throws ServletException
   {
      try
      {   
         Connection c = Datasource.getConnection(request);
         log(type, userId, msg, c, "UI");
      }
      catch(Exception e)
      {
         throw new ServletException(e.getMessage());
      }
   }
   
   public static void log(String type, int userId, String msg, Connection c, String source) throws ServletException
   {
      try
      {   
         //Connection c = Datasource.getConnection(request);
         try
         {
            PreparedStatement st = c.prepareStatement("insert into audit_log values (null, now(), ?, ?, ?, ?)");
            st.setString(1, source);
            st.setString(2, type);
            st.setInt(3, userId);
            st.setString(4, msg);
            st.executeUpdate();
         }
         catch(Exception e)
         {
            throw e;
         }
         finally
         {
            if(c != null)
               c.close();
         }
      }
      catch(Exception e)
      {
         throw new ServletException(e.getMessage());
      }
   }
}
