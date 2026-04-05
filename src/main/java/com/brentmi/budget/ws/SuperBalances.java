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
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import org.json.JSONArray;
import org.json.JSONObject;

@Path("/")
public class SuperBalances extends AllowDeny
{
   public SuperBalances()
   {
      super("ENABLED");
   }

   // GET /ws/super
   // Returns all super balance records ordered by date ascending
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("super")
   public String getBalances(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getSuperBalances"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "SELECT id, balance_date, balance_amount, notes " +
                      "FROM super_balance ORDER BY balance_date ASC";
         PreparedStatement st = c.prepareStatement(sql);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",             rs.getInt(1));
            row.put("balance_date",   rs.getString(2));
            row.put("balance_amount", rs.getDouble(3));
            row.put("notes",          rs.getString(4) == null ? "" : rs.getString(4));
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load super balances: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // POST /ws/super
   // Body: { "balance_date":"2026-04-30", "balance_amount":610000.00, "notes":"" }
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("super")
   public String addBalance(@Context HttpServletRequest request, String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "addSuperBalance"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "INSERT INTO super_balance (balance_date, balance_amount, notes) VALUES (?, ?, ?)";
         PreparedStatement st = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
         st.setString(1, o.getString("balance_date"));
         st.setDouble(2, o.getDouble("balance_amount"));
         st.setString(3, o.optString("notes", ""));
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
         setError("Failed to add super balance: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // PUT /ws/super/{id}
   // Body: { "balance_date":"2026-04-30", "balance_amount":615000.00, "notes":"updated" }
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("super/{id}")
   public String updateBalance(@Context HttpServletRequest request,
                               @PathParam("id") int id,
                               String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "updateSuperBalance"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "UPDATE super_balance SET balance_date = ?, balance_amount = ?, notes = ? WHERE id = ?";
         PreparedStatement st = c.prepareStatement(sql);
         st.setString(1, o.getString("balance_date"));
         st.setDouble(2, o.getDouble("balance_amount"));
         st.setString(3, o.optString("notes", ""));
         st.setInt(4, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to update super balance: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // DELETE /ws/super/{id}
   @DELETE
   @Produces(MediaType.APPLICATION_JSON)
   @Path("super/{id}")
   public String deleteBalance(@Context HttpServletRequest request, @PathParam("id") int id)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "deleteSuperBalance"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement("DELETE FROM super_balance WHERE id = ?");
         st.setInt(1, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to delete super balance: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
