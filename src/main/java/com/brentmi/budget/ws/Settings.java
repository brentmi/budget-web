package com.brentmi.budget.ws;

import com.brentmi.budget.Datasource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import org.json.JSONObject;

@Path("/")
public class Settings extends AllowDeny
{
   public Settings()
   {
      super("ENABLED");
   }

   // GET /ws/settings/{name}
   // Returns a single setting by name: { "name": "...", "value": "..." }
   // Returns { "name": "...", "value": null } if not found
   @GET
   @Produces(MediaType.APPLICATION_JSON)
   @Path("settings/{name}")
   public String getSetting(@Context HttpServletRequest request,
                            @PathParam("name") String name)
   {
      JSONObject o = new JSONObject();
      if (!assertAllow(request, o, "getSetting"))
         return getError();

      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         PreparedStatement st = c.prepareStatement(
            "SELECT name, value FROM settings WHERE name = ?");
         st.setString(1, name);
         ResultSet rs = st.executeQuery();

         JSONObject result = new JSONObject();
         if (rs.next())
         {
            result.put("name",  rs.getString(1));
            result.put("value", rs.getString(2));
         }
         else
         {
            result.put("name",  name);
            result.put("value", JSONObject.NULL);
         }
         return result.toString();
      }
      catch (Exception e)
      {
         setError("Failed to load setting: " + e.getMessage());
         return getError();
      }
      finally
      {
         if (c != null) try { c.close(); } catch (Exception ignored) {}
      }
   }
}
