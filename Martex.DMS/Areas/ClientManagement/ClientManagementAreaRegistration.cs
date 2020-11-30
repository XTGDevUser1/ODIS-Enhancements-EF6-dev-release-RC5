using System.Web.Mvc;

namespace Martex.DMS.Areas.ClientManagement
{
    public class ClientManagementAreaRegistration : AreaRegistration
    {
        public override string AreaName
        {
            get
            {
                return "ClientManagement";
            }
        }

        public override void RegisterArea(AreaRegistrationContext context)
        {
            context.MapRoute(
                "ClientManagement_default",
                "ClientManagement/{controller}/{action}/{id}",
                new { action = "Index", id = UrlParameter.Optional }
            );
        }
    }
}
