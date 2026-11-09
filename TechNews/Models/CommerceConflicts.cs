using System;
using Microsoft.Data.SqlClient;
namespace TechNews.Models {
 public static class CommerceConflicts {
  public static bool IsRetryable(Exception error) {
   for(var current=error;current!=null;current=current.InnerException)
    if(current is SqlException sql&&(sql.Number==1205||sql.Number==2601||sql.Number==2627))return true;
   return false;
  }
 }
}
