using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using log4net.Config;
using Martex.DMS.BLL.Facade;

namespace EventNotificationService
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static void Main()
        {
            #region The following lines are required when the program is run as a service.
            ServiceBase[] ServicesToRun;
            ServicesToRun = new ServiceBase[] 
            { 
                new EventNotificationService() 
            };
            XmlConfigurator.Configure();
            ServiceBase.Run(ServicesToRun);
            #endregion

            #region To Test as console app
            //var notificationService = new EventNotificationFacade();
            //notificationService.ProcessEvents();

            #endregion
        }
    }
}
