/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package com.brentmi.budget;

import com.brentmi.budget.Control;
import com.brentmi.budget.AccessLevels;
import java.io.PrintWriter;
import jakarta.servlet.http.HttpServletRequest;

/**
 *
 * @author brentmi
 */
public class WebControl extends Control 
{

   @Override
   public String getNextPage(HttpServletRequest request, PrintWriter out) throws Exception
   {
      PageHandler ph = new PageHandler();
      return ph.handle(request, out);
   }
   
   @Override
   public AccessLevels getDefaultAccessLevels()
   {
      return new CPAccessLevels();
   }
}
