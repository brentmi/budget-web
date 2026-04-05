/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import jakarta.servlet.ServletContextEvent;
import com.brentmi.budget.RuntimeEnv;

/**
 *
 * @author millingtonb
 */
public class ServletContextListener implements jakarta.servlet.ServletContextListener
{
   @Override
   public void contextInitialized(ServletContextEvent arg0) 
   {
      System.out.println("ServletContextListener Starting...");
   
      arg0.getServletContext().setInitParameter("platform", RuntimeEnv.getPlatform());
      
      System.out.println("Runtime environment: Platform=" + RuntimeEnv.getPlatform());
   }
        
   @Override
   public void contextDestroyed(ServletContextEvent arg0) 
   {
      System.out.println("ServletContextListener Shutdown.");
   }
}
