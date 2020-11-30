using ODISAPI.ActionFilters;
using System.Web.Mvc;

namespace ODIS.Closedloop.API
{
    public class FilterConfig
    {
        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {   
            filters.Add(new HandleErrorAttribute());
        }
    }
}
