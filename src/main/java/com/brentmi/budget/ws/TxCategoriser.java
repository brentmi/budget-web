package com.brentmi.budget.ws;

import com.brentmi.budget.AuditLogger;
import com.brentmi.budget.Datasource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.Part;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Categorises credit-card CSV exports and inserts results into trx_categorised.
 *
 * DB tables used:
 *   trx_category             - spending buckets
 *   trx_narrative            - keyword matching rules
 *   trx_narrative_overrides  - manual override corrections
 *   trx_categorised          - output / destination table
 *
 * CSV columns expected: Date, Narrative, Debit Amount, Credit Amount
 * Date format expected: d/M/yyyy  (e.g. 3/4/2025 or 03/04/2025)
 */
public class TxCategoriser
{
   private static final int NARRATIVE_MAX_LEN = 128;
   private static final int BATCH_SIZE        = 500;


   // ── Public entry point ───────────────────────────────────────────────────

   public String processCcExportCsv(HttpServletRequest request, Part file) throws Exception
   {
      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);

         List<String[]> rules     = loadRules(c);
         List<String[]> overrides = loadOverrides(c);
         Date           maxDate   = getMaxDate(c);

         // Parse CSV — each row is String[6]: { dateStr, narrative, debitStr, creditStr, category, confidence }
         // Slots 4 and 5 are empty strings here; filled in below.
         List<String[]> rows = parseCsv(file);

         // Categorise every row in-place
         for (String[] row : rows)
         {
            String[] cat = categorise(row[1], rules, overrides);
            row[4] = cat[0];
            row[5] = cat[1];
         }

         // Insert rows that are newer than maxDate
         int[] insertCounts = insertRows(c, rows, maxDate);
         int inserted = insertCounts[0];
         int excluded = insertCounts[1];

         // Build summary grouped by category, over ALL rows in the file (mirrors Python behaviour)
         Map<String, double[]> byCategory = new LinkedHashMap<>();   // category -> { rowCount, totalDebit }
         int uncategorisedRows            = 0;
         LinkedHashMap<String, Double> uncatNarratives = new LinkedHashMap<>(); // unique narrative -> debit

         for (String[] row : rows)
         {
            String cat   = row[4];
            double debit = parseAmount(row[2]);

            if (!byCategory.containsKey(cat))
               byCategory.put(cat, new double[]{ 0, 0.0 });
            byCategory.get(cat)[0]++;
            byCategory.get(cat)[1] += debit;

            if ("Other / Unknown".equals(cat))
            {
               uncategorisedRows++;
               uncatNarratives.putIfAbsent(row[1], debit);
            }
         }

         // Sort summary by total debit descending
         List<Map.Entry<String, double[]>> sorted = new ArrayList<>(byCategory.entrySet());
         sorted.sort((a, b) -> Double.compare(b.getValue()[1], a.getValue()[1]));

         JSONArray summaryArr = new JSONArray();
         for (Map.Entry<String, double[]> entry : sorted)
         {
            JSONObject s = new JSONObject();
            s.put("category",   entry.getKey());
            s.put("count",      (int) entry.getValue()[0]);
            s.put("totalDebit", Math.round(entry.getValue()[1] * 100.0) / 100.0);
            summaryArr.put(s);
         }

         JSONArray uncatArr = new JSONArray();
         for (Map.Entry<String, Double> entry : uncatNarratives.entrySet())
         {
            JSONObject u = new JSONObject();
            u.put("narrative",   entry.getKey());
            u.put("debitAmount", entry.getValue());
            uncatArr.put(u);
         }

         // Audit log — swallowed if log service is unavailable so the main result still returns
         String logMsg = "TxCategoriser: " + rows.size() + " rows processed | "
                       + inserted + " inserted | " + excluded + " excluded | "
                       + uncategorisedRows + " uncategorised | "
                       + rules.size() + " rules loaded";
         try { AuditLogger.log(logMsg, request); }
         catch (Exception ignored) {}

