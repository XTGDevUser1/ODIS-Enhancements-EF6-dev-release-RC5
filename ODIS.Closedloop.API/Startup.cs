using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Owin;
using Owin;
using System.Web.Http;
using log4net.Config;
using ODISAPI.ActionFilters;
using System.Web.Http.Filters;

[assembly: OwinStartup(typeof(ODIS.Closedloop.API.Startup))]

namespace ODIS.Closedloop.API
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            HttpConfiguration config = new HttpConfiguration();
            WebApiConfig.Register(config);
            GlobalConfiguration.Configure(WebApiConfig.Register);
            app.UseCors(Microsoft.Owin.Cors.CorsOptions.AllowAll);
            app.UseWebApi(config);
            XmlConfigurator.Configure();
            RegisterGlobalFilters(config.Filters);

        }
        public static void RegisterGlobalFilters(HttpFilterCollection filters)
        {
            filters.Add(new ODISApiHandleErrorAttribute());
        }
    }
}
