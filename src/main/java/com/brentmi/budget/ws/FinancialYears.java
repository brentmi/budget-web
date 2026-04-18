package com.brentmi.budget.ws;

import com.brentmi.budget.Datasource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
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
public class FinancialYears extends AllowDeny
{
   public FinancialYears()
   {
      super("ENABLED");
   }

   // GET /ws/years
   // Returns all financial years ordered by start_date
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("years")
   public String getYears(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getYears"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "SELECT id, year_label, start_date, end_date, opening_balance, target_gain, net_spend_budget " +
                      "FROM financial_year ORDER BY start_date ASC";
         PreparedStatement st = c.prepareStatement(sql);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",               rs.getInt(1));
            row.put("year_label",       rs.getString(2));
            row.put("start_date",       rs.getString(3));
            row.put("end_date",         rs.getString(4));
            row.put("opening_balance",  rs.getDouble(5));
            row.put("target_gain",      rs.getDouble(6));
            row.put("net_spend_budget", rs.getObject(7));
            arr.put(row);
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load financial years: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // GET /ws/years/{id}
   // Returns one financial year by id
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("years/{id}")
   public String getYear(@Context HttpServletRequest request, @PathParam("id") int id)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getYear"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         String sql = "SELECT id, year_label, start_date, end_date, opening_balance, target_gain, net_spend_budget " +
                      "FROM financial_year WHERE id = ?";
         PreparedStatement st = c.prepareStatement(sql);
         st.setInt(1, id);
         ResultSet rs = st.executeQuery();
         if (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("id",               rs.getInt(1));
            row.put("year_label",       rs.getString(2));
            row.put("start_date",       rs.getString(3));
            row.put("end_date",         rs.getString(4));
            row.put("opening_balance",  rs.getDouble(5));
            row.put("target_gain",      rs.getDouble(6));
            row.put("net_spend_budget", rs.getObject(7));
            return row.toString();
         }
         JSONObject notFound = new JSONObject();
         notFound.put("status", "not_found");
         return notFound.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load year: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }

   // POST /ws/years
   // Body: { "year_label":"2027-2028", "start_date":"2027-07-01", "end_date":"2028-06-30",
   //         "opening_balance":0.00, "target_gain":20000.00 }
   // Creates the year and auto-creates 12 budget_month rows.
   @POST
   @Consumes(MediaType.APPLICATION_JSON)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("years")
   public String createYear(@Context HttpServletRequest request, String json)
   {
      JSONObject o = new JSONObject(json);
      if (!assertAllow(request, o, "createYear"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         c.setAutoCommit(false);

         // Insert financial year
         String sql = "INSERT INTO financial_year (year_label, start_date, end_date, opening_balance, target_gain, net_spend_budget) " +
                      "VALUES (?, ?, ?, ?, ?, ?)";
         PreparedStatement st = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
         st.setString(1, o.getString("year_label"));
         st.setString(2, o.getString("start_date"));
         st.setString(3, o.getString("end_date"));
         st.setDouble(4, o.optDouble("opening_balance", 0.00));
         st.setDouble(5, o.optDouble("target_gain", 20000.00));
         if (o.isNull("net_spend_budget"))
            st.setNull(6, java.sql.Types.DECIMAL);
         else
            st.setDouble(6, o.getDouble("net_spend_budget"));
         st.executeUpdate();

         ResultSet keys = st.getGeneratedKeys();
         if (!keys.next())
            throw new Exception("Failed to get generated year id");
         int yearId = keys.getInt(1);

         // Auto-create 12 budget_month rows (1=July ... 12=June)
         String monthSql = "INSERT INTO budget_month (year_id, month_number) VALUES (?, ?)";
         PreparedStatement monthSt = c.prepareStatement(monthSql);
         for (int m = 1; m <= 12; m++)
         {
            monthSt.setInt(1, yearId);
            monthSt.setInt(2, m);
            monthSt.addBatch();
         }
         monthSt.executeBatch();

         c.commit();

         JSONObject result = new JSONObject();
         result.put("status", "ok");
         result.put("year_id", yearId);
         return result.toString();
      }
      catch (Exception e)
      {
         if (c != null) try { c.rollback(); } catch (Exception ignored) {}
         setError("Failed to create year: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.setAutoCommit(true); c.close(); } catch (Exception ignored) {}
      }
   }
}
