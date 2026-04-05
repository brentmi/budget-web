/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import com.brentmi.budget.Datasource;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Map;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 *
 * @author millingtonb
 * 
 * Required table updates:
 * alter table operator drop column active
 * alter table operator change role_id permission_set int(9) unsigned not null
 * alter table operator add column name varchar(128) not null default '' after id
 * alter table operator add column email varchar(128) default '' after name
 * alter table operator add unique key idx_username(username)
 * 
 */
@WebServlet(name = "UserAdmin", urlPatterns =
{
   "/UserAdmin"
})
public class UserAdmin extends HttpServlet
{

   /**
    * Processes requests for both HTTP <code>GET</code> and <code>POST</code>
    * methods.
    *
    * @param request servlet request
    * @param response servlet response
    * @throws ServletException if a servlet-specific error occurs
    * @throws IOException if an I/O error occurs
    */
   protected void processRequest(HttpServletRequest request, HttpServletResponse response)
           throws ServletException, IOException
   {
      PrintWriter out = response.getWriter();
//      if(request.getParameter("updatePassword") != null)
//      {
//         UserCheck.validate(request, "PWD-SET");
//         out.println(updatePassword(request));
//      }
      
      UserCheck.validate(request, "ADMIN");
      
      if(request.getParameter("getUserDetails") != null)
         out.println(getUser(Integer.valueOf(request.getParameter("id")), request));
   }
   
   public String updatePassword(User user, HttpServletRequest request) throws ServletException
   {
      Connection c = null;
      try
      {
         c = Datasource.getConnection(request);
         //String username = request.getParameter("inputUsername");
         //String password = request.getParameter("inputPassword");
         PreparedStatement st = c.prepareStatement("update operator set password = password(?) where username = ?");
         st.setString(1, user.getPassword());
         st.setString(2, user.getUsername());
         st.executeUpdate();
      }
      catch(Exception e)
      {
         throw new ServletException(e.getMessage());
      }
      finally
      {
         try
         {   
            if(c != null)
               c.close();
         }
         catch(Exception e)
         {
            // ignore
         }
      }
      return "Password updated OK!";
   }
   
   public void updateUserDetails(User user, HttpServletRequest request) throws ServletException
   {
      try
      {
         user.setUserPermissionsFromChBox(((AccessLevels)request.getSession().getAttribute("defaultAccessLevels")));
                 
         Connection c = Datasource.getConnection(request);
         try
         {
            PreparedStatement st = c.prepareStatement("select id, username from operator where id = ?");
            st.setInt(1, user.getUserId());
            ResultSet rs = st.executeQuery();
            if(rs.next() && rs.getString(2).equals(user.getUsername()))
            {
               rs.close();
               
               if(user.getEmail() != null && ! user.getEmail().equals(""))
               {   
                  st = c.prepareStatement("update operator set email = ? where id = ?");
                  st.setString(1, user.getEmail());
                  st.setInt(2, user.getUserId());
                  st.executeUpdate();
               }

               if(user.getPassword() != null && ! user.getPassword().equals(""))
               {   
                  st = c.prepareStatement("update operator set password = password(?) where id = ?");
                  st.setString(1, user.getPassword());
                  st.setInt(2, user.getUserId());
                  st.executeUpdate();
               }

               if(user.getFullName() != null && ! user.getFullName().equals(""))
               {   
                  st = c.prepareStatement("update operator set name = ? where id = ?");
                  st.setString(1, user.getFullName());
                  st.setInt(2, user.getUserId());
                  st.executeUpdate();
               }

               if(user.getPermissionSet() >= 0)
               {   
                  st = c.prepareStatement("update operator set permission_set = ? where id = ?");
                  st.setInt(1, user.getPermissionSet());
                  st.setInt(2, user.getUserId());
                  st.executeUpdate();
               }
            }
            else
            {
               st = c.prepareStatement("insert into operator (id, name, email, username, password, permission_set) values (null, ?, ?, ?, password(?), ?)");
               st.setString(1, user.getFullName());

               if(user.getEmail() != null && ! user.getEmail().equals(""))
                  st.setString(2, user.getEmail());
               else
                  st.setString(2, "");

               st.setString(3, user.getUsername());

               if(user.getPassword() != null && ! user.getPassword().equals(""))
                  st.setString(4, user.getPassword()); 
               else
                  throw new ServletException("Password cannot be empty for a new user.");

               st.setInt(5, user.getPermissionSet());
               st.executeUpdate();
            }
         }
         catch(Exception e)
         {
            throw e;
         }
         finally
         {
            if(c != null)
               c.close();
         }
      }
      catch(Exception e)
      {
         throw new ServletException(e.getMessage());
      }
   }
   
