using System.Web;
using System.Web.Mvc;
using VendorPortal.ActionFilters;

namespace VendorPortal
{
    public class FilterConfig
    {
        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            filters.Add(new DMSHandleErrorAttribute());
        }
    }
}