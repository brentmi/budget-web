/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.brentmi.budget.ws;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import org.json.JSONArray;
import org.json.JSONObject;
import com.brentmi.budget.Datasource;

/**
 *
 * @author brent.millington
 */

@Path("/")
public class AuditRecords
{
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("getlogrecords")
   public String getAuditLogRecords(@Context HttpServletRequest request, String json) throws Exception
   {
      JSONObject o = new JSONObject(json);
      String source = o.getString("source");
      String dateFrom = o.getString("date_from");
      String dateTo = o.getString("date_to") + " 23:59:59";
      int limit = o.getInt("row_limit");
      ArrayList<String> a = new ArrayList();
      Connection c = Datasource.getConnection(request);
      
      JSONArray res = new JSONArray();
      try
      {  
         PreparedStatement st = null;
         String sql = "select l.when_date, type, o.username, l.msg  " +
         "from audit_log l join operator o on o.id = l.operator_id " +
         "where l.when_date between ? and ? " +
         (source == null ? "and l.source like ? " : "and l.source = ? ") +
         "order by l.id desc " +
         "limit ?";

         st = c.prepareStatement(sql);
         st.setString(1, dateFrom);
         st.setString(2, dateTo);
         st.setString(3, source == null ? "%" : source);
         st.setInt(5, limit);
         ResultSet rs = st.executeQuery();
         while(rs.next())
         {
            JSONObject o1 = new JSONObject();
            o1.put("date", rs.getString(1));
            o1.put("type", rs.getString(2));
            o1.put("user", rs.getString(3));
            o1.put("message", rs.getString(4));
            res.put(o1);
         }
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
      
      return res.toString();
   }
}
