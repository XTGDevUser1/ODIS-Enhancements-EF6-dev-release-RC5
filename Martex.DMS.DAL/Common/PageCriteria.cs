using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Common
{
    public class PageCriteria
    {
        public int? StartInd { get; set; }
        public int? EndInd { get; set; }
        public int? PageSize { get; set; }
        public string SortColumn { get; set; }
        public string SortDirection { get; set; }
        public string WhereClause { get; set; }
    }
}
