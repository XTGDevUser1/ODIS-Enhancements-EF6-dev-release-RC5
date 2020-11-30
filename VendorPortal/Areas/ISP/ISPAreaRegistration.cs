using System.Web.Mvc;

namespace VendorPortal.Areas.ISP
{
    public class ISPAreaRegistration : AreaRegistration
    {
        public override string AreaName
        {
            get
            {
                return "ISP";
            }
        }

        public override void RegisterArea(AreaRegistrationContext context)
        {
            context.MapRoute(
                "ISP_default",
                "ISP/{controller}/{action}/{id}",
                new { action = "Index", id = UrlParameter.Optional }
            );
        }
    }
}
