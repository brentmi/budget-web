package com.brentmi.budget.ws;

import com.brentmi.budget.Datasource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
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
public class EntryCategories extends AllowDeny
{
   public EntryCategories()
   {
      super("ENABLED");
   }

   // GET /ws/entry-categories
   // Returns active categories only: { "DEBIT": ["cc_payment", ...], "CREDIT": ["wages", ...] }
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("entry-categories")
   public String getCategories(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getCategories"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT entry_type, name FROM entry_category WHERE is_active = 1 ORDER BY entry_type, sort_order ASC");
         ResultSet rs = st.executeQuery();

         JSONArray debits  = new JSONArray();
         JSONArray credits = new JSONArray();

         while (rs.next())
         {
            String type = rs.getString(1);
            String name = rs.getString(2);
            if ("DEBIT".equals(type))
               debits.put(name);
            else if ("CREDIT".equals(type))
               credits.put(name);
         }

         JSONObject result = new JSONObject();
         result.put("DEBIT",  debits);
         result.put("CREDIT", credits);
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load entry categories: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // GET /ws/entry-categories/all
   // Returns all categories (active and hidden) with full fields, for the settings page.
   // Returns array of { id, entry_type, name, sort_order, is_active }
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("entry-categories/all")
   public String getAllCategories(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getAllCategories"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT id, entry_type, name, sort_order, is_active FROM entry_category ORDER BY entry_type, sort_order ASC");
         ResultSet rs = st.executeQuery();

         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",         rs.getInt(1));
            row.put("entry_type", rs.getString(2));
            row.put("name",       rs.getString(3));
            row.put("sort_order", rs.getInt(4));
            row.put("is_active",  rs.getInt(5));
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load all entry categories: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // POST /ws/entry-categories
   // Body: { "entry_type": "DEBIT", "name": "new_cat" }
   // Adds a new active category. sort_order is set to max+1 for that entry_type.
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("entry-categories")
   public String addCategory(@Context HttpServletRequest request, String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "addCategory"))
         return getError();

      String entryType = o.getString("entry_type");
      String name      = o.getString("name").trim();

      if (name.isEmpty())
      {
         setError("Category name cannot be empty.");
         return getError();
      }

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);

         PreparedStatement maxSt = c.prepareStatement(
            "SELECT COALESCE(MAX(sort_order), 0) FROM entry_category WHERE entry_type = ?");
         maxSt.setString(1, entryType);
         ResultSet maxRs   = maxSt.executeQuery();
         int nextSortOrder = maxRs.next() ? maxRs.getInt(1) + 1 : 1;

         PreparedStatement st = c.prepareStatement(
            "INSERT INTO entry_category (entry_type, name, sort_order, is_active) VALUES (?, ?, ?, 1)",
            Statement.RETURN_GENERATED_KEYS);
         st.setString(1, entryType);
         st.setString(2, name);
         st.setInt(3,    nextSortOrder);
         st.executeUpdate();

         ResultSet keys  = st.getGeneratedKeys();
         JSONObject result = new JSONObject();
         result.put("status", "ok");
         if (keys.next())
            result.put("id", keys.getInt(1));
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to add category: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // PUT /ws/entry-categories/{id}/rename
   // Body: { "name": "new_name" }
   // Renames the category and updates all matching budget_entry rows.
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("entry-categories/{id}/rename")
   public String renameCategory(@Context HttpServletRequest request,
                                @PathParam("id") int id,
                                String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "renameCategory"))
         return getError();

      String newName = o.getString("name").trim();
      if (newName.isEmpty())
      {
         setError("Category name cannot be empty.");
         return getError();
      }

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);

         PreparedStatement getCat = c.prepareStatement(
            "SELECT name, entry_type FROM entry_category WHERE id = ?");
         getCat.setInt(1, id);
         ResultSet rs = getCat.executeQuery();
         if (!rs.next())
         {
            setError("Category not found.");
            return getError();
         }
         String oldName   = rs.getString(1);
         String entryType = rs.getString(2);

         PreparedStatement updCat = c.prepareStatement(
            "UPDATE entry_category SET name = ? WHERE id = ?");
         updCat.setString(1, newName);
         updCat.setInt(2, id);
         updCat.executeUpdate();

         PreparedStatement updEntries = c.prepareStatement(
            "UPDATE budget_entry SET category = ? WHERE category = ? AND entry_type = ?");
         updEntries.setString(1, newName);
         updEntries.setString(2, oldName);
         updEntries.setString(3, entryType);
         int updated = updEntries.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status",          "ok");
         result.put("entries_updated", updated);
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to rename category: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // PUT /ws/entry-categories/{id}/visibility
   // Body: { "is_active": 0 } or { "is_active": 1 }
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("entry-categories/{id}/visibility")
   public String setCategoryVisibility(@Context HttpServletRequest request,
                                       @PathParam("id") int id,
                                       String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "setCategoryVisibility"))
         return getError();

      int isActive = o.getInt("is_active");
      if (isActive != 0 && isActive != 1)
      {
         setError("is_active must be 0 or 1.");
         return getError();
      }

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "UPDATE entry_category SET is_active = ? WHERE id = ?");
         st.setInt(1, isActive);
         st.setInt(2, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to update category visibility: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
