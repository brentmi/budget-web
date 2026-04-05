/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 *
 * @author millingtonb
 */
public abstract class AccessLevelsImpl implements AccessLevels
{
   private int permission = 0;
   protected Map<String, Integer> pSet = new LinkedHashMap();
   
   public AccessLevelsImpl()
   {
      
   }
   
   public Map getLevels()
   {
      return pSet;
   }
   
   public void setPermission(int p)
   {
      this.permission = p;
   }
   
   public int getPermission()
   {
      return permission;
   }
   
   public void setBit(String accessType)
   {
      if(! pSet.containsKey(accessType))
         return;
      
      permission = permission | (1 << pSet.get(accessType));
   }
   
   public boolean isSet(String accessType)
   {
      if(! pSet.containsKey(accessType))
         return false;
      
      return (permission & (1 << pSet.get(accessType))) != 0;
   }
   
   public void clear()
   {
      permission = 0;
   }
}