   public String getUser(int id, HttpServletRequest request) throws ServletException
   {
      User user = new User();
      try
      {   
         Connection c = Datasource.getConnection(request);
         try
         {
            PreparedStatement st = c.prepareStatement("select o.id, o.name, o.email, o.username, o.permission_set from operator o where o.id = ?");
            st.setInt(1, id);
            ResultSet rs = st.executeQuery();
            if(rs.next())
            {
               user.setUserId(rs.getInt(1));
               user.setFullName(rs.getString(2));
               user.setEmail(rs.getString(3));
               user.setUsername(rs.getString(4));
               user.setPermissionSet(rs.getInt(5));
            }
         }
         catch(Exception e)
         {
            throw e;
         }
         finally
         {
            if(c != null)
               c.close();
         }
      }
      catch(Exception e)
      {
         throw new ServletException(e.getMessage());
      }
      
      
      StringBuilder json = new StringBuilder();
      json.append("{\"username\":\"").append(user.getUsername()).append("\",");
      json.append("\"fullName\":\"").append(user.getFullName()).append("\",");
      json.append("\"email\":\"").append(user.getEmail()).append("\",");
      json.append("\"id\":\"").append(user.getUserId()).append("\",");
      json.append("\"accessLevels\":\"").append(getAccessLevels(user, request).replaceAll("\"", "\\\\\"")).append("\"}");
      
      return json.toString();
   }
   
   public ArrayList<User> getRegisteredUsers(HttpServletRequest request) throws Exception
   {
      ArrayList users = new ArrayList();
      Connection c = Datasource.getConnection(request);
      try
      {
         // updated
         PreparedStatement st = c.prepareStatement("select id, email, email, username, permission_set from operator where permission_set > 0 order by name");
         ResultSet rs = st.executeQuery();
         while(rs.next())
         {
            User u = new User();
            u.setUserId(rs.getInt(1));
            u.setFullName(rs.getString(2));
            u.setEmail(rs.getString(3));
            u.setUsername(rs.getString(4));
            u.setPermissionSet(rs.getInt(5));
            
            users.add(u);
         }
      }
      catch(Exception e)
      {
         throw e;
      }
      finally
      {
         if(c != null)
            c.close();
      }
      
      return users;
   }
   
   public String getRegisteredUsersSelectList(HttpServletRequest request) throws Exception
   {
      StringBuilder b = new StringBuilder();
      b.append("<select style=\"width: 270px;\" onchange=\"javascript:getUserDetails(this.options[this.selectedIndex].value)\"><option value=\"-1\">Select user to modify</option>");
      
      ArrayList<User> users = getRegisteredUsers(request);
      for(int i = 0; i < users.size(); i++)
         b.append("<option value=\"").append(users.get(i).getUserId()).append("\">").append(users.get(i).getFullName()).append("</option>");
     
      b.append("</select>");
      
      return b.toString();
   }
   
   public String getAccessLevels(User user, HttpServletRequest request)
   {
      AccessLevels al = (AccessLevels)request.getSession().getAttribute("defaultAccessLevels");
      if(user != null)
         al.setPermission(user.getPermissionSet());
      
      Iterator<Map.Entry<String,Integer>> it = al.getLevels().entrySet().iterator();
      StringBuilder b = new StringBuilder();
      b.append("<table>");
      while(it.hasNext())
      {
         b.append("<tr>");
         Map.Entry<String,Integer> e = it.next();
         String name = e.getKey();
         Integer bit = e.getValue();
         b.append("<td><input type=\"checkbox\" name=\"userPermissionsChBox\"").append(" id=\"").append(name).append("\" value=\"").append(name).append("\"");
         if(user != null && al.isSet(name))
            b.append(" checked");
         
         if(user != null && user.getUsername().equals("admin"))
            b.append(" disabled");

         b.append("></td>");
         b.append("<td> : ").append(name).append("</td>");
         b.append("</tr>");
      }
      b.append("</table>");
      al.clear();

      return b.toString();
   }

   // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
   /**
    * Handles the HTTP <code>GET</code> method.
    *
    * @param request servlet request
    * @param response servlet response
    * @throws ServletException if a servlet-specific error occurs
    * @throws IOException if an I/O error occurs
    */
   @Override
   protected void doGet(HttpServletRequest request, HttpServletResponse response)
           throws ServletException, IOException
   {
      processRequest(request, response);
   }

   /**
    * Handles the HTTP <code>POST</code> method.
    *
    * @param request servlet request
    * @param response servlet response
    * @throws ServletException if a servlet-specific error occurs
    * @throws IOException if an I/O error occurs
    */
   @Override
   protected void doPost(HttpServletRequest request, HttpServletResponse response)
           throws ServletException, IOException
   {
      processRequest(request, response);
   }

   /**
    * Returns a short description of the servlet.
    *
    * @return a String containing servlet description
    */
   @Override
   public String getServletInfo()
   {
      return "Short description";
   }// </editor-fold>

}
