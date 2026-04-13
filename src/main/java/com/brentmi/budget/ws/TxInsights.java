package com.brentmi.budget.ws;

import com.brentmi.budget.Datasource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.GET;
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

/**
 * Insight-level data endpoints for tx-insights.jsp.
 * All queries are against trx_categorised.
 */
@Path("/tx-insights")
public class TxInsights extends AllowDeny
{
   public TxInsights()
   {
      super("ENABLED");
   }


   // ── GET /ws/tx-insights/rolling/{year} ───────────────────────────────
   // Returns monthly debit totals for the selected year plus November and
   // December of the prior year so the caller can compute a 3-month
   // rolling average back to January of the selected year.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("rolling/{year}")
   public String getRolling(@Context HttpServletRequest request, @PathParam("year") int year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getRolling"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT YEAR(when_date) AS yr, MONTH(when_date) AS m, " +
            "       ROUND(SUM(debit_amount), 2) AS total_debit, " +
            "       COUNT(*) AS row_count " +
            "FROM trx_categorised " +
            "WHERE debit_amount > 0 " +
            "  AND (   (YEAR(when_date) = ? - 1 AND MONTH(when_date) >= 11) " +
            "       OR  YEAR(when_date) = ? " +
            "      ) " +
            "GROUP BY yr, m " +
            "ORDER BY yr ASC, m ASC"
         );
         st.setInt(1, year);
         st.setInt(2, year);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("year",       rs.getInt("yr"));
            row.put("month",      rs.getInt("m"));
            row.put("totalDebit", rs.getDouble("total_debit"));
            row.put("rowCount",   rs.getInt("row_count"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load rolling data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-insights/largest?year=&limit= ────────────────────────
   // Returns the top N debit transactions for the year, sorted by amount.
   // limit defaults to 20, max 50.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("largest")
   public String getLargest(@Context HttpServletRequest request,
                            @QueryParam("year")  int year,
                            @QueryParam("limit") int limit)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getLargest"))
         return getError();

      if (year == 0)
      {
         setError("year parameter is required.");
         return getError();
      }
      if (limit <= 0 || limit > 50) limit = 20;

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT when_date, narrative, debit_amount, credit_amount, category " +
            "FROM trx_categorised " +
            "WHERE YEAR(when_date) = ? AND debit_amount > 0 " +
            "ORDER BY debit_amount DESC " +
            "LIMIT ?"
         );
         st.setInt(1, year);
         st.setInt(2, limit);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("date",         rs.getDate("when_date").toString());
            row.put("narrative",    rs.getString("narrative"));
            row.put("debitAmount",  rs.getDouble("debit_amount"));
            row.put("creditAmount", rs.getDouble("credit_amount"));
            row.put("category",     rs.getString("category"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load largest transactions: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-insights/dow/{year} ──────────────────────────────────
   // Returns total and average debit spend grouped by day of week.
   // MySQL DAYOFWEEK: 1=Sunday … 7=Saturday.
   // days_count = number of distinct calendar dates with that weekday,
   // used by the caller to compute average spend per weekday occurrence.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("dow/{year}")
   public String getDayOfWeek(@Context HttpServletRequest request, @PathParam("year") int year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getDayOfWeek"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT DAYOFWEEK(when_date)           AS dow, " +
            "       DAYNAME(when_date)              AS dow_name, " +
            "       ROUND(SUM(debit_amount), 2)     AS total_debit, " +
            "       COUNT(*)                        AS row_count, " +
            "       COUNT(DISTINCT when_date)       AS days_count " +
            "FROM trx_categorised " +
            "WHERE YEAR(when_date) = ? AND debit_amount > 0 " +
            "GROUP BY dow, dow_name " +
            "ORDER BY dow ASC"
         );
         st.setInt(1, year);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("dow",        rs.getInt("dow"));
            row.put("dowName",    rs.getString("dow_name"));
            row.put("totalDebit", rs.getDouble("total_debit"));
            row.put("rowCount",   rs.getInt("row_count"));
            row.put("daysCount",  rs.getInt("days_count"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load day-of-week data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-insights/projection/{year} ───────────────────────────
   // Per-category: total debit, months with data, average monthly spend,
   // and projected annual (avg * 12). Sorted by projected_annual DESC.
   // months_active lets the caller flag partial-year estimates.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("projection/{year}")
   public String getProjection(@Context HttpServletRequest request, @PathParam("year") int year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getProjection"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT category, " +
            "       ROUND(SUM(debit_amount), 2)                                  AS total_debit, " +
            "       COUNT(DISTINCT MONTH(when_date))                             AS months_active, " +
            "       ROUND(SUM(debit_amount) / COUNT(DISTINCT MONTH(when_date)), 2) AS avg_monthly, " +
            "       ROUND(SUM(debit_amount) / COUNT(DISTINCT MONTH(when_date)) * 12, 2) AS projected_annual " +
            "FROM trx_categorised " +
            "WHERE YEAR(when_date) = ? AND debit_amount > 0 " +
            "GROUP BY category " +
            "ORDER BY projected_annual DESC"
         );
         st.setInt(1, year);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("category",        rs.getString("category"));
            row.put("totalDebit",      rs.getDouble("total_debit"));
            row.put("monthsActive",    rs.getInt("months_active"));
            row.put("avgMonthly",      rs.getDouble("avg_monthly"));
            row.put("projectedAnnual", rs.getDouble("projected_annual"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load projection data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
