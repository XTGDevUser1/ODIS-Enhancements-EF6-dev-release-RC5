using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.DigitalDispatchAPI;
using System.Web.Hosting;
using System.Collections;
using NVelocityTemplateEngine;
using NVelocityTemplateEngine.Interfaces;
using Martex.DMS.BLL.Model.DigitalDispatch;
using Martex.DMS.BLL.Common;
using System.IO;
namespace Martex.DMS.BLL.Facade.DigitalDispatch
{
    public class DigitalDispatchFacade
    {
        public DigitalDispatchReturnModel Ack(ACKModel model)
        {
            return ProcessTemplate("ACKMessage.vm", model.ToDictionary());
        }

        public DigitalDispatchReturnModel Dsp(DSPModel model)
        {
            return ProcessTemplate("DSPMessage.vm", model.ToDictionary());
        }

        public DigitalDispatchReturnModel Inq(INQModel model)
        {
            return ProcessTemplate("INQMessage.vm", model.ToDictionary());
        }

        public DigitalDispatchReturnModel Ret(RETModel model)
        {
            return ProcessTemplate("RETMessage.vm", model.ToDictionary());
        }

        public DigitalDispatchReturnModel Rsl(RSLModel model)
        {
            return ProcessTemplate("RSLMessage.vm", model.ToDictionary());
        }

        public DigitalDispatchReturnModel Rsp(RSPModel model)
        {
            return ProcessTemplate("RSPMessage.vm", model.ToDictionary());
        }

        public DigitalDispatchReturnModel Upd(UPDModel model)
        {
            return ProcessTemplate("UPDMessage.vm", model.ToDictionary());
        }
        public DigitalDispatchReturnModel Dsi(DSIModel model)
        {
            return ProcessTemplate("DSIMessage.vm", model.ToDictionary());
        }

        public DigitalDispatchReturnModel TowBookRET(RETModel model)
        {
            return ProcessTowBookTemplate("RETMessage.vm", model.ToDictionary());
        }

        public DigitalDispatchReturnModel TowBookCNL(CNLModel model)
        {
            return ProcessTowBookTemplate("CNLMessage.vm", model.ToDictionary());
        }

        public DigitalDispatchReturnModel TowBookDSR(DSRModel model)
        {
            
            return ProcessTowBookTemplate("DSRMessage.vm", model.ToDictionary());
            
        }
        
        private DigitalDispatchReturnModel ProcessTowBookTemplate(string templateName, Dictionary<string, string> model)
        {
            var returnModel = new DigitalDispatchReturnModel();
            try
            {

                TowBookServiceReference.TowbookRequestHandlerClient client = new TowBookServiceReference.TowbookRequestHandlerClient();
                string modelData = GetDDMessage(templateName, model);
                returnModel.Request = modelData;
                returnModel.Response = client.Process(modelData, "131bc55c-c9f9-41ab-beb8-743e6f148b19");
                return returnModel;
                

            }
            catch (Exception ex)
            {
                returnModel.Response = ex.InnerException != null ? ex.InnerException.Message + "<br/>" + ex.Message : ex.Message;
            }
            return returnModel;
        }

        private DigitalDispatchReturnModel ProcessTemplate(string templateName, Dictionary<string, string> model)
        {
            var returnModel = new DigitalDispatchReturnModel();
            try
            {

                TowbookServiceSoapClient client = new TowbookServiceSoapClient("TowbookServiceSoap");
                string modelData = GetDDMessage(templateName, model);
                returnModel.Request = modelData;
                string response = client.DDXMLReceiveMessageEx("kpa7PXtUd32gbR3dN5R6gsCy", modelData);
                returnModel.Response = response;
            }
            catch (Exception ex)
            {
                returnModel.Response = ex.InnerException != null ? ex.InnerException.Message + "<br/>" + ex.Message : ex.Message;
            }
            return returnModel;
        }

        public string GetDDMessage(string templateName, Dictionary<string, string> model)
        {
            string templateDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Templates");
            INVelocityEngine fileEngine = NVelocityEngineFactory.CreateNVelocityFileEngine(templateDir, true);
            string modelData = fileEngine.Process(model, templateName);
            return modelData;
        }
    }
}
