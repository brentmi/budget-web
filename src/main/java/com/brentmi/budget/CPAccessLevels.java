/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.brentmi.budget;
import com.brentmi.budget.AccessLevelsImpl;


/**
 *
 * @author millingtonb
 */
public class CPAccessLevels extends AccessLevelsImpl
{
   public CPAccessLevels()
   {
      pSet.put("ENABLED", 0);
      pSet.put("ADMIN", 1);
      pSet.put("SUPER", 2);
      pSet.put("WORKFLOW-RO", 3);
      pSet.put("WORKFLOW-RW", 4);
//      pSet.put("EDIT-TASK", 2);
//      pSet.put("TASK-ORDER", 3);
//      pSet.put("VIEW-LOG", 4);
//      pSet.put("UPLOAD", 5);
//      pSet.put("DL-STATIC", 6);
//      pSet.put("BTCPS-INPUT", 7);
//      pSet.put("DTT-MAP", 8);
//      pSet.put("REPORTING", 9);
//      pSet.put("UTILS", 10);
//      pSet.put("DL-EXPORT", 11);
//      pSet.put("BOUQUET-MGMT", 12);
//      //pSet.put("LIVE-UPDATES", 13);
//      pSet.put("SCHEDULER-RO", 14);
//      pSet.put("SCHEDULER-EXE", 15);
//      pSet.put("PLATFORM-MGNT", 16);
//      pSet.put("PLATFORM-MGNT-RO", 17);
//      pSet.put("SITE-MGNT", 18);
//      pSet.put("SITE-MGNT-RO", 19);
//      pSet.put("STBSW-RW", 20);
//      pSet.put("STBSW-RO", 21);
      
   }
}
