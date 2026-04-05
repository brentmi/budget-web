/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.brentmi.budget;

import java.util.Base64;
import org.json.JSONObject;


/**
 *
 * @author brentmillington
 */
public class JwtDecoder
{
   static String getUser(String jwt) throws Exception
   {
      return ""+decode(jwt).get("sub").toString();
   }
   
   static JSONObject decode(String jwt) throws Exception
   {
      String[] chunks = jwt.split("\\.");
      Base64.Decoder decoder = Base64.getUrlDecoder();
      
      String header = new String(decoder.decode(chunks[0]));
      String payload = new String(decoder.decode(chunks[1]));
      
      JSONObject o = new JSONObject(payload);
      return o;
   }
   
   public static void main(String[] args)
   {
      try
      {   
         System.out.println(JwtDecoder.decode(DevJwt.getJwt()).toString());
         System.out.println(JwtDecoder.getUser(DevJwt.getJwt()));
      }
      catch(Exception e)
      {
         e.printStackTrace();
      }
   }
}
