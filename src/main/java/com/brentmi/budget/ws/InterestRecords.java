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
public class InterestRecords extends AllowDeny
{
   public InterestRecords()
   {
      super("ENABLED");
   }

   // GET /ws/interest
   // Optional ?year=2025-2026 to filter by financial year.
   // Without year param returns all records ordered by date.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("interest")
   public String getRecords(@Context HttpServletRequest request,
                            @QueryParam("year") String year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getInterestRecords"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql;
         PreparedStatement st;
         if (year != null && !year.isEmpty())
         {
            sql = "SELECT id, record_date, net_amount, year_label " +
                  "FROM interest_record WHERE year_label = ? ORDER BY record_date ASC";
            st = c.prepareStatement(sql);
            st.setString(1, year);
         }
         else
         {
            sql = "SELECT id, record_date, net_amount, year_label " +
                  "FROM interest_record ORDER BY record_date ASC";
            st = c.prepareStatement(sql);
         }

         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",          rs.getInt(1));
            row.put("record_date", rs.getString(2));
            row.put("net_amount",  rs.getDouble(3));
            row.put("year_label",  rs.getString(4));
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load interest records: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // POST /ws/interest
   // Body: { "record_date":"2026-04-30", "net_amount":450.00, "year_label":"2025-2026" }
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("interest")
   public String addRecord(@Context HttpServletRequest request, String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "addInterestRecord"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "INSERT INTO interest_record (record_date, net_amount, year_label) VALUES (?, ?, ?)";
         PreparedStatement st = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
         st.setString(1, o.getString("record_date"));
         st.setDouble(2, o.getDouble("net_amount"));
         st.setString(3, o.getString("year_label"));
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
         setError("Failed to add interest record: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // PUT /ws/interest/{id}
   // Body: { "record_date":"2026-04-30", "net_amount":475.00, "year_label":"2025-2026" }
   @PUT
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("interest/{id}")
   public String updateRecord(@Context HttpServletRequest request,
                              @PathParam("id") int id,
                              String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "updateInterestRecord"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "UPDATE interest_record SET record_date = ?, net_amount = ?, year_label = ? WHERE id = ?";
         PreparedStatement st = c.prepareStatement(sql);
         st.setString(1, o.getString("record_date"));
         st.setDouble(2, o.getDouble("net_amount"));
         st.setString(3, o.getString("year_label"));
         st.setInt(4, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to update interest record: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // DELETE /ws/interest/{id}
   @DELETE
   @Produces(MediaType.APPLICATION_JSON)
   @Path("interest/{id}")
   public String deleteRecord(@Context HttpServletRequest request, @PathParam("id") int id)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "deleteInterestRecord"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement("DELETE FROM interest_record WHERE id = ?");
         st.setInt(1, id);
         st.executeUpdate();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to delete interest record: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
