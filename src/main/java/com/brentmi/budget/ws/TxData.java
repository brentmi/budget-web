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
 * Read-only data endpoints for the transaction dashboard and explorer.
 * All queries are against trx_categorised.
 */
@Path("/tx-data")
public class TxData extends AllowDeny
{
   public TxData()
   {
      super("ENABLED");
   }


   // ── GET /ws/tx-data/years ────────────────────────────────────────────
   // Returns array of available calendar years, most recent first.
   // e.g. [2025, 2024, 2023]
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
         PreparedStatement st = c.prepareStatement(
            "SELECT DISTINCT YEAR(when_date) AS yr FROM trx_categorised ORDER BY yr DESC"
         );
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
            arr.put(rs.getInt("yr"));
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load years: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-data/overview ─────────────────────────────────────────
   // Returns debit/credit/count totals for the two most recent calendar years.
   // Used by the tx-dashboard stat cards.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("overview")
   public String getOverview(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getOverview"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT YEAR(when_date) AS yr, " +
            "       ROUND(SUM(debit_amount),  2) AS total_debit, " +
            "       ROUND(SUM(credit_amount), 2) AS total_credit, " +
            "       COUNT(*) AS row_count " +
            "FROM trx_categorised " +
            "WHERE YEAR(when_date) >= YEAR(NOW()) - 1 " +
            "GROUP BY yr " +
            "ORDER BY yr DESC"
         );
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("year",        rs.getInt("yr"));
            row.put("totalDebit",  rs.getDouble("total_debit"));
            row.put("totalCredit", rs.getDouble("total_credit"));
            row.put("rowCount",    rs.getInt("row_count"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load overview: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-data/monthly/{year} ───────────────────────────────────
   // Monthly debit/credit totals for a given year.
   // Returns only months that have data (no zero-fill).
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("monthly/{year}")
   public String getMonthly(@Context HttpServletRequest request, @PathParam("year") int year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getMonthly"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT MONTH(when_date) AS m, " +
            "       ROUND(SUM(debit_amount),  2) AS total_debit, " +
            "       ROUND(SUM(credit_amount), 2) AS total_credit, " +
            "       COUNT(*) AS row_count " +
            "FROM trx_categorised " +
            "WHERE YEAR(when_date) = ? " +
            "GROUP BY m " +
            "ORDER BY m ASC"
         );
         st.setInt(1, year);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("month",       rs.getInt("m"));
            row.put("totalDebit",  rs.getDouble("total_debit"));
            row.put("totalCredit", rs.getDouble("total_credit"));
            row.put("rowCount",    rs.getInt("row_count"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load monthly data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-data/categories/{year} ────────────────────────────────
   // Category debit totals for a given year, sorted by total debit descending.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("categories/{year}")
   public String getCategories(@Context HttpServletRequest request, @PathParam("year") int year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getCategories"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT category, " +
            "       ROUND(SUM(debit_amount), 2) AS total_debit, " +
            "       COUNT(*) AS row_count " +
            "FROM trx_categorised " +
            "WHERE YEAR(when_date) = ? " +
            "GROUP BY category " +
            "ORDER BY total_debit DESC"
         );
         st.setInt(1, year);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("category",   rs.getString("category"));
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
         setError("Failed to load categories: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-data/monthly-by-category/{year} ───────────────────────
   // Returns { month, category, totalDebit } for every month×category pair.
   // Used to build the stacked bar chart in tx-explore.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("monthly-by-category/{year}")
   public String getMonthlyByCategory(@Context HttpServletRequest request, @PathParam("year") int year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getMonthlyByCategory"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT MONTH(when_date) AS m, " +
            "       category, " +
            "       ROUND(SUM(debit_amount), 2) AS total_debit " +
            "FROM trx_categorised " +
            "WHERE YEAR(when_date) = ? " +
            "GROUP BY m, category " +
            "ORDER BY m ASC, total_debit DESC"
         );
         st.setInt(1, year);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("month",      rs.getInt("m"));
            row.put("category",   rs.getString("category"));
            row.put("totalDebit", rs.getDouble("total_debit"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load monthly-by-category data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-data/transactions ─────────────────────────────────────
   // Individual transaction rows. year is required. month=0 and category=""
   // mean "all". Results capped at 2000 rows.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("transactions")
   public String getTransactions(@Context HttpServletRequest request,
                                 @QueryParam("year")     int    year,
                                 @QueryParam("month")    int    month,
                                 @QueryParam("category") String category)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getTransactions"))
         return getError();

      if (year == 0)
      {
         setError("year parameter is required.");
         return getError();
      }

      boolean hasMonth    = month > 0;
      boolean hasCategory = category != null && !category.trim().isEmpty();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);

         StringBuilder sql = new StringBuilder(
            "SELECT when_date, narrative, debit_amount, credit_amount, category, confidence " +
            "FROM trx_categorised " +
            "WHERE YEAR(when_date) = ? "
         );
         if (hasMonth)    sql.append("AND MONTH(when_date) = ? ");
         if (hasCategory) sql.append("AND category = ? ");
         sql.append("ORDER BY when_date DESC LIMIT 2000");

         PreparedStatement st = c.prepareStatement(sql.toString());
         int idx = 1;
         st.setInt(idx++, year);
         if (hasMonth)    st.setInt(idx++, month);
         if (hasCategory) st.setString(idx++, category.trim());

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
            row.put("confidence",   rs.getString("confidence"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load transactions: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
