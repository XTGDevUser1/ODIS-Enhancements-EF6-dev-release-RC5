using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;
using System.Xml.Serialization;
using Martex.DMS.BLL.Facade.DigitalDispatch;
using Martex.DMS.BLL.Model.DigitalDispatch;
using Martex.DMS.BLL.Common;
using log4net;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;

namespace ODIS.Towbook.Listener
{
    public class TowbookRequestHandler : ITowbookRequestHandler
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(TowbookRequestHandler));
        DigitalDispatchFacade ddFacade = new DigitalDispatchFacade();

        public string Process(string message, string key)
        {
            var returnMessage = string.Empty;
            try
            {
                logger.InfoFormat("Process called with message : {0}", message);
                var apiKey = ConfigurationManager.AppSettings["TowbookApiKey"];
                if (key != null && key.Equals(apiKey, StringComparison.InvariantCultureIgnoreCase))
                {
                    if (!string.IsNullOrEmpty(message))
                    {
                        if (message.Contains("DSRMessage"))
                        {
                            returnMessage = DSR(message);
                        }
                        else if (message.Contains("RETMessage"))
                        {
                            returnMessage = RET(message);
                        }
                        else if (message.Contains("CNLMessage"))
                        {
                            returnMessage = CNL(message);
                        }
                        else
                        {
                            throw new Exception("No message type found for the Message.");
                        }
                    }
                }
                else
                {
                    throw new Exception("Unauthorized access. Please check your key.");
                }
            }
            catch (Exception ex)
            {
                logger.Error("Error while processing request", ex);
                ERRModel model = new ERRModel()
                {
                    HeaderVersion = "1.0",
                    ErrorCode = ex.Message,
                    ErrorDescription = ex.InnerException != null ? ex.InnerException.Message : ex.Message
                };
                return ddFacade.GetDDMessage("ERRMessage.vm", model.ToDictionary());
            }
            logger.InfoFormat("Process returns: {0}", returnMessage);
            return returnMessage;
        }

        public string RET(string message)
        {
            logger.Info("Processing RET");
            using (StringReader sr = new StringReader(message))
            {

                XmlSerializer serializer = new XmlSerializer(typeof(RETModel));
                //RETModel myxml = (RETModel)serializer.Deserialize(sr);

                ACKModel model = new ACKModel()
                {
                    HeaderVersion = "1.0",
                    TriggerType = "RET",
                    ResponseType = "ACK"
                };

                return ddFacade.GetDDMessage("ACKMessage.vm", model.ToDictionary());
            }
        }


        public string CNL(string message)
        {
            logger.Info("Processing CNL");
            using (StringReader sr = new StringReader(message))
            {

                XmlSerializer serializer = new XmlSerializer(typeof(CNLModel));
                //CNLModel myxml = (RETModel)serializer.Deserialize(sr);

                ACKModel model = new ACKModel()
                {
                    HeaderVersion = "1.0",
                    TriggerType = "CNL",
                    ResponseType = "ACK"
                };

                return ddFacade.GetDDMessage("ACKMessage.vm", model.ToDictionary());
            }
        }

        public string DSR(string message)
        {
            logger.Info("Processing DSR");
            using (StringReader sr = new StringReader(message))
            {

                XmlSerializer serializer = new XmlSerializer(typeof(DSRModel));
                //DSRModel myxml = (RETModel)serializer.Deserialize(sr);

                ACKModel model = new ACKModel()
                {
                    HeaderVersion = "1.0",
                    TriggerType = "DSR",
                    ResponseType = "ACK"
                };

                return ddFacade.GetDDMessage("ACKMessage.vm", model.ToDictionary());
            }
        }

        //public List<VendorLocationsListForVendorNumber_Result> GetVendorLocationsListForVendorNumber(string vendorNumber)
        //{
        //    VendorFacade vendorFacade = new VendorFacade();
        //    return vendorFacade.GetVendorLocationsListForVendorNumber(vendorNumber);
        //}

        public string GetVendorLocationsListForVendorNumber(string vendorNumber, string key)
        {
            var returnLocations = string.Empty;
            try
            {
                logger.InfoFormat("GetVendorLocationsListForVendorNumber called with vendorNumber : {0}", vendorNumber);
                var apiKey = ConfigurationManager.AppSettings["TowbookApiKey"];
                if (key != null && key.Equals(apiKey, StringComparison.InvariantCultureIgnoreCase))
                {
                    VendorFacade vendorFacade = new VendorFacade();
                    var list = vendorFacade.GetVendorLocationsListForVendorNumber(vendorNumber);

                    if (list != null && list.Count > 0)
                    {
                        returnLocations = "<?xml version='1.0'?>	<DDMessage Version='1.0'>";
                        returnLocations += "<VendorLocations>";
                        foreach (var item in list)
                        {
                            returnLocations += "<VendorLocation>";
                            returnLocations += "<VendorLocationID>" + item.VendorLocationID + "</VendorLocationID>";
                            returnLocations += "<Line1>" + item.Line1 + "</Line1>";
                            returnLocations += "<Line2>" + item.Line2 + "</Line2>";
                            returnLocations += "<City>" + item.City + "</City>";
                            returnLocations += "<StateProvince>" + item.StateProvince + "</StateProvince>";
                            returnLocations += "<PostalCode>" + item.PostalCode + "</PostalCode>";
                            returnLocations += "<CountryCode>" + item.CountryCode + "</CountryCode>";
                            returnLocations += "</VendorLocation>";
                        }
                        returnLocations += "</VendorLocations>";
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error("Error while processing request", ex);
                ERRModel model = new ERRModel()
                {
                    HeaderVersion = "1.0",
                    ErrorCode = ex.Message,
                    ErrorDescription = ex.InnerException != null ? ex.InnerException.Message : ex.Message
                };
                return ddFacade.GetDDMessage("ERRMessage.vm", model.ToDictionary());
            }
            logger.InfoFormat("GetVendorLocationsListForVendorNumber returns: {0}", returnLocations);
            return returnLocations;
        }
    }
}
