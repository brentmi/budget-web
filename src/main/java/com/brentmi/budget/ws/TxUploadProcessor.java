/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.brentmi.budget.ws;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.Part;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;

/**
 *
 * @author brentmi
 */
@Path("/upload")
public class TxUploadProcessor extends AllowDeny
{
   
   public TxUploadProcessor()
   {
      super("ENABLED");
   }
   
   @POST
   @Consumes(MediaType.MULTIPART_FORM_DATA)
   @Produces(MediaType.APPLICATION_JSON)
   @Path("ingestcategorise")
   public String ingestCategorise(@Context HttpServletRequest request)
   {
      try
      {
         Part file = request.getPart("file");
         return new TxCategoriser().processCcExportCsv(request, file);
      }
      catch(Exception e)
      {
         setError(e.getMessage());
         return getError();
      }
   }
}
