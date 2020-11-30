using System;
using Martex.DMS.BLL.Facade;
using log4net.Config;
using log4net;
using SelectPdf;

namespace Martex.DMS.EventNotification
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            #region Map snapshot

            //string bingKey = AppConfigRepository.GetValue("BING_API_KEY");
            //const string MAP_URL_LOCATION_ONLY = "http://dev.virtualearth.net/REST/V1/Imagery/Map/Road/{0},{1}/15?pp={0},{1};53;A&mapLayer=TrafficFlow&key={2}&mapSize=500,500";
            //const string MAP_URL_ROUTE = "https://dev.virtualearth.net/REST/V1/Imagery/Map/Road/Routes/?wp.0={0},{1};;A&wp.1={2},{3};;B&timeType=Departure&dateTime={4}&output=xml&key={5}&mapSize=500,500";
            //string staticMapURL = string.Empty;
            //string destinationAddress = string.Empty;

            //decimal serviceLocationLatitude = 32.7197723M, serviceLocationLongitude = -97.1182785M, destinationLatitude = 32.7639809M, destinationLongitude = -97.0723495M;

            //if (!string.IsNullOrWhiteSpace(destinationAddress))
            //{
            //    staticMapURL = string.Format(MAP_URL_ROUTE, serviceLocationLatitude, serviceLocationLongitude, destinationLatitude, destinationLongitude, DateTime.Now.ToString("hh:mm:sstt"), bingKey);
            //}
            //else
            //{
            //    staticMapURL = string.Format(MAP_URL_LOCATION_ONLY, serviceLocationLatitude, serviceLocationLongitude, bingKey);
            //}

            //WebClient client = new WebClient();
            //byte[] bytes = client.DownloadData(staticMapURL);

            //var base64String = Convert.ToBase64String(bytes);
            //System.Console.WriteLine(base64String);


            #endregion

            #region PushNotifications
            //PushNotification pushNotification = new PushNotification();
            //pushNotification.ProcessNotifications();            
            #endregion

            #region ODIS Services
            XmlConfigurator.Configure();
            ILog logger = LogManager.GetLogger(typeof(Program));
            logger.Info("Program Started");

            //EventNotificationFacade notificationService = new EventNotificationFacade();
            //notificationService.ProcessEvents();
            try
            {

                string filePath = @"C:\Users\kbanda.INFORICA\Desktop\PO_Fax.html";
                string pathToPDF = @"D:\tmp\FaxFiles\FontCheck36.pdf";

                // instantiate a html to pdf converter object
                HtmlToPdf converter = new HtmlToPdf();
                converter.Options.PdfPageSize = PdfPageSize.A4;
                // create a new pdf document converting an url
                PdfDocument doc = converter.ConvertUrl(filePath);                
                // save pdf document
                doc.Save(pathToPDF);

                // close pdf document
                doc.Close();

                /*CommunicationServiceFacade communicationServiceFacade = new CommunicationServiceFacade();
                communicationServiceFacade.SendNotification();*/
                //DispatchProcessingServiceFacade facade = new DispatchProcessingServiceFacade();
                //facade.StartProcessing("sysadmin");
            }
            catch(Exception ex)
            {
                System.Console.WriteLine(ex.Message);
            }
            #endregion
            System.Console.Write("Done");
            System.Console.ReadLine();
            #region Digital Dispatch
            /*DigitalDispatchFacade facade = new DigitalDispatchFacade();

            ACKModel model = new ACKModel();
            model.HeaderVersion = "1.0";
            model.Key = "Pinnacle";
            model.ContractorID = "112834";
            model.TransType = "ACK";
            model.ConRequired = "Y";
            model.ResponseType = "RSP";

            model.TriggerType = "DSP";

            var response = facade.Ack(model);

            System.Console.WriteLine(response);*/

            /*
            TowbookServiceReference.TowbookRequestHandlerClient client = new TowbookServiceReference.TowbookRequestHandlerClient();

            string message = "<?xml version='1.0'?>	<DDMessage Version='1.0'>";
            message += "	<DDMessageHeader>                                           ";
            message += "		<HeaderVersion>1.0</HeaderVersion>                      ";
            message += "		<Key>Pinnacle</Key>                                     ";
            message += "		<ContractorID>112834</ContractorID>                     ";
            message += "		<ResponseID/>                                           ";
            message += "		<TransType>RET</TransType>                              ";
            message += "		<MsgVersion/>                                           ";
            message += "		<ConRequired>Y</ConRequired>                            ";
            message += "		<ResponseType>ACK</ResponseType>                        ";
            message += "	</DDMessageHeader>                                          ";
            message += "	<RETMessage>                                                ";
            message += "		<JobID>463607639</JobID>                                ";
            message += "		< OrigonatedBy>                                         ";
            message += "		<ServiceProviderResponse>0</ServiceProviderResponse>    ";
            message += "		<ETA>10</ETA>                                           ";
            message += "		<MilesToVehicle>10</MilesToVehicle>                     ";
            message += "		<MilesLoaded>10</MilesLoaded>                           ";
            message += "		<EstimatedPrice/>                                       ";
            message += "		<ColorOfTruck/>                                         ";
            message += "		<ContactName/>                                          ";
            message += "		<RejectDescription/>                                    ";
            message += "		<CurrentTemperature/>                                   ";
            message += "		<PrecipitationType/>                                    ";
            message += "		<RoadCondition/>                                        ";
            message += "		<Remarks>testing</Remarks>                              ";
            message += "	</RETMessage>                                               ";
            message += "</DDMessage>";
            System.Console.WriteLine(client.Process(message, "131bc55c-c9f9-41ab-beb8-743e6f148b19"));

            System.Console.WriteLine(client.GetVendorLocationsListForVendorNumber("TX167426", "131bc55c-c9f9-41ab-beb8-743e6f148b19"));

             */
            #endregion

        }
    }
}
