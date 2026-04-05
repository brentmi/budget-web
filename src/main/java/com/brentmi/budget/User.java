/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import java.util.ArrayList;

/**
 *
 * @author millingtonb
 */
public class User
{
   int userId;
   int permissionSet;
   String fullName;
   String username;
   String password;
   String email;
   String[] userPermissionsChBox;
  
   public int getUserId()
   {
      return userId;
   }

   public void setUserId(int userId)
   {
      this.userId = userId;
   }

   public int getPermissionSet()
   {
      return permissionSet;
   }

   public void setPermissionSet(int permissionSet)
   {
      this.permissionSet = permissionSet;
   }

   public String getFullName()
   {
      return fullName;
   }

   public void setFullName(String fullName)
   {
      this.fullName = fullName;
   }

   public String getUsername()
   {
      return username;
   }

   public void setUsername(String username)
   {
      this.username = username;
   }

   public String getPassword()
   {
      return password;
   }

   public void setPassword(String password)
   {
      this.password = password;
   }

   public String getEmail()
   {
      return email;
   }

   public void setEmail(String email)
   {
      this.email = email;
   }

   public String[] getUserPermissionsChBox()
   {
      return userPermissionsChBox;
   }

   public void setUserPermissionsFromChBox(AccessLevels al)
   {
      for(int i = 0; i < this.userPermissionsChBox.length; i++)
         al.setBit(this.userPermissionsChBox[i]);
      
      permissionSet = al.getPermission();
      al.clear();
   }
   
   public void setUserPermissionsChBox(String[] userPermissionsChBox)
   {
      this.userPermissionsChBox = userPermissionsChBox;
   }

   @Override
   public String toString()
   {
      return "userId=" + userId + "\n" +
         "permissionSet=" + permissionSet + "\n" +
         "fullName=" + fullName + "\n" +
         "username=" + username + "\n" +
         "password=" + password + "\n" +
         "email=" + email +  "\n" +
         "userPermissionsChBox=" + userPermissionsChBox + "\n";
   }

}
