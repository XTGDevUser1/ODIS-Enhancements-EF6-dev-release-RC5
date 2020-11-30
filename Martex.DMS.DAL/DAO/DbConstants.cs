using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Configuration;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// Class to hold constants related to stored proc names, params and column names.
    /// </summary>
    public static class DbConstants
    {
        public static readonly string CONNECTION_STRING = ConfigurationManager.ConnectionStrings["MartexConnectionString"].ConnectionString;

        // Page and Sort related parameters
        public const string PARM_START_INDEX = "@startInd";
        public const string PARM_PAGE_SIZE = "@pageSize";
        public const string PARM_SORT_COLUMN = "@sortColumn";
        public const string PARM_SORT_ORDER = "@sortOrder";



    }
}
