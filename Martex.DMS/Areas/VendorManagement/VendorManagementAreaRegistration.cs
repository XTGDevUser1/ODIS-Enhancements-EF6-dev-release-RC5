using System.Web.Mvc;

namespace Martex.DMS.Areas.VendorManagement
{
    public class VendorManagementAreaRegistration : AreaRegistration
    {
        public override string AreaName
        {
            get
            {
                return "VendorManagement";
            }
        }

        public override void RegisterArea(AreaRegistrationContext context)
        {
            context.MapRoute(
                "VendorManagement_default",
                "VendorManagement/{controller}/{action}/{id}",
                new { action = "Index", id = UrlParameter.Optional }
            );
        }
    }
}
