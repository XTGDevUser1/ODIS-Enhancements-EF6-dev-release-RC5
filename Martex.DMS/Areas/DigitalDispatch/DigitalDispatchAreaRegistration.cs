using System.Web.Mvc;

namespace Martex.DMS.Areas.DigitalDispatch
{
    public class DigitalDispatchAreaRegistration : AreaRegistration
    {
        public override string AreaName
        {
            get
            {
                return "DigitalDispatch";
            }
        }

        public override void RegisterArea(AreaRegistrationContext context)
        {
            context.MapRoute(
                "DigitalDispatch_default",
                "DigitalDispatch/{controller}/{action}/{id}",
                new { action = "Index", id = UrlParameter.Optional }
            );
        }
    }
}
