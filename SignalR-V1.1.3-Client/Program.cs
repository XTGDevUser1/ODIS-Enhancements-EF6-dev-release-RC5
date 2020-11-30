using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.AspNet.SignalR.Client.Hubs;
using System.Configuration;
using Microsoft.AspNet.SignalR.Client;
using System.Threading.Tasks;

namespace SignalR_V1._1._3_Client
{
    class Program
    {
        static void Main(string[] args)
        {
            //if (args.Length == 0)
            //{
            //    Console.WriteLine("Usage : SignalR-V1.1.3-Client.exe <message>");
            //}
            //else
            {
                var host = ConfigurationManager.AppSettings["Host"];

                var connection = new HubConnection(host);
                connection.TraceLevel = TraceLevels.All;
                connection.TraceWriter = Console.Out;
                var hubProxy = connection.CreateHubProxy("NotificationHub");
                connection.Start().Wait();

                for (var i = 0; i < 10; i++)
                {
                    Task t = hubProxy.Invoke("SendMessage", "demouser", "Test");
                    //t.Start();
                    //t.RunSynchronously();
                    dynamic result = t;
                    var taskResult = result.Result;
                    Console.WriteLine("Status : " + taskResult.Status.ToString());
                    connection.Stop();
                    
                }
                

                

                Console.Read();
            }
        }
    }
}
