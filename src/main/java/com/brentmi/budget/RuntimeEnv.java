/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.brentmi.budget;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

/**
 *
 * @author brentmi
 */
public class RuntimeEnv
{
   static String platform;
   static 
   {
      try
      {   
         System.out.println("RuntimeEnv setting variables.. ");
         File file = new File("/etc/budgetapi_tomcat.env");
         try (BufferedReader reader = new BufferedReader(new FileReader(file))) 
         {
            String line;
            while ((line = reader.readLine()) != null) 
            {
               if(line.trim().equals(""))
                  continue;
               
               String[] kv = line.trim().split("=");
               if(kv.length != 2)
                  throw new Exception("Invalid parameters: " + line);
               
               switch(kv[0])
               {
                  case "PLATFORM":
                     platform = kv[1];
                     break;
                     
                  default:
                     throw new Exception("");
               }
            }   
            reader.close();
         }
      }
      catch(Exception e)
      {
         throw new RuntimeException(e.getMessage());
      }
   }
   
   public static String getPlatform()
   {
      return platform;
   }
}
