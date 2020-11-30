using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.Filters;
using log4net.Config;
using MemberAPI.ActionFilters;
using Microsoft.Owin;
using Microsoft.Owin.Security.OAuth;
using Owin;
using MemberAPI.Handlers;

[assembly: OwinStartup(typeof(MemberAPI.Startup))]

namespace MemberAPI
{
    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureOAuth(app);

            HttpConfiguration config = new HttpConfiguration();
            config.MessageHandlers.Add(new AuthorizationHeaderHandler());
            WebApiConfig.Register(config);
            GlobalConfiguration.Configure(WebApiConfig.Register);
            app.UseCors(Microsoft.Owin.Cors.CorsOptions.AllowAll);
            app.UseWebApi(config);
            XmlConfigurator.Configure();
            RegisterGlobalFilters(config.Filters);

        }
        public static void RegisterGlobalFilters(HttpFilterCollection filters)
        {
            filters.Add(new MemberApiHandleErrorAttribute());
        }
        public void ConfigureOAuth(IAppBuilder app)
        {
            OAuthAuthorizationServerOptions OAuthServerOptions = new OAuthAuthorizationServerOptions()
            {
                AllowInsecureHttp = true,
                TokenEndpointPath = new PathString("/Members/Login"),
                AccessTokenExpireTimeSpan = TimeSpan.FromDays(90),
                Provider = new MemberAuthorizationServerProvider()
            };

            // Token Generation
            app.UseOAuthAuthorizationServer(OAuthServerOptions);
            app.UseOAuthBearerAuthentication(new OAuthBearerAuthenticationOptions());

        }
    }
}
