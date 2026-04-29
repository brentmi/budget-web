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
public class WorksheetItems extends AllowDeny
{
   public WorksheetItems()
   {
      super("ENABLED");
   }

   // GET /ws/worksheet
   // Returns all worksheet items ordered by section then sort_order
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("worksheet")
   public String getItems(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getWorksheetItems"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "SELECT id, section, item_name, amount, notes, sort_order, is_active " +
                      "FROM worksheet_item ORDER BY section ASC, sort_order ASC, id ASC";
         PreparedStatement st = c.prepareStatement(sql);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",         rs.getInt(1));
            row.put("section",    rs.getString(2));
            row.put("item_name",  rs.getString(3));
            row.put("amount",     rs.getDouble(4));
            row.put("notes",      rs.getString(5) == null ? "" : rs.getString(5));
            row.put("sort_order", rs.getInt(6));
            row.put("is_active",  rs.getInt(7));
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load worksheet items: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // POST /ws/worksheet
   // Body: { "section":"subscription", "item_name":"Netflix", "amount":21.00,
   //         "notes":"", "sort_order":1 }
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("worksheet")
   public String addItem(@Context HttpServletRequest request, String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "addWorksheetItem"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "INSERT INTO worksheet_item (section, item_name, default_item_name, amount, default_amount, notes, is_active, default_is_active, sort_order) " +
                      "VALUES (?, ?, ?, ?, ?, ?, ?, ?, (SELECT COALESCE(MAX(wi.sort_order), 0) + 1 FROM worksheet_item wi))";
         PreparedStatement st = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
         st.setString(1, o.getString("section"));
         st.setString(2, o.getString("item_name"));
         st.setString(3, o.getString("item_name"));
         st.setDouble(4, o.getDouble("amount"));
         st.setDouble(5, o.getDouble("amount"));
         st.setString(6, o.optString("notes", ""));
         st.setInt(7,    o.optInt("is_active", 1));
         st.setInt(8,    o.optInt("is_active", 1));
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
         setError("Failed to add worksheet item: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // PUT /ws/worksheet/{id}
   // Body: { "section":"subscription", "item_name":"Netflix", "amount":22.00,
   //         "notes":"", "sort_order":1, "is_active":1 }
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("worksheet/{id}")
   public String updateItem(@Context HttpServletRequest request,
                            @PathParam("id") int id,
                            String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "updateWorksheetItem"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         boolean setDefault = o.optBoolean("set_as_default", false);
         String sql = setDefault
            ? "UPDATE worksheet_item SET section = ?, item_name = ?, amount = ?, notes = ?, is_active = ?, " +
              "default_item_name = ?, default_amount = ?, default_is_active = ? WHERE id = ?"
            : "UPDATE worksheet_item SET section = ?, item_name = ?, amount = ?, notes = ?, is_active = ? WHERE id = ?";
         PreparedStatement st = c.prepareStatement(sql);
         st.setString(1, o.getString("section"));
         st.setString(2, o.getString("item_name"));
         st.setDouble(3, o.getDouble("amount"));
         st.setString(4, o.optString("notes", ""));
         st.setInt(5,    o.optInt("is_active", 1));
         if (setDefault)
         {
            st.setString(6, o.getString("item_name"));
            st.setDouble(7, o.getDouble("amount"));
            st.setInt(8,    o.optInt("is_active", 1));
            st.setInt(9, id);
         }
         else
         {
            st.setInt(6, id);
         }
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to update worksheet item: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // POST /ws/worksheet/reset-cc-defaults
   // Resets all cc_estimate items to their default name, amount, and active state
   @POST
   @Produces(MediaType.APPLICATION_JSON)
   @Path("worksheet/reset-cc-defaults")
   public String resetCcDefaults(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "resetCcDefaults"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "UPDATE worksheet_item " +
                      "SET item_name = default_item_name, amount = default_amount, is_active = default_is_active " +
                      "WHERE section IN ('cc_estimate', 'cc_balance')";
         PreparedStatement st = c.prepareStatement(sql);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to reset CC estimates: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // DELETE /ws/worksheet/{id}
   @DELETE
   @Produces(MediaType.APPLICATION_JSON)
   @Path("worksheet/{id}")
   public String deleteItem(@Context HttpServletRequest request, @PathParam("id") int id)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "deleteWorksheetItem"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement("DELETE FROM worksheet_item WHERE id = ?");
         st.setInt(1, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to delete worksheet item: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
