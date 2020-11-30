using System;
using System.Collections.Generic;
using System.Linq;

using Foundation;
using UIKit;
using ODISMember.Services.Service;
using ODISMember.Helpers.UIHelpers;

namespace ODISMember.iOS
{
    public class Application
    {
        // This is the main entry point of the application.
        static void Main(string[] args)
        {
            // if you want to use a different Application Delegate class from "AppDelegate"
            // you can specify it here.
            try
            {
                 UIApplication.Main(args, "MyApplication", "AppDelegate");
           }
            catch (Exception ex) {
                if (ex != null && ex.InnerException != null)
               {
                   (new LoggerHelper()).Trace("Exception: "+ex.InnerException.ToString());
               }
               throw ex;
            }
            
        }
    }
}
