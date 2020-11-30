using System.Web.Mvc;

namespace Martex.DMS.Areas.MemberManagement
{
    public class MemberManagementAreaRegistration : AreaRegistration
    {
        public override string AreaName
        {
            get
            {
                return "MemberManagement";
            }
        }

        public override void RegisterArea(AreaRegistrationContext context)
        {
            context.MapRoute(
                "MemberManagement_default",
                "MemberManagement/{controller}/{action}/{id}",
                new { action = "Index", id = UrlParameter.Optional }
            );
        }
    }
}