         JSONObject result = new JSONObject();
         result.put("status",            "ok");
         result.put("totalRows",         rows.size());
         result.put("inserted",          inserted);
         result.put("excluded",          excluded);
         result.put("uncategorisedRows", uncategorisedRows);
         result.put("rulesLoaded",       rules.size());
         result.put("overridesLoaded",   overrides.size());
         result.put("summary",           summaryArr);
         result.put("uncategorised",     uncatArr);
         return result.toString();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }


   // ── Rule / override loading ──────────────────────────────────────────────

   // Returns list of String[4]: { pattern, matchType, category, confidence }
   private List<String[]> loadRules(Connection c) throws Exception
   {
      List<String[]> rules = new ArrayList<>();
      PreparedStatement st = c.prepareStatement(
         "SELECT n.pattern, n.match_type, cat.name, n.confidence " +
         "FROM trx_narrative n " +
         "JOIN trx_category cat ON n.trx_category_id = cat.id " +
         "ORDER BY n.id ASC"
      );
      ResultSet rs = st.executeQuery();
      while (rs.next())
         rules.add(new String[]{ rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4) });
      rs.close();
      st.close();

      if (rules.isEmpty())
         throw new Exception("trx_narrative table is empty — seed the database before running.");

      return rules;
   }

   // Returns list of String[2]: { narrativePattern, correctCategory }
   private List<String[]> loadOverrides(Connection c) throws Exception
   {
      List<String[]> overrides = new ArrayList<>();
      PreparedStatement st = c.prepareStatement(
         "SELECT narrative_pattern, correct_category FROM trx_narrative_overrides ORDER BY id ASC"
      );
      ResultSet rs = st.executeQuery();
      while (rs.next())
         overrides.add(new String[]{ rs.getString(1), rs.getString(2) });
      rs.close();
      st.close();
      return overrides;
   }

   private Date getMaxDate(Connection c) throws Exception
   {
      PreparedStatement st = c.prepareStatement("SELECT MAX(when_date) FROM trx_categorised");
      ResultSet rs = st.executeQuery();
      Date maxDate = null;
      if (rs.next())
         maxDate = rs.getDate(1);
      rs.close();
      st.close();
      return maxDate;
   }


   // ── Categorisation ───────────────────────────────────────────────────────

   // Returns String[2]: { category, confidence }
   // Precedence: overrides first, then rules in id order, then "Other / Unknown".
   private String[] categorise(String narrative, List<String[]> rules, List<String[]> overrides)
   {
      if (narrative == null || narrative.trim().isEmpty())
         return new String[]{ "Other / Unknown", "low" };

      String upper = narrative.toUpperCase();

      for (String[] ov : overrides)
         if (upper.contains(ov[0].toUpperCase()))
            return new String[]{ ov[1], "high" };

      for (String[] rule : rules)
      {
         String pattern   = rule[0].toUpperCase();
         String matchType = rule[1];

         if ("contains".equals(matchType) && upper.contains(pattern))
            return new String[]{ rule[2], rule[3] };
         if ("starts_with".equals(matchType) && upper.startsWith(pattern))
            return new String[]{ rule[2], rule[3] };
      }

      return new String[]{ "Other / Unknown", "low" };
   }


   // ── CSV parsing ──────────────────────────────────────────────────────────

   // Returns list of String[6]: { dateStr, narrative, debitStr, creditStr, "", "" }
   private List<String[]> parseCsv(Part file) throws Exception
   {
      List<String[]> rows = new ArrayList<>();
      BufferedReader reader = new BufferedReader(
         new InputStreamReader(file.getInputStream(), "UTF-8")
      );

      String headerLine = reader.readLine();
      if (headerLine == null)
         throw new Exception("CSV file is empty.");

      List<String> headers = splitCsvLine(headerLine);
      int idxDate   = findHeader(headers, "Date");
      int idxNarr   = findHeader(headers, "Narrative");
      int idxDebit  = findHeader(headers, "Debit Amount");
      int idxCredit = findHeader(headers, "Credit Amount");

      if (idxDate < 0 || idxNarr < 0 || idxDebit < 0 || idxCredit < 0)
         throw new Exception(
            "CSV is missing one or more required columns: Date, Narrative, Debit Amount, Credit Amount"
         );

      int minIdx = Math.max(idxDate, Math.max(idxNarr, Math.max(idxDebit, idxCredit)));

      String line;
      while ((line = reader.readLine()) != null)
      {
         if (line.trim().isEmpty())
            continue;

         List<String> fields = splitCsvLine(line);
         if (fields.size() <= minIdx)
            continue; // skip malformed / short rows

         rows.add(new String[]{
            fields.get(idxDate).trim(),
            fields.get(idxNarr).trim(),
            fields.get(idxDebit).trim(),
            fields.get(idxCredit).trim(),
            "",   // category   — filled in by categorise()
            ""    // confidence — filled in by categorise()
         });
      }
      reader.close();

      if (rows.isEmpty())
         throw new Exception("CSV file contains no data rows.");

      return rows;
   }

   private int findHeader(List<String> headers, String name)
   {
      for (int i = 0; i < headers.size(); i++)
         if (name.equalsIgnoreCase(headers.get(i).trim()))
            return i;
      return -1;
   }

   // Splits a single CSV line, respecting quoted fields and doubled-quote escaping.
   private List<String> splitCsvLine(String line)
   {
      List<String> fields = new ArrayList<>();
      StringBuilder field = new StringBuilder();
      boolean inQuotes    = false;

      for (int i = 0; i < line.length(); i++)
      {
         char ch = line.charAt(i);

         if (ch == '"')
         {
            // Doubled quote inside a quoted field is an escaped quote character
            if (inQuotes && i + 1 < line.length() && line.charAt(i + 1) == '"')
            {
               field.append('"');
               i++;
            }
            else
            {
               inQuotes = !inQuotes;
            }
         }
         else if (ch == ',' && !inQuotes)
         {
            fields.add(field.toString());
            field.setLength(0);
         }
         else
         {
            field.append(ch);
         }
      }
      fields.add(field.toString());
      return fields;
   }


   // ── DB insert ────────────────────────────────────────────────────────────

   // Returns int[2]: { inserted, excluded }
   // Only inserts rows where when_date > maxDate (or all rows when maxDate is null).
   private int[] insertRows(Connection c, List<String[]> rows, Date maxDate) throws Exception
   {
      SimpleDateFormat sdf = new SimpleDateFormat("d/M/yyyy");
      sdf.setLenient(false);

      String sql =
         "INSERT INTO trx_categorised " +
         "(when_date, narrative, debit_amount, credit_amount, category, confidence) " +
         "VALUES (?, ?, ?, ?, ?, ?)";

      PreparedStatement st = c.prepareStatement(sql);

      int inserted     = 0;
      int excluded     = 0;
      int batchPending = 0;

      for (String[] row : rows)
      {
         java.util.Date parsed;
         try { parsed = sdf.parse(row[0]); }
         catch (Exception e) { continue; } // skip rows with unparseable dates

         Date whenDate = new Date(parsed.getTime());

         if (maxDate != null && !whenDate.after(maxDate))
         {
            excluded++;
            continue;
         }

         String narrative = row[1];
         if (narrative.length() > NARRATIVE_MAX_LEN)
            narrative = narrative.substring(0, NARRATIVE_MAX_LEN);

         st.setDate(1,   whenDate);
         st.setString(2, narrative);
         st.setDouble(3, parseAmount(row[2]));
         st.setDouble(4, parseAmount(row[3]));
         st.setString(5, row[4]);
         st.setString(6, row[5]);
         st.addBatch();
         batchPending++;

         if (batchPending % BATCH_SIZE == 0)
         {
            st.executeBatch();
            inserted += BATCH_SIZE;
            batchPending = 0;
         }
      }

      if (batchPending > 0)
      {
         st.executeBatch();
         inserted += batchPending;
      }

      st.close();
      return new int[]{ inserted, excluded };
   }

   private double parseAmount(String s)
   {
      if (s == null || s.trim().isEmpty())
         return 0.0;
      try { return Double.parseDouble(s.trim()); }
      catch (NumberFormatException e) { return 0.0; }
   }
}
