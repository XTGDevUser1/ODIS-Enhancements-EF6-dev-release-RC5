using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ODISAPI.Models
{
  public class CTRUpdateResults
  {
    public CTRUpdateResults() {
      Results = new Dictionary<string, CTRUpdateResult>();
    }

    public IDictionary<string, CTRUpdateResult> Results { get; set; }
  }
}