using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using log4net;
using log4net.Config;
using Martex.DMS.ActionFilters;
using System.Globalization;
using System.Threading;
using Martex.DMS.ModelBinder;
using Martex.DMS.App_Start;
using System.Web.Optimization;
using Microsoft.AspNet.SignalR;
using System.Configuration;

namespace Martex.DMS
{
    // Note: For instructions on enabling IIS6 or IIS7 classic mode, 
    // visit http://go.microsoft.com/?LinkId=9394801

    public class MvcApplication : System.Web.HttpApplication
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(MvcApplication));

        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            filters.Add(new DMSHandleErrorAttribute());
        }

        public static void RegisterRoutes(RouteCollection routes)
        {
            routes.IgnoreRoute("{resource}.axd/{*pathInfo}");
            //Fix to handle the error:
            //The controller for path '/Application/img/demo/icon.png' was not found or does not implement IController
            routes.IgnoreRoute("{file}.png");
            routes.IgnoreRoute("{file}.jpg");
            routes.IgnoreRoute("{file}.gif");
            routes.IgnoreRoute("{file}.ico");

            routes.MapRoute(
                "Default", // Route name
                "{controller}/{action}/{id}", // URL with parameters
                new { controller = "Account", action = "LogOn", id = UrlParameter.Optional } // Parameter defaults
            );

        }

        void Application_Error(object sender, EventArgs e)
        {
            // Get the exception object.
            Exception exc = Server.GetLastError();
            if (exc is System.InvalidOperationException) //KB: SignalR complains when there is a session reset
            {
                logger.Warn(exc.Message,exc);
            }
            else
            {
                logger.Error(exc.Message, exc);
            }
        }

        protected void Application_Start()
        {
            XmlConfigurator.Configure();

            AreaRegistration.RegisterAllAreas();
         
            //Any connection or hub wire up and configuration should go here
            string sqlConnectionString = ConfigurationManager.ConnectionStrings["NotificationServices"].ToString();
            GlobalHost.DependencyResolver.UseSqlServer(sqlConnectionString);
            RouteTable.Routes.MapHubs();
            

            RegisterGlobalFilters(GlobalFilters.Filters);
            RegisterRoutes(RouteTable.Routes);
            // register Integer model binder.
            ModelBinders.Binders.Add(typeof(int?), new IntegerModelBinder());
            ModelBinders.Binders.Add(typeof(TimeSpan?), new TimeSpanModelBinder());
            BundleConfig.RegisterBundles(BundleTable.Bundles);

            
        }

        
    }
}
