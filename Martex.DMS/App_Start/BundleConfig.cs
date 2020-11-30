using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Optimization;

namespace Martex.DMS.App_Start
{
    public class BundleConfig
    {
        public static void RegisterBundles(BundleCollection bundles)
        {
            // Custom JScript File

            bundles.Add(new ScriptBundle("~/js").Include("~/Scripts/CustomJScript-{version}.js")
                                                .Include("~/Scripts/DesktopNotifications-{version}.js"));

            bundles.Add(new ScriptBundle("~/bundles/amazonConnect").Include("~/Scripts/amazon-connect-v1.2.0-21-ge9b5224.js")
                                                                   .Include("~/Scripts/libs/jquery-1.7.2.min.js")
                                                                   .Include("~/Scripts/script.js"));
            BundleTable.EnableOptimizations = false;
        }
    }
}
