/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.brentmi.budget;

/**
 *
 * @author brentmi
 */
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;
import java.sql.Connection;
import java.util.HashMap;
import jakarta.servlet.http.HttpServletRequest;

/**
 *
 * @author brentmi
 */
public class Datasource 
{
   private static final HashMap<String, DataSource> dsInstance = new HashMap<String, DataSource>();
   
   public static Connection getConnection(HttpServletRequest request) throws Exception
   {    
      return getConnection(request.getServletContext().getInitParameter("webappDbPlatform"));
   }
   
   public static Connection getConnection(String db) throws Exception
   {    
      synchronized(dsInstance)
      {  
//         if(dsInstance == null)
//            dsInstance = new HashMap();
         if(! dsInstance.containsKey(db))
         { 
            InitialContext ic = new InitialContext();
            Context xmlContext = (Context) ic.lookup("java:comp/env"); 
            DataSource ds = (DataSource) xmlContext.lookup("jdbc/"+db);
            dsInstance.put(db, ds);
         }

         return dsInstance.get(db).getConnection();
     }
   }
}