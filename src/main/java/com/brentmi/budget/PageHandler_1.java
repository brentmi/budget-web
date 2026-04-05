/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package com.brentmi.budget;

import java.io.PrintWriter;
import jakarta.servlet.http.HttpServletRequest;

/**
 *
 * @author brentmi
 */
public interface PageHandler_1 
{
   public String handle(HttpServletRequest request, PrintWriter out) throws Exception;
}
