/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;

/**
 *
 * @author millingtonb
 */
public class UserCheck
{
   public UserCheck()
   {
      
   }
   
   public static boolean validate(HttpServletRequest request, String level) throws ServletException
   {
      UserToken ut = null; 
      if(request.getSession().getAttribute("userToken") != null)
         ut = (UserToken)request.getSession().getAttribute("userToken");
      
      if(ut == null || ! ut.hasAccess(level))
         throw new ServletException("Sorry you do not have adequate permissions to use this function!");
      
      return true;
   }
}
