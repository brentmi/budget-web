package com.brentmi.budget.ws;

import com.brentmi.budget.Datasource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import org.json.JSONArray;
import org.json.JSONObject;

@Path("/")
public class BudgetMonths extends AllowDeny
{
   public BudgetMonths()
   {
      super("ENABLED");
   }

   // GET /ws/months?year_id=1
   // Returns all 12 months for a financial year
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("months")
   public String getMonths(@Context HttpServletRequest request, @QueryParam("year_id") int yearId)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getMonths"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "SELECT id, year_id, month_number, is_reconciled, notes " +
                      "FROM budget_month WHERE year_id = ? ORDER BY month_number ASC";
         PreparedStatement st = c.prepareStatement(sql);
         st.setInt(1, yearId);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",            rs.getInt(1));
            row.put("year_id",       rs.getInt(2));
            row.put("month_number",  rs.getInt(3));
            row.put("is_reconciled", rs.getInt(4));
            row.put("notes",         rs.getString(5) == null ? "" : rs.getString(5));
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load months: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // PUT /ws/months/{id}
   // Body: { "is_reconciled": 1, "notes": "..." }
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("months/{id}")
   public String updateMonth(@Context HttpServletRequest request,
                             @PathParam("id") int id,
                             String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "updateMonth"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "UPDATE budget_month SET is_reconciled = ?, notes = ? WHERE id = ?";
         PreparedStatement st = c.prepareStatement(sql);
         st.setInt(1,    o.optInt("is_reconciled", 0));
         st.setString(2, o.optString("notes", ""));
         st.setInt(3, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to update month: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
