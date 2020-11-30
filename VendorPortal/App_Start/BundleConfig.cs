using System.Web;
using System.Web.Optimization;

namespace VendorPortal
{
    public class BundleConfig
    {
        // For more information on Bundling, visit http://go.microsoft.com/fwlink/?LinkId=254725
        public static void RegisterBundles(BundleCollection bundles)
        {
            //// Custom JScript File
            //bundles.Add(new ScriptBundle("~/Scripts").Include(
            //            "~/Scripts/login-{version}.js"));

            //bundles.Add(new ScriptBundle("~/CustomScripts").Include(
            //            "~/Scripts/CustomJScript-{version}.js"));
            
            //BundleTable.EnableOptimizations = false;

            bundles.IgnoreList.Clear();
            // The jQuery bundle
            bundles.Add(new ScriptBundle("~/bundles/jquery").Include(
                            "~/Scripts/jquery-1.*"));
            bundles.Add(new ScriptBundle("~/bundles/jquerymigrate").Include(
                            "~/Scripts/jquery-migrate-1.*"));


            bundles.IgnoreList.Ignore("*.map");
            // Custom JScript File
            bundles.Add(new ScriptBundle("~/Scripts").Include(
                        "~/Scripts/login-{version}.js"));

            bundles.Add(new ScriptBundle("~/CustomScripts").Include(
                        "~/Scripts/CustomJScript-{version}.js"));

            // The Kendo JavaScript bundle
            bundles.Add(new ScriptBundle("~/bundles/kendo").Include(
                    "~/Scripts/kendo.all-*", // or kendo.all.* if you want to use Kendo UI Web and Kendo UI DataViz
                    "~/Scripts/kendo.aspnetmvc-*"));

            // The Kendo CSS bundle for web
            bundles.Add(new StyleBundle("~/Content/kendoweb").Include(
                    "~/Content/web/kendo.common.*",
                    "~/Content/web/kendo.default-blue.*"));           

            BundleTable.EnableOptimizations = false;
        }
    }
}