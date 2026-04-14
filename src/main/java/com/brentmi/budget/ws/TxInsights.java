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
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
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


   // ── GET /ws/tx-insights/anomalies/{year} ─────────────────────────────
   // Detects months where a category's spend was >25% above its 6-month
   // trailing average. Fetches 6 context months before the selected year
   // so January can have a meaningful baseline. Requires at least 2 prior
   // months of data per category and a minimum average of $50 to avoid
   // noise from tiny categories. Returns results sorted by pctAbove DESC.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("anomalies/{year}")
   public String getAnomalies(@Context HttpServletRequest request, @PathParam("year") int year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getAnomalies"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT YEAR(when_date) AS yr, MONTH(when_date) AS m, category, " +
            "       ROUND(SUM(debit_amount), 2) AS total_debit " +
            "FROM trx_categorised " +
            "WHERE debit_amount > 0 " +
            "  AND (   (YEAR(when_date) = ? - 1 AND MONTH(when_date) >= 7) " +
            "       OR  YEAR(when_date) = ? " +
            "      ) " +
            "GROUP BY yr, m, category " +
            "ORDER BY yr ASC, m ASC, category ASC"
         );
         st.setInt(1, year);
         st.setInt(2, year);
         ResultSet rs = st.executeQuery();

         // category -> chronological list of {yrMonth, totalDebit}
         // yrMonth key = yr * 100 + m  (e.g. 202507 = July 2025)
         Map<String, List<long[]>> byCategory = new LinkedHashMap<>();
         while (rs.next())
         {
            int    yr    = rs.getInt("yr");
            int    m     = rs.getInt("m");
            String cat   = rs.getString("category");
            double total = rs.getDouble("total_debit");
            int    key   = yr * 100 + m;

            if (!byCategory.containsKey(cat))
               byCategory.put(cat, new ArrayList<long[]>());
            byCategory.get(cat).add(new long[]{ key, Double.doubleToLongBits(total) });
         }
         rs.close();
         st.close();

         final double THRESHOLD   = 0.25; // 25% above avg = spike
         final double MIN_AVG     = 50.0; // ignore trivially small categories
         final int    MIN_CONTEXT = 2;    // need at least 2 prior months

         List<JSONObject> anomalies = new ArrayList<JSONObject>();

         for (Map.Entry<String, List<long[]>> entry : byCategory.entrySet())
         {
            String       cat    = entry.getKey();
            List<long[]> months = entry.getValue();

            for (int i = 0; i < months.size(); i++)
            {
               int key = (int)months.get(i)[0];
               int yr  = key / 100;
               int m   = key % 100;
               if (yr != year) continue; // skip context months from prior year

               double actual = Double.longBitsToDouble(months.get(i)[1]);

               // Collect up to 6 prior months for this category
               List<Double> prior = new ArrayList<Double>();
               for (int j = i - 1; j >= 0 && prior.size() < 6; j--)
                  prior.add(Double.longBitsToDouble(months.get(j)[1]));

               if (prior.size() < MIN_CONTEXT) continue;

               double sum = 0;
               for (double v : prior) sum += v;
               double avg = sum / prior.size();

               if (avg < MIN_AVG) continue;

               double pctAbove = (actual - avg) / avg;
               if (pctAbove < THRESHOLD) continue;

               JSONObject row = new JSONObject();
               row.put("month",       m);
               row.put("category",    cat);
               row.put("actualSpend", actual);
               row.put("avgSpend",    Math.round(avg * 100.0) / 100.0);
               row.put("pctAbove",    Math.round(pctAbove * 1000.0) / 10.0);
               anomalies.add(row);
            }
         }

         Collections.sort(anomalies, new Comparator<JSONObject>()
         {
            public int compare(JSONObject a, JSONObject b)
            {
               return Double.compare(b.optDouble("pctAbove", 0), a.optDouble("pctAbove", 0));
            }
         });

         JSONArray arr = new JSONArray();
         for (JSONObject j : anomalies) arr.put(j);
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load anomaly data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-insights/velocity/{year} ──────────────────────────────
   // Average number of days between consecutive transactions per category
   // using MySQL LAG(). days_gap IS NULL for the first transaction in each
   // partition, so those rows are filtered out in the outer query.
   // tx_count = COUNT(*) + 1 restores the dropped first row per category.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("velocity/{year}")
   public String getVelocity(@Context HttpServletRequest request, @PathParam("year") int year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getVelocity"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT category, " +
            "       ROUND(AVG(days_gap), 1) AS avg_days, " +
            "       MAX(days_gap)            AS max_gap, " +
            "       MIN(days_gap)            AS min_gap, " +
            "       COUNT(*) + 1             AS tx_count " +
            "FROM ( " +
            "    SELECT category, " +
            "           DATEDIFF(when_date, " +
            "                    LAG(when_date) OVER (PARTITION BY category ORDER BY when_date)) AS days_gap " +
            "    FROM trx_categorised " +
            "    WHERE debit_amount > 0 AND YEAR(when_date) = ? " +
            ") sub " +
            "WHERE days_gap IS NOT NULL " +
            "GROUP BY category " +
            "HAVING COUNT(*) >= 2 " +
            "ORDER BY avg_days ASC"
         );
         st.setInt(1, year);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("category", rs.getString("category"));
            row.put("avgDays",  rs.getDouble("avg_days"));
            row.put("maxGap",   rs.getInt("max_gap"));
            row.put("minGap",   rs.getInt("min_gap"));
            row.put("txCount",  rs.getInt("tx_count"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load velocity data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-insights/subscriptions ───────────────────────────────
   // Identifies likely recurring charges over the last 24 months.
   // Criteria applied in Java after the query:
   //   - implied interval = total_span_days / (count - 1): must be 20–50 days
   //   - coefficient of variation (stddev / avg): must be < 0.30 (stable amounts)
   //   - minimum 3 occurrences in the window
   // projected_annual = avg_amount * (365 / implied_interval)
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("subscriptions")
   public String getSubscriptions(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getSubscriptions"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT narrative, category, " +
            "       COUNT(*)                                  AS occurrence_count, " +
            "       ROUND(AVG(debit_amount), 2)               AS avg_amount, " +
            "       ROUND(STDDEV(debit_amount), 2)            AS stddev_amount, " +
            "       DATEDIFF(MAX(when_date), MIN(when_date))  AS total_span_days " +
            "FROM trx_categorised " +
            "WHERE debit_amount > 0 " +
            "  AND when_date >= DATE_SUB(NOW(), INTERVAL 24 MONTH) " +
            "GROUP BY narrative, category " +
            "HAVING COUNT(*) >= 3 " +
            "ORDER BY avg_amount DESC"
         );
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            int    count     = rs.getInt("occurrence_count");
            double avgAmount = rs.getDouble("avg_amount");
            double stddev    = rs.getDouble("stddev_amount");
            int    spanDays  = rs.getInt("total_span_days");

            if (count < 2 || spanDays <= 0) continue;

            double impliedInterval = (double)spanDays / (count - 1);
            double cv              = avgAmount > 0 ? stddev / avgAmount : 1.0;

            if (impliedInterval < 20.0 || impliedInterval > 50.0) continue;
            if (cv >= 0.30) continue;

            double projectedAnnual = avgAmount * (365.0 / impliedInterval);

            JSONObject row = new JSONObject();
            row.put("narrative",       rs.getString("narrative"));
            row.put("category",        rs.getString("category"));
            row.put("occurrenceCount", count);
            row.put("avgAmount",       avgAmount);
            row.put("impliedInterval", Math.round(impliedInterval * 10.0) / 10.0);
            row.put("projectedAnnual", Math.round(projectedAnnual * 100.0) / 100.0);
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load subscription data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-insights/merchants/{year} ─────────────────────────────
   // Top 30 narrative+category pairs by total debit for the year.
   // The caller populates a category filter to let users exclude fixed costs.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("merchants/{year}")
   public String getMerchants(@Context HttpServletRequest request, @PathParam("year") int year)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getMerchants"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT narrative, category, " +
            "       COUNT(*) AS tx_count, " +
            "       ROUND(SUM(debit_amount), 2) AS total_debit, " +
            "       ROUND(AVG(debit_amount), 2) AS avg_per_tx " +
            "FROM trx_categorised " +
            "WHERE YEAR(when_date) = ? AND debit_amount > 0 " +
            "GROUP BY narrative, category " +
            "ORDER BY total_debit DESC " +
            "LIMIT 30"
         );
         st.setInt(1, year);
         ResultSet rs = st.executeQuery();
         JSONArray arr = new JSONArray();
         while (rs.next())
         {
            JSONObject row = new JSONObject();
            row.put("narrative",  rs.getString("narrative"));
            row.put("category",   rs.getString("category"));
            row.put("txCount",    rs.getInt("tx_count"));
            row.put("totalDebit", rs.getDouble("total_debit"));
            row.put("avgPerTx",   rs.getDouble("avg_per_tx"));
            arr.put(row);
         }
         rs.close();
         st.close();
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load merchant data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── GET /ws/tx-insights/sub-creep ────────────────────────────────────
   // For each subscription identified by the same criteria as getSubscriptions(),
   // returns monthly amounts across ALL available history for timeline charting.
   // Raw narratives are resolved to their matching trx_narrative pattern so that
   // variants of the same merchant (e.g. "NETFLIX.COM AU 1234" / "... 5678")
   // collapse to a single labelled line on the chart.
   // Limited to top 20 qualifying subscriptions by avg_amount.
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("sub-creep")
   public String getSubCreep(@Context HttpServletRequest request)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getSubCreep"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);

         // Load narrative patterns for label normalisation (same table as TxCategoriser)
         List<String[]> rules = new ArrayList<String[]>();
         PreparedStatement ruleSt = c.prepareStatement(
            "SELECT pattern, match_type FROM trx_narrative ORDER BY id ASC"
         );
         ResultSet ruleRs = ruleSt.executeQuery();
         while (ruleRs.next())
            rules.add(new String[]{ ruleRs.getString("pattern"), ruleRs.getString("match_type") });
         ruleRs.close();
         ruleSt.close();

         // Fetch raw monthly rows for qualifying subscriptions
         PreparedStatement st = c.prepareStatement(
            "SELECT t.narrative, " +
            "       YEAR(t.when_date) AS yr, MONTH(t.when_date) AS m, " +
            "       ROUND(AVG(t.debit_amount), 2) AS month_avg " +
            "FROM trx_categorised t " +
            "INNER JOIN ( " +
            "    SELECT narrative, category " +
            "    FROM ( " +
            "        SELECT narrative, category, AVG(debit_amount) AS avg_amt " +
            "        FROM trx_categorised " +
            "        WHERE debit_amount > 0 " +
            "          AND when_date >= DATE_SUB(NOW(), INTERVAL 24 MONTH) " +
            "        GROUP BY narrative, category " +
            "        HAVING COUNT(*) >= 3 " +
            "           AND DATEDIFF(MAX(when_date), MIN(when_date)) / (COUNT(*) - 1) BETWEEN 20 AND 50 " +
            "           AND STDDEV(debit_amount) / AVG(debit_amount) < 0.30 " +
            "        ORDER BY avg_amt DESC " +
            "        LIMIT 20 " +
            "    ) top_subs " +
            ") subs ON t.narrative = subs.narrative AND t.category = subs.category " +
            "WHERE t.debit_amount > 0 " +
            "GROUP BY t.narrative, yr, m " +
            "ORDER BY t.narrative ASC, yr ASC, m ASC"
         );
         ResultSet rs = st.executeQuery();

         // Resolve each narrative to its pattern label, then aggregate:
         //   label -> (yrMonth -> sumMonthAvg)
         Map<String, Map<Integer, Double>> labelData = new LinkedHashMap<String, Map<Integer, Double>>();

         while (rs.next())
         {
            String rawNarrative = rs.getString("narrative");
            int    yr           = rs.getInt("yr");
            int    m            = rs.getInt("m");
            double monthAvg     = rs.getDouble("month_avg");
            int    yrMonth      = yr * 100 + m;

            String label = resolveLabel(rawNarrative, rules);

            if (!labelData.containsKey(label))
               labelData.put(label, new LinkedHashMap<Integer, Double>());

            Map<Integer, Double> pts = labelData.get(label);
            pts.put(yrMonth, pts.getOrDefault(yrMonth, 0.0) + monthAvg);
         }
         rs.close();
         st.close();

         // Flatten to JSON array sorted by label, then yrMonth
         JSONArray arr = new JSONArray();
         for (Map.Entry<String, Map<Integer, Double>> entry : labelData.entrySet())
         {
            String               label      = entry.getKey();
            Map<Integer, Double> pts        = entry.getValue();
            List<Integer>        sortedKeys = new ArrayList<Integer>(pts.keySet());
            Collections.sort(sortedKeys);

            for (int yrMonth : sortedKeys)
            {
               int    yr  = yrMonth / 100;
               int    m   = yrMonth % 100;
               double avg = pts.get(yrMonth);

               JSONObject row = new JSONObject();
               row.put("label",    label);
               row.put("yr",       yr);
               row.put("m",        m);
               row.put("monthAvg", Math.round(avg * 100.0) / 100.0);
               arr.put(row);
            }
         }
         return arr.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load sub-creep data: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── Helpers ──────────────────────────────────────────────────────────

   // Returns the first trx_narrative pattern whose match_type condition is
   // satisfied by the given narrative (case-insensitive). Falls back to the
   // raw narrative if no rule matches. Mirrors the logic in TxCategoriser.
   private String resolveLabel(String narrative, List<String[]> rules)
   {
      if (narrative == null || narrative.trim().isEmpty())
         return narrative;

      String upper = narrative.trim().toUpperCase();

      for (String[] rule : rules)
      {
         String pattern   = rule[0].toUpperCase();
         String matchType = rule[1];

         if ("contains".equals(matchType)    && upper.contains(pattern))    return rule[0];
         if ("starts_with".equals(matchType) && upper.startsWith(pattern))  return rule[0];
      }

      return narrative; // no match: use raw narrative as label
   }
}
