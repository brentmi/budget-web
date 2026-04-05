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
public class FixedInput extends AllowDeny
{
   public FixedInput()
   {
      super("ENABLED");
   }

   // GET /ws/fixed-input
   // Returns all active fixed input items ordered by section then sort_order
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("fixed-input")
   public String getItems(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getFixedInput"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "SELECT id, item_name, item_cost, frequency, section, is_active, sort_order " +
                      "FROM fixed_input_item ORDER BY section ASC, sort_order ASC, id ASC";
         PreparedStatement st = c.prepareStatement(sql);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",         rs.getInt(1));
            row.put("item_name",  rs.getString(2));
            row.put("item_cost",  rs.getDouble(3));
            row.put("frequency",  rs.getString(4));
            row.put("section",    rs.getString(5));
            row.put("is_active",  rs.getInt(6));
            row.put("sort_order", rs.getInt(7));
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load fixed input items: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // POST /ws/fixed-input
   // Body: { "item_name":"Strata", "item_cost":1950.00, "frequency":"Quarterly",
   //         "section":"known_fixed", "sort_order":1 }
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("fixed-input")
   public String addItem(@Context HttpServletRequest request, String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "addFixedInput"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "INSERT INTO fixed_input_item (item_name, item_cost, frequency, section, sort_order) " +
                      "VALUES (?, ?, ?, ?, ?)";
         PreparedStatement st = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
         st.setString(1, o.getString("item_name"));
         st.setDouble(2, o.getDouble("item_cost"));
         st.setString(3, o.getString("frequency"));
         st.setString(4, o.getString("section"));
         st.setInt(5,    o.optInt("sort_order", 0));
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
         setError("Failed to add fixed input item: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // PUT /ws/fixed-input/{id}
   // Body: { "item_name":"Strata", "item_cost":2100.00, "frequency":"Quarterly",
   //         "section":"known_fixed", "is_active":1, "sort_order":1 }
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("fixed-input/{id}")
   public String updateItem(@Context HttpServletRequest request,
                            @PathParam("id") int id,
                            String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "updateFixedInput"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "UPDATE fixed_input_item SET item_name = ?, item_cost = ?, frequency = ?, " +
                      "section = ?, is_active = ?, sort_order = ? WHERE id = ?";
         PreparedStatement st = c.prepareStatement(sql);
         st.setString(1, o.getString("item_name"));
         st.setDouble(2, o.getDouble("item_cost"));
         st.setString(3, o.getString("frequency"));
         st.setString(4, o.getString("section"));
         st.setInt(5,    o.optInt("is_active", 1));
         st.setInt(6,    o.optInt("sort_order", 0));
         st.setInt(7, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to update fixed input item: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // DELETE /ws/fixed-input/{id}
   @DELETE
   @Produces(MediaType.APPLICATION_JSON)
   @Path("fixed-input/{id}")
   public String deleteItem(@Context HttpServletRequest request, @PathParam("id") int id)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "deleteFixedInput"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement("DELETE FROM fixed_input_item WHERE id = ?");
         st.setInt(1, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to delete fixed input item: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
