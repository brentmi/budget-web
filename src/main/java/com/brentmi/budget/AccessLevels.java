/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package com.brentmi.budget;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 *
 * @author brentmi
 */
public interface AccessLevels
{
   public Map getLevels();
   public void setPermission(int p);
   public int getPermission();
   public void setBit(String accessType);
   public boolean isSet(String accessType);
   public void clear();
}
