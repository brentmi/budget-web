package com.brentmi.budget.ws;

import com.brentmi.budget.Datasource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
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
import java.sql.Statement;
import org.json.JSONArray;
import org.json.JSONObject;

@Path("/")
public class BudgetEntries extends AllowDeny
{
   public BudgetEntries()
   {
      super("ENABLED");
   }

   // GET /ws/entries?month_id=1
   // Returns all entries for a month, ordered by entry_type then sort_order
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("entries")
   public String getEntries(@Context HttpServletRequest request, @QueryParam("month_id") int monthId)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getEntries"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "SELECT id, month_id, entry_type, category, description, amount, is_actual, sort_order " +
                      "FROM budget_entry WHERE month_id = ? ORDER BY entry_type DESC, sort_order ASC, id ASC";
         PreparedStatement st = c.prepareStatement(sql);
         st.setInt(1, monthId);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",          rs.getInt(1));
            row.put("month_id",    rs.getInt(2));
            row.put("entry_type",  rs.getString(3));
            row.put("category",    rs.getString(4));
            row.put("description", rs.getString(5));
            row.put("amount",      rs.getDouble(6));
            row.put("is_actual",   rs.getInt(7));
            row.put("sort_order",  rs.getInt(8));
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load entries: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // POST /ws/entries
   // Body: { "month_id":1, "entry_type":"DEBIT", "category":"cc_payment",
   //         "description":"...", "amount":500.00, "is_actual":1, "sort_order":0 }
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("entries")
   public String addEntry(@Context HttpServletRequest request, String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "addEntry"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "INSERT INTO budget_entry (month_id, entry_type, category, description, amount, is_actual, sort_order) " +
                      "VALUES (?, ?, ?, ?, ?, ?, ?)";
         PreparedStatement st = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
         st.setInt(1,    o.getInt("month_id"));
         st.setString(2, o.getString("entry_type"));
         st.setString(3, o.getString("category"));
         st.setString(4, o.optString("description", ""));
         st.setDouble(5, o.getDouble("amount"));
         st.setInt(6,    o.optInt("is_actual", 0));
         st.setInt(7,    o.optInt("sort_order", 0));
         st.executeUpdate();

         ResultSet keys = st.getGeneratedKeys();
         JSONObject result = new JSONObject();
         result.put("status", "ok");
         if (keys.next())
            result.put("id", keys.getInt(1));
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to add entry: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // PUT /ws/entries/{id}
   // Body: { "entry_type":"DEBIT", "category":"misc", "description":"...",
   //         "amount":200.00, "is_actual":0, "sort_order":1 }
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("entries/{id}")
   public String updateEntry(@Context HttpServletRequest request,
                             @PathParam("id") int id,
                             String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "updateEntry"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "UPDATE budget_entry SET entry_type = ?, category = ?, description = ?, " +
                      "amount = ?, is_actual = ?, sort_order = ? WHERE id = ?";
         PreparedStatement st = c.prepareStatement(sql);
         st.setString(1, o.getString("entry_type"));
         st.setString(2, o.getString("category"));
         st.setString(3, o.optString("description", ""));
         st.setDouble(4, o.getDouble("amount"));
         st.setInt(5,    o.optInt("is_actual", 0));
         st.setInt(6,    o.optInt("sort_order", 0));
         st.setInt(7, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to update entry: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // DELETE /ws/entries/{id}
   @DELETE
   @Produces(MediaType.APPLICATION_JSON)
   @Path("entries/{id}")
   public String deleteEntry(@Context HttpServletRequest request, @PathParam("id") int id)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "deleteEntry"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement("DELETE FROM budget_entry WHERE id = ?");
         st.setInt(1, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to delete entry: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
