using System.Web.Mvc;

namespace Martex.DMS.Areas.QA
{
    public class CXAreaRegistration : AreaRegistration
    {
        public override string AreaName
        {
            get
            {
                return "CX";
            }
        }

        public override void RegisterArea(AreaRegistrationContext context)
        {
            context.MapRoute(
                "CX_default",
                "CX/{controller}/{action}/{id}",
                new { action = "Index", id = UrlParameter.Optional }
            );
        }
    }
}
