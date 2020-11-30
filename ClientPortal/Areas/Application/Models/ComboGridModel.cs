using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ClientPortal.Areas.Application.Models
{
    public class ComboGridModel
    {
        public int records { get; set; }
        public int total { get; set; }
        public int Count { get; set; }
        public object[] rows { get; set; }
    }
}