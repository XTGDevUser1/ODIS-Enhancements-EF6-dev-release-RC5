using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using log4net.Config;

namespace WinDispatchProcessingService
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static void Main()
        {
            ServiceBase[] ServicesToRun;
            ServicesToRun = new ServiceBase[] 
			{ 
				new DispatchProcessingService() 
			};
            XmlConfigurator.Configure();
            ServiceBase.Run(ServicesToRun);
        }
    }
}
