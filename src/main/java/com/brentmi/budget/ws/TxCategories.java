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

/**
 * CRUD endpoints for trx_category and trx_narrative (used by tx-categories.jsp).
 */
@Path("/tx-categories")
public class TxCategories extends AllowDeny
{
   public TxCategories()
   {
      super("ENABLED");
   }


   // GET /ws/tx-categories
   // Returns all rows from trx_category: [{ id, name, note }, ...]
   @GET
   @Produces(MediaType.APPLICATION_JSON)
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
            "SELECT id, name, note FROM trx_category ORDER BY name ASC");
         ResultSet rs = st.executeQuery();

         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",   rs.getInt(1));
            row.put("name", rs.getString(2));
            row.put("note", rs.getString(3) != null ? rs.getString(3) : "");
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load categories: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // POST /ws/tx-categories
   // Body: { "name": "...", "note": "..." }
   // Inserts a new trx_category row.
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   public String addCategory(@Context HttpServletRequest request, String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "addCategory"))
         return getError();

      String name = o.optString("name", "").trim();
      String note = o.optString("note", "").trim();

      if (name.isEmpty())
      {
         setError("Category name cannot be empty.");
         return getError();
      }

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "INSERT INTO trx_category (name, note) VALUES (?, ?)",
            Statement.RETURN_GENERATED_KEYS);
         st.setString(1, name);
         st.setString(2, note.isEmpty() ? null : note);
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
         setError("Failed to add category: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // PUT /ws/tx-categories/{id}
   // Body: { "name": "...", "note": "..." }
   // Updates name and note on a trx_category row.
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("{id}")
   public String updateCategory(@Context HttpServletRequest request,
                                @PathParam("id") int id,
                                String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "updateCategory"))
         return getError();

      String name = o.optString("name", "").trim();
      String note = o.optString("note", "").trim();

      if (name.isEmpty())
      {
         setError("Category name cannot be empty.");
         return getError();
      }

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "UPDATE trx_category SET name = ?, note = ? WHERE id = ?");
         st.setString(1, name);
         st.setString(2, note.isEmpty() ? null : note);
         st.setInt(3, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to update category: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // GET /ws/tx-categories/{categoryId}/narratives
   // Returns all trx_narrative rows for the given category id:
   // [{ id, trx_category_id, category_name, pattern, confidence, match_type }, ...]
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("{categoryId}/narratives")
   public String getNarratives(@Context HttpServletRequest request,
                               @PathParam("categoryId") int categoryId)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getNarratives"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT n.id, n.trx_category_id, tc.name, n.pattern, n.confidence, n.match_type " +
            "FROM trx_narrative n " +
            "JOIN trx_category tc ON tc.id = n.trx_category_id " +
            "WHERE n.trx_category_id = ? " +
            "ORDER BY n.id ASC");
         st.setInt(1, categoryId);
         ResultSet rs = st.executeQuery();

         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",              rs.getInt(1));
            row.put("trx_category_id", rs.getInt(2));
            row.put("category_name",   rs.getString(3));
            row.put("pattern",         rs.getString(4));
            row.put("confidence",      rs.getString(5));
            row.put("match_type",      rs.getString(6));
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load narratives: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // POST /ws/tx-categories/narrative
   // Body: { "trx_category_id": 1, "pattern": "...", "confidence": "high", "match_type": "contains" }
   // Inserts a new trx_narrative row. No retrospective update on add.
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("narrative")
   public String addNarrative(@Context HttpServletRequest request, String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "addNarrative"))
         return getError();

      int    categoryId  = o.getInt("trx_category_id");
      String pattern     = o.optString("pattern", "").trim();
      String confidence  = o.optString("confidence", "high");
      String matchType   = o.optString("match_type", "contains");

      if (pattern.isEmpty())
      {
         setError("Pattern cannot be empty.");
         return getError();
      }

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "INSERT INTO trx_narrative (trx_category_id, pattern, confidence, match_type) VALUES (?, ?, ?, ?)",
            Statement.RETURN_GENERATED_KEYS);
         st.setInt(1,    categoryId);
         st.setString(2, pattern);
         st.setString(3, confidence);
         st.setString(4, matchType);
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
         setError("Failed to add narrative: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // PUT /ws/tx-categories/narrative/{id}
   // Body: { "trx_category_id": 1, "pattern": "...", "confidence": "high", "match_type": "contains" }
   // Updates the narrative row. If trx_category_id changed, retroactively
   // reclassifies matching rows in trx_categorised using pattern + match_type.
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("narrative/{id}")
   public String updateNarrative(@Context HttpServletRequest request,
                                 @PathParam("id") int id,
                                 String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "updateNarrative"))
         return getError();

      int    newCategoryId = o.getInt("trx_category_id");
      String pattern       = o.optString("pattern", "").trim();
      String confidence    = o.optString("confidence", "high");
      String matchType     = o.optString("match_type", "contains");

      if (pattern.isEmpty())
      {
         setError("Pattern cannot be empty.");
         return getError();
      }

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);

         // Load current state of the narrative before updating
         PreparedStatement getCurrent = c.prepareStatement(
            "SELECT n.trx_category_id, tc.name FROM trx_narrative n " +
            "JOIN trx_category tc ON tc.id = n.trx_category_id " +
            "WHERE n.id = ?");
         getCurrent.setInt(1, id);
         ResultSet currentRs = getCurrent.executeQuery();
         if (!currentRs.next())
         {
            setError("Narrative rule not found.");
            return getError();
         }
         int    oldCategoryId   = currentRs.getInt(1);
         String oldCategoryName = currentRs.getString(2);

         // Update the narrative row
         PreparedStatement updNarrative = c.prepareStatement(
            "UPDATE trx_narrative SET trx_category_id = ?, pattern = ?, confidence = ?, match_type = ? WHERE id = ?");
         updNarrative.setInt(1,    newCategoryId);
         updNarrative.setString(2, pattern);
         updNarrative.setString(3, confidence);
         updNarrative.setString(4, matchType);
         updNarrative.setInt(5,    id);
         updNarrative.executeUpdate();

         int retroUpdated = 0;

         // If the category changed, reclassify matching trx_categorised rows
         if (newCategoryId != oldCategoryId)
         {
            PreparedStatement getNewCat = c.prepareStatement(
               "SELECT name FROM trx_category WHERE id = ?");
            getNewCat.setInt(1, newCategoryId);
            ResultSet newCatRs = getNewCat.executeQuery();
            if (!newCatRs.next())
            {
               setError("New category not found.");
               return getError();
            }
            String newCategoryName = newCatRs.getString(1);

            String likePattern;
            if ("starts_with".equals(matchType))
               likePattern = pattern + "%";
            else
               likePattern = "%" + pattern + "%";   // contains (default)

            PreparedStatement retro = c.prepareStatement(
               "UPDATE trx_categorised SET category = ? " +
               "WHERE UPPER(narrative) LIKE UPPER(?) AND category = ?");
            retro.setString(1, newCategoryName);
            retro.setString(2, likePattern);
            retro.setString(3, oldCategoryName);
            retroUpdated = retro.executeUpdate();
         }

         JSONObject result = new JSONObject();
         result.put("status",        "ok");
         result.put("retro_updated", retroUpdated);
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to update narrative: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
